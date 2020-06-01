# Get the files which should be moved, without folders
$files = Get-ChildItem 'D:\Sorted\Output3' -Recurse | where {!$_.PsIsContainer} 
 

foreach ($file in $files) {

    Write-Host "-----"
    $file

    Write-Output ($file -like '*(Edited)*')
    if ($file -like '*(Edited)*') {
        Write-Output "leave name since Edited"
        $newFileName = $file
    } else {
       Write-Output "strip ()"
       $newFileName = $file -replace '\([^\)]+\)'
       $newFileName
    }
    Write-Output $newFileName
    $newPathNewName = $Directory + "\" + $newFileName
    Write-Output $newPathNewName

    #if already exists
    if (Test-Path $newPathCurrentName) {
        Write-Output "file exists"
    } else {
        Write-Output "rename"
        #Rename-Item -Path $file -NewName $newFileNameRenameOnly
    }

}