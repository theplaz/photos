# Get the files which should be moved, without folders
$files = Get-ChildItem 'G:\To Sort\2017 Test\2017-09-30' -Recurse | where {!$_.PsIsContainer}
	 
# List Files which will be moved
#$files
	 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'G:\Sorted\2017'
	 
foreach ($file in $files) {

    $year = $file.LastWriteTime.Year.ToString()
    $month = $file.LastWriteTime.Month.ToString()
    $day = $DateTime.Day.ToString()


    # Out FileName, year and month
    $file.Name + ': ' + $year + "-" + $month + "-" + $day

 
    # Set Directory Path
    $Directory = $targetPath + "\" + $year + "\" + $year + '-' + $month + '-' + $day
    # Create directory if it doesn't exsist
    if (!(Test-Path $Directory)) {
        New-Item $directory -type directory
    }
 
    # Move File to new location
    $file | Move-Item -Destination $Directory
}