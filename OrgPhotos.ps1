function exiftool {
    Param ([string]$function, [string] $filePath)

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "G:\exiftool.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = "Hidden"
    $pinfo.CreateNoWindow = $true
    $pinfo.Arguments = "-" + $function + ' "' + $filePath +'"'
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"

    Write-Output $stdout
}

# Get the files which should be moved, without folders
$files = Get-ChildItem 'G:\To Sort\Test\Time Mov' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
#$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'G:\Sorted\Test'
 
foreach ($file in $files) {

    Write-Host "-----"

    $file.FullName

    $file | Format-List
       
    
    if ($file.Extension -eq ".JPG" -or $file.Extension -eq ".JPEG" -or $file.Extension -eq ".HEIC") {
        $dateField = "DateTimeOriginal"
    } elseif ($file.Extension -eq ".PNG") {
        $dateField = "DateCreated"
    } elseif ($file.Extension -eq ".MOV" -or $file.Extension -eq ".mp4") {
        $dateField = "CreationDate"
    } elseif ($file.Extension -eq ".GIF") {
        $dateField = "FileModifyDate"
    } else {
        $dateField = "TrackCreateDate"
    }

    $output = exiftool -function $dateField -filepath $file.fullName

    #remove first part
    $pos = $output.IndexOf(":")
    $dateString = $output.Substring($pos+2).trim()
    $dateString
    #DISCARD (don't apply offset)
    if ($dateString -like '*+*') {
        $pos = $dateString.IndexOf("+")
        $dateString = $dateString.Substring(0,$pos).trim()
    } elseif  ($dateString -like '*-*') { 
        $pos = $dateString.IndexOf("-")
        $dateString = $dateString.Substring(0,$pos).trim()
    }
    $dateString
    $date = [datetime]::ParseExact($dateString,'yyyy:MM:dd HH:mm:ss',$null)
    $date


    #check if the date contains a timezone offset, if not will need to adust

    if ($file.Extension -eq ".MOV" -or $file.Extension -eq ".mp4") {
        if ($dateString -like '*+*' -or $dateString -like '*-*') { 
            #do nothing
        } else {
            #get location 
            $latlngString = exiftool -function "GPSPosition -n" -filepath $file.fullName
            $latlngString
            $pos = $latlngString.IndexOf(":")
            $latlngString = $latlngString.Substring($pos+2).trim()
            $latlngString
            $pos = $latlngString.IndexOf(" ")
            $lat = $latlngString.Substring(0,$pos).trim()
            $lng = $latlngString.Substring($pos).trim()

            $lat
            $lng

            $url = "http://api.geonames.org/timezoneJSON?lat="+$lat+"&lng="+$lng+"&date="+$year+"-"+$month+"-"+$day+"&username=theplaz"
            $url

            #get rest method
            Invoke-RestMethod -Method Post -Uri $url


        }
    }
 

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