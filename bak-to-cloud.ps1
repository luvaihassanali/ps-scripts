<#
    .DESCRIPTION
    Backup script with progress bar
    https://social.technet.microsoft.com/Forums/windowsserver/en-US/c957ca7a-088e-40fb-8ce6-23da4d0753bb/progress-bar-for-copied-files-in-powershell?forum=winserverpowershell
#>

Function PadCounter($value) {
    if ($value -lt 10) {
        $paddedString = "00" + $value
    } elseif ($value -ge 10 -and $value -lt 100) {
        $paddedString = "0" + $value
    } else {
        $paddedString = $value
    }
    return $paddedString
}

$sourceDir = "C:\\Users\\Username\\folder"
$literalSourceDir = "C:\Users\Username\folder"
$targetDir = "C:\\Users\\Username\\folder"
$oldFiles = Get-ChildItem $targetDir | Get-ChildItem -Recurse -Force -File
$files = Get-ChildItem $sourceDir | Get-ChildItem -Recurse -Force -File
$dirs = Get-ChildItem $sourceDir | Get-ChildItem -Recurse -Force -Directory
$rootDirs = Get-ChildItem $sourceDir -Directory
Write-Host "Starting backup..."

$counter = 1
foreach ($oldFile in $oldFiles) {
    $counterString = PadCounter $counter
    $status = "Deleting files {0} on {1}: {2}" -f $counterString, $oldFiles.Count, $oldFile.Name
    Write-Progress -Activity "Backup Data A" $status -PercentComplete ($counter / $oldFiles.Count * 100)
    Remove-Item $oldFile.FullName -Force
    $counter = $counter + 1
}

if (Test-Path $targetDir) {
    Move-Item $targetDir "C:\temp"
    Remove-Item "C:\temp\work" -Force -Recurse
}

# Wait for OneDrive to sync
Write-Host "Press Enter when OneDrive sync is complete" -NoNewLine
$UserInput = $Host.UI.ReadLine()

foreach ($rd in $rootDirs) {
    New-Item -Type Directory ($targetDir + "\\" + $rd.Name) -Force | Out-Null
}

foreach ($dir in $dirs) {
    # Skip shortcut folder    
    if ($dir -Match ".lnk") {   
        continue;
    }
    $newPath = $targetDir + $dir.FullName.replace($literalSourceDir, "\")
    New-Item -Type Directory $newPath -Force | Out-Null
}

$counter = 1
foreach ($file in $files) {
    $counterString = PadCounter $counter
    $status = "Copying files {0} on {1}: {2}" -f $counterString, $files.Count, $file.Name
    Write-Progress -Activity "Backup Data B" $status -PercentComplete ($counter / $files.Count * 100)   
    $fileSuffix = $file.FullName.Replace($literalSourceDir, "")
    $newPath = $sourceDir + $fileSuffix
    Copy-Item $newPath ($targetDir + $fileSuffix) -Recurse -Force      
    $counter = $counter + 1
}

Write-Host "Completed backup. Press Enter to exit" -NoNewLine
$UserInput = $Host.UI.ReadLine()
