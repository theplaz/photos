#Goal is to organize files into folders by timestamp taken at LOCAL time (when taken).

$TimeZoneKey = Get-Content -Path TimeZonesKey.txt

function exiftool {
    Param ([string]$function, [string] $filePath)

    Write-Host $function

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "D:\exiftool.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = "Hidden"
    $pinfo.CreateNoWindow = $true
    $pinfo.Arguments = '-"' + $function + '" "' + $filePath +'"'
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
$files = Get-ChildItem 'D:\To Sort\2020' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
#$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'D:\Sorted\Output2'
 
foreach ($file in $files) {

    Write-Host "-----"

    #set to null
    $lat = $null
    $lng = $null

    $file.FullName

    #$file | Format-List
       
    
    if ($file.Extension -eq ".JPG" -or $file.Extension -eq ".JPEG" -or $file.Extension -eq ".HEIC") {
        $dateField = "DateTimeOriginal"
    } elseif ($file.Extension -eq ".PNG") {
        $dateField = "DateCreated"
    } elseif ($file.Extension -eq ".MOV" -or $file.Extension -eq ".mp4") {
        #check which date format the video has
        $output = exiftool -function "CreationDate" -filepath $file.fullName
        if (-not [string]::IsNullOrEmpty($output)) {
            $dateField = "CreationDate"
            $adjustForTimeZoneOffset = $False
        } else {
            #times will be GMT
            #$dateField = "CreateDate"
            #actually adjustment ioffset is wrong
            #$adjustForTimeZoneOffset = $True
            #but file modify time without offset right
            $dateField = "FileModifyDate"
            $adjustForTimeZoneOffset = $False

        }
    } elseif ($file.Extension -eq ".GIF") {
        $dateField = "FileModifyDate"
    } elseif ($file.Extension -eq "original") {
        continue #skip these
    } else {
        $dateField = "FileModifyDate"
    }

    $output = exiftool -function $dateField -filepath $file.fullName
    $output

    #test if need to fallback
    if ([string]::IsNullOrEmpty($output)) {
        $output = exiftool -function "FileModifyDate" -filepath $file.fullName

    }

    #remove first part
    $pos = $output.IndexOf(":")
    $dateString = $output.Substring($pos+2).trim()
    $dateString

    #split offset
    #DISCARD (don't apply offset, since we want local time)
    if ($dateString -like '*+*') { 
        $hasOffset = $True;
        $pos = $dateString.IndexOf("+")
        
        $justDateString = $dateString.Substring(0,$pos).trim()
        $date = [datetime]::ParseExact($justDateString,'yyyy:MM:dd HH:mm:ss',$null)

        $offsetString = $dateString.Substring($pos+1).trim()
        $hourOffset = $offsetString.Substring(0,2).trim()
        $minOffset = $offsetString.Substring(3,2).trim()
        $dateWithOffset = $date.AddHours($hourOffset).AddMinutes($minOffset)
        $gmtDate = $date.AddHours(-$hourOffset).AddMinutes(-$minOffset)
        
    } elseif ($dateString -like '*-*') {
        $hasOffset = $True;
        $pos = $dateString.IndexOf("-")

        $justDateString = $dateString.Substring(0,$pos).trim()
        $date = [datetime]::ParseExact($justDateString,'yyyy:MM:dd HH:mm:ss',$null)

        $offsetString = $dateString.Substring($pos+1).trim()
        $hourOffset = $offsetString.Substring(0,2).trim()
        $minOffset = $offsetString.Substring(3,2).trim()
        $dateWithOffset = $date.AddHours(-$hourOffset).AddMinutes(-$minOffset)
        $gmtDate = $date.AddHours($hourOffset).AddMinutes($minOffset)
    } else {
        $hasOffset = $False;
        $date = [datetime]::ParseExact($dateString,'yyyy:MM:dd HH:mm:ss',$null)
    }
    
    
    $offsetString
    $hourOffset
    $minOffset
           
    $dateWithOffset
    $gmtDate

    
    #update timestamp on PNG
    if ($file.Extension -eq ".PNG") {
        Write-Output "Add time to PNG"
        exiftool -function 'PNG:CreationTime<DateCreated' -filepath $file.fullName
    }

    
    #update timestamp on MOV
    if ($file.Extension -eq ".MOV" -or $file.Extension -eq ".mp4") {
        Write-Output "Add time to MOV"
        #date needs to be written in GMT+PC offset on that date!

        $gmtDate

        #get timestamp offset on this date
        $unixTS = [int64](($date)-(get-date "1/1/1970")).TotalSeconds
        if ($unixTS -gt 1615690800) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1604192400) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1583636400) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1572742800) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1552186800) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1541293200) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1520737200) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1509843600) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1489287600) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1478394000) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1457838000) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1446339600) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1425783600) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1414890000) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1394334000) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1383440400) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1362884400) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1351990800) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1331434800) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1320541200) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1299985200) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1289091600) { $currentOffset = '-28800' }
        elseif ($unixTS -gt 1268535600) { $currentOffset = '-25200' }
        elseif ($unixTS -gt 1257037200) { $currentOffset = '-28800' }

        $currentOffset

        
        $gmtDate = $date.AddSeconds(-$currentOffset)
        $gmtDateString = $gmtDate.ToString("yyyy:MM:dd HH:mm:ss")
        $gmtDateString
        $command = "CreateDate="+$gmtDateString+""
        #$dateWithOffsetString = $dateWithOffset.ToString("yyyy:MM:dd HH:mm:ss")
        #$dateWithOffsetString
        #$command = "CreateDate="+$dateWithOffsetString+""
        exiftool -function $command -filepath $file.fullName
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
        New-Item $directory -type directory | Out-Null
    }


    #to fix: if the (1) version coipid first then normal version tries to be copied

    #rename away (1)
    $newPathCurrentName = $Directory + "\" + $file
    $newPathCurrentName
    #if the file already exists
    if (Test-Path $newPathCurrentName) {
        #if the file is not the same, keep old name
        if (-not ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $newPathCurrentName).Hash)) {
            #copy as is
            # Move File to new location
            $file | Move-Item -Destination $Directory
        }
        #if the same, skip
    } else { #file doesnt exist
       #rename and copy
       if (-not $file -like '*(Edited)*') {
           $newFileName = $file -replace '\([^\)]+\)'
           $newFileName
       } else {
           $newFileName = $file
       }
       $newPathNewName = $Directory + "\" + $newFileName
       $newPathNewName
       $file | Move-Item -Destination $newPathNewName
    }
}