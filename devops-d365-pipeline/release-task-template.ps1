# Organizational policies on remote PowerShell execution prevents module from loading directly
# To workaround, a new process is created locally to execute module-helper.ps1 and output is redirected back
Write-Host "Starting Microsoft.Xrm.Data.Powershell module in new process with parameters:"
$psi = New-object System.Diagnostics.ProcessStartInfo

# If environment is on-premises collect administrator username and password
# Provide parameters for xrm-module-helper.ps1 script to start Microsoft.Xrm.Data module
$isOnPrem = "$(onPremises)"
if ($isOnPrem -eq "true")
{
  $psi.Arguments = "-File `"$(libraryPath)\xrm-module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"true`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -solutionOrder `"$(solutionOrder)`" -username `"$(adminUsername)`" -password `"$(adminPassword)`" -Wait"
}
else
{
  $psi.Arguments = "-File `"$(libraryPath)\xrm-module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"false`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -solutionOrder `"$(solutionOrder)`" -Wait"
}

# Display process arguments
$parameters = $psi.Arguments -split ' '
for ($i = 0; $i -lt $parameters.Length - 1; $i += 2)
{
  Write-Host $parameters[$i] $parameters[$i + 1]
}

# Parameters for new script execution
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.FileName = "powershell.exe"

# Start module-helper.ps1 process and read output till exit
$process = New-Object System.Diagnostics.Process 
$process.StartInfo = $psi 
[void]$process.Start()
# Read stdout and output if string is not empty
do
{
  $stdout = $process.StandardOutput.ReadLine()
  if (![string]::IsNullOrEmpty($stdout))
  {
    Write-Host $stdout 
  }
}
while (!$process.HasExited)
$processOutput = $process.StandardError.ReadToEnd()
$exitCode = $process.ExitCode

# If process exit code != 0 pipeline will fail
if ($exitCode -eq 0)
{
  Write-Host "SUCCESS: Microsoft.Xrm.Data.Powershell module process ended with no errors"
  exit 0
}
else
{
  Write-Host "##vso[task.logissue type=error]FAILURE: Microsoft.Xrm.Data.Powershell module process ended with errors: $processOutput"
  exit 1
}
