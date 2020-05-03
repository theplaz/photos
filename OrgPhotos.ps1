function Start-Proc  {
     param (
             [string]$exe = $(Throw "An executable must be specified"),
             [string]$arguments,
             [switch]$hidden,
             [switch]$waitforexit,
             [switch]$redirectStdOut
             )   
     
     # Build Startinfo and set options according to parameters
     $startinfo = new-object System.Diagnostics.ProcessStartInfo
     $startinfo.FileName = $exe
     $startinfo.Arguments = $arguments
     if ($hidden){
         $startinfo.WindowStyle = "Hidden"
         $startinfo.CreateNoWindow = $true
     }
     if($redirectStdOut){
        $startinfo.RedirectStandardOutput=$true
        $startinfo.UseShellExecute=$false
     }
     $process = [System.Diagnostics.Process]::Start($startinfo)
     if ($waitforexit) {$process.WaitForExit()}
     $process 
}
	
$argfile = 'exifargfile5'

if (Test-Path $argfile) { del $argfile }           # delete any existing argfile
$null | Out-File $argfile -Append -Encoding Ascii;    # and create an empty new one

$p = start-proc "G:\exiftool.exe" "-stay_open True -@ $argfile" -redirectStdOut -hidden      #start exiftool, make it resident monitoring exifargfile, capturing stdout

	
	
# Get the files which should be moved, without folders
$files = Get-ChildItem 'G:\To Sort\2017 Test\2017-09-30' -Recurse | where {!$_.PsIsContainer}
	 
# List Files which will be moved
#$files
	 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = 'G:\Sorted\2017'
	 
foreach ($file in $files) {

    # send exiftool the command to execute
    "-datetimeoriginal"| Out-File $argfile -Append -Encoding Ascii;         # return me the filename of the processed file
    "$file"               | Out-File $argfile -Append -Encoding Ascii;         # file to process
    "-execute`n"       | Out-File $argfile -Append -Encoding Ascii;         # execute it

    # read exiftool response from stdout 
    # Readline() will wait for input if there is none (yet), effectively pausing script execution, giving exiftool time to process the command
    $resultFilename = $p.StandardOutput.Readline()      # this returns a string in the form : "Filename        : somefilename"
    $dummy          = $p.StandardOutput.Readline()      # read exiftool's termination string "{ready}"

    $resultFilename
    $dummy
    

    $year = $DateTime.Year
    $month = $DateTime.Month
    $day = $DateTime.Day

    # Out FileName, year and month
    $file.Name + ': ' + $year + "-" + $month + "-" + $day

 
    # Set Directory Path
    $Directory = $targetPath + "\" + $year + "\" + $year + '-' + $month + '-' + $day
    # Create directory if it doesn't exsist
    if (!(Test-Path $Directory)) {
        New-Item $directory -type directory
    }
 
    # Move File to new location
    #$file | Copy-Item -Destination $Directory
}