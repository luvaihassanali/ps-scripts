$psi = New-object System.Diagnostics.ProcessStartInfo
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.FileName = "powershell.exe"

Write-Host "Starting Microsoft.Xrm.Data.Powershell module in new process..."
$isOnPrem = "$(onPremises)"
if ($isOnPrem -eq "true") {
  $psi.Arguments = "-File `"$(libraryPath)\module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"true`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -solutionOrder `"$(solutionOrder)`" -username `"$(adminUsername)`" -password `"$(adminPassword)`" -Wait"
} else {
  $psi.Arguments = "-File `"$(libraryPath)\module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"false`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -solutionOrder `"$(solutionOrder)`" -Wait"
}

Write-Host "Process arguments: "
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
