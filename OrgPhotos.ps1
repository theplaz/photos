# Get the files which should be moved, without folders
$files = Get-ChildItem 'G:\To Sort\2017 Test\' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
#$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'G:\Sorted\2017'
 
foreach ($file in $files) {

    Write-Host "-----"

    $file.FullName

    $file | Format-List
   
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "G:\exiftool.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = "Hidden"
    $pinfo.CreateNoWindow = $true
    
    if ($file.Extension -eq ".JPG" -or $file.Extension -eq ".JPEG" -or $file.Extension -eq ".HEIC") {
        $dateField = "DateTimeOriginal"
    } elseif ($file.Extension -eq ".PNG") {
        $dateField = "DateCreated"
    } elseif ($file.Extension -eq ".MOV" -or $file.Extension -eq ".mp4") {
        $dateField = "TrackCreateDate"
    } elseif ($file.Extension -eq ".GIF") {
        $dateField = "FileModifyDate"
    } else {
        $dateField = "TrackCreateDate"
    }


    $pinfo.Arguments = "-" + $dateField + ' "' + $file.FullName +'"'
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"
    $pos = $stdout.IndexOf(":")
    $dateString = $stdout.Substring($pos+2).trim()
    $dateString
    $date = [datetime]::ParseExact($dateString,'yyyy:MM:dd HH:mm:ss',$null)
    $date
 

    $year = $date.Year
    $month = $date.Month
    $day = $date.Day

    if ($month -lt 10) {
	    $month = '0'+$month
	    $month = $month.ToString()
	}
	
	if ($day -lt 10) {
	    $day = '0'+$day
	    $day = $day.ToString()
	}


    # Out FileName, year and month
    $file.FullName + ': ' + $year + "-" + $month + "-" + $day

 
    # Set Directory Path
    $Directory = $targetPath + "\" + $year + "\" + $year + '-' + $month + '-' + $day
    # Create directory if it doesn't exsist
    if (!(Test-Path $Directory)) {
        New-Item $directory -type directory
    }
 
    # Move File to new location
    #$file | Copy-Item -Destination $Directory
}
