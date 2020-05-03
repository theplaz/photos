#Goal is to organize files into folders by timestamp taken at LOCAL time (when taken).

$TimeZoneKey = Get-Content -Path TimeZonesKey.txt

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
$files = Get-ChildItem 'G:\To Sort\Test\2019-04-04' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
#$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'G:\Sorted\Test'
 
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
            $dateField = "CreateDate"
            #times will be GMT
            $adjustForTimeZoneOffset = $True
        }
    } elseif ($file.Extension -eq ".GIF") {
        $dateField = "FileModifyDate"
    } else {
        $dateField = "FileModifyDate"
    }

    $output = exiftool -function $dateField -filepath $file.fullName

    #test if need to fallback
    if (-not [string]::IsNullOrEmpty($output)) {
        $output = exiftool -function "FileModifyDate" -filepath $file.fullName
    }

    #remove first part
    $pos = $output.IndexOf(":")
    $dateString = $output.Substring($pos+2).trim()
    $dateString

    if ($dateString -like '*+*' -or $dateString -like '*-*') { 
        $hasOffset = $True;
    } else {
        $hasOffset = $False;
    }


    #DISCARD (don't apply offset, since we want local time)
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


    #adjust GMT times to local
    if ($adjustForTimeZoneOffset) {
        #check if it has location
        $latlngString = exiftool -function "GPSPosition -n" -filepath $file.fullName
        $latlngString
         if (-not [string]::IsNullOrEmpty($latlngString)) {
            $pos = $latlngString.IndexOf(":")
            $latlngString = $latlngString.Substring($pos+2).trim()
            $latlngString
            $pos = $latlngString.IndexOf(" ")
            $lat = $latlngString.Substring(0,$pos).trim()
            $lng = $latlngString.Substring($pos).trim()

            $lat
            $lng

            #here assuming GMT, which it is for movies
            $unixTS = [int64](($date)-(get-date "1/1/1970")).TotalSeconds

            $url = "http://api.timezonedb.com/v2.1/get-time-zone?key="+$TimeZoneKey+"&format=json&by=position&lat="+$lat+"&lng="+$lng+"&time="+$unixTS
            $url

            #get rest method
            $timeZoneInfo = Invoke-RestMethod -Method Post -Uri $url

            $timeZoneInfo

            $timeZoneInfo.gmtOffset

            $date = $date + $timeZoneInfo.gmtOffset

        } else { 

            #assume file modify date has the proper offset
            #(usually right, but not if edited)
            $output = exiftool -function 'FileModifyDate' -filepath $file.fullName
            
            if ($output -like '*+*') {
                 $pos = $output.IndexOf("+")
                 $offsetString = $output.Substring($pos+1).trim()
                 $hourOffset = $offsetString.Substring(0,2).trim()
                 $minOffset = $offsetString.Substring(3,2).trim()
                 $date = $date.AddHours($hourOffset).AddMinutes($minOffset)
            } elseif  ($output -like '*-*') { 
                 $pos = $output.IndexOf("-")
                 $offsetString = $output.Substring($pos+1).trim()
                 $hourOffset = $offsetString.Substring(0,2).trim()
                 $minOffset = $offsetString.Substring(3,2).trim()
                 $date = $date.AddHours(-$hourOffset).AddMinutes(-$minOffset)
            } else {
                 #error
                 Write-Output "ERROR NO OFFSET STRING"
            }

            $offsetString
            $hourOffset
            $minOffset
        
            $date

        }

    }

    #update timestamp on PNG
    if ($file.Extension -eq ".PNG") {
        Write-Output "Add time to PNG"
        exiftool -function 'PNG:CreationTime<DateCreated' -filepath $file.fullName
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

    # Move File to new location
    $file | Copy-Item -Destination $Directory
}