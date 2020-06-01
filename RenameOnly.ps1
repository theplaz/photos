# Get the files which should be moved, without folders
$files = Get-ChildItem 'D:\Sorted\Output3\2020\2020-04-29' -Recurse | where {!$_.PsIsContainer}
 

foreach ($file in $files) {

    Write-Host "-----"
    $file.FullName
    $file.Basename
    #$file.Extension
    #$filePath = Split-Path -Path $file.FullName
    #$filePath


    if ($file.Basename -like '*(Edited)*') {
        Write-Output "leave name since Edited"
        $newFileName = $file.Basename
    } else {
       Write-Output "strip ()"
       $newFileName = $file.Basename -replace '\([^\)]+\)'
    }
    $newFileName = $newFileName + $file.Extension
    Write-Output $newFileName
    $newPathNewName = $filePath + "\" + $newFileName
    Write-Output $newPathNewName

    #if already exists
    if (Test-Path $newPathNewName) {
        Write-Output "file exists; skip"
    } else {
        Write-Output "rename"
        Rename-Item -Path $file.FullName -NewName $newFileName
    }

}