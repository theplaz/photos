#Goal is to organize files into folders by timestamp taken at LOCAL time (when taken).


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
    $pinfo.Arguments = '-"' + $function + '" "' + $filePath +'" -overwrite_original' 
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
$files = Get-ChildItem 'D:\To Sort\Test\Owl Videos' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
#$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'D:\Sorted\OutputOwl'
 
foreach ($file in $files) {

    Write-Host "-----"

    #set to null
    $lat = $null
    $lng = $null

    $file.FullName
    $file.Extension

    #$file | Format-List
       
    #deal with files with no file extension
    if ($file.Extension -eq "") {
        #no file extension
        $output = exiftool -function "MIMEType" -filepath $file.fullName

        $output

        if ($output -like "*video/mp4*") {
            $newName = $file.BaseName + ".mp4"
            $newName
            Write-Output "rename to add .mp4"
            $file = Rename-Item -Path $file.fullName -NewName $newName -PassThru

        }

        
    }
    
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
            $output = exiftool -function "MediaCreateDate" -filepath $file.fullName
            if (-not [string]::IsNullOrEmpty($output)) {
                $dateField = "MediaCreateDate"
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

        }
    } elseif ($file.Extension -eq ".GIF") {
        $dateField = "FileModifyDate"
    } elseif ($file.Extension -eq "original") { #to-do this should be contains
        continue #skip these
    } else {
        #Other file extension
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


    #remove away (#)
    $newPathCurrentName = $Directory + "\" + $file
    $newPathCurrentName
    Write-Output $file.BaseName
    Write-Output "check if needs to be renamed"
    if ($file -like '*(Edited)*') {
        Write-Output "leave name since Edited"
        $newFileName = $file.BaseName
    } else {
        Write-Output "strip ()"
        $newFileName = $file.BaseName -replace '\([^\)]+\)'
    }
    Write-Output $newFileName
    $newPathNewName = $Directory + "\" + $newFileName + $file.Extension
    Write-Output $newPathNewName
    

    $originalHash = (Get-FileHash $file.FullName).Hash
    if (Test-Path $newPathNewName) {
        $targetHash = (Get-FileHash $newPathNewName).Hash
    } else {
        #file doesn't exist; move
        $targetHash = $originalHash
    }


    #check to make sure file is not there and is the same
    while ($originalHash -ne $targetHash) {
       
        #if the file is not the same, add (2)
        if (-not ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $newPathNewName).Hash)) {
             Write-Output "file exists"
            Write-Output "add (2)"
            $newFileName = $newFileName + " (2)"
            $newPathNewName = $Directory + "\" + $newFileName + $file.Extension
            Write-Output $newFileName

            if (Test-Path $newPathNewName) {
                $targetHash = (Get-FileHash $newPathNewName).Hash
            } else {
                #file doesn't exist; move
                $targetHash = $originalHash
            }
        }
    }

    #check if we actually need to move
    if (Test-Path $newPathNewName) {
        Write-Output "file exists with same hash; skip"
        Write-Output (Get-FileHash $file.FullName).Hash
        Write-Output (Get-FileHash $newPathNewName).Hash
    } else {
        #actually move
        Write-Output "Time to actually move"
        $newPathNewName
        $file | Move-Item -Destination $newPathNewName
    }

    
}