$isOnPrem= "false"
$import = "true"
$url = "" 
$url2 = ""
$path = "$modulePath"
$localpath = "C:\Users\Username\Desktop\temp"

$psi = New-object System.Diagnostics.ProcessStartInfo
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.FileName = "powershell.exe"

Write-Host "Starting Microsoft.Xrm.Data.Powershell module in new process..."

if ($isOnPrem -eq "true") {
  $adminPassword = Read-Host 'Enter administrator password' -AsSecureString
  $pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))

  if ($import -eq "true") {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url`" -onPremises `"true`" -task `"import`" -solutionFilePath `"$localpath`" -username `"<insert username>`" -password `"$pw`" -Wait"
  } else {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url`" -onPremises `"true`" -task `"export`" -solutionName `"Solution1,Solution2`" -solutionFilePath `"$localpath`" -username `"<insert username>`" -password `"$pw`" -Wait"
  }
} else { # Cloud test 
  if ($import -eq "true") {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url2`" -onPremises `"false`" -task `"import`" -solutionFilePath `"$localpath`" -solutionOrder `"Solution1,Solution2`" -Wait"
  } else {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url2`" -onPremises `"false`" -task `"export`" -solutionName `"Solution1,Solution2`" -solutionFilePath `"$localpath`" -Wait"
  }
}

Write-Host $psi.Arguments
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
[void]$process.Start()

do
{
   $process.StandardOutput.ReadLine()
}
while (!$process.HasExited)
$processOutput = $process.StandardError.ReadToEnd()
$exitCode = $process.ExitCode

if($exitCode -eq 0) {
  Write-Host "SUCCESS: Microsoft.Xrm.Data.Powershell module process ended with no errors"
  exit 0
} else {
  Write-Host "##vso[task.logissue type=error]FAILURE: Microsoft.Xrm.Data.Powershell module process ended with errors: $processOutput"
  exit 1
}
