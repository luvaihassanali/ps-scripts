$onPremises = $false
$import = $true # if false export solutions
$onPremUrl = "https://some-url.crm3.dynamics.com/"
$onPremSlnNames = "Solution1,Solution2"
$cloudUrl = "https://some-url.crm3.dynamics.com/"
$cloudSlnNames = "Solution1,Solution2"
$modulePath = ""
$workingDir = ""

# Organizational policies on remote PowerShell execution prevents module from loading directly
# A new script will be started locally and output is redirected back to remote PS process 
Write-Host "Starting Microsoft.Xrm.Data.Powershell module in new process with parameters:"
$psi = New-object System.Diagnostics.ProcessStartInfo

# If environment is on-premises collect administrator username and password
# Provide parameters for xrm-module-helper.ps1 script to start Microsoft.Xrm.Data module
if ($onPremises)
{
  $adminPassword = Read-Host 'Enter administrator password' -AsSecureString
  $pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
  # Provide parameters for xrm-module-helper.ps1 script to start Microsoft.Xrm.Data module
  if ($import)
  {
    $psi.Arguments = "-File `"$modulePath\xrm-module-helper.ps1`" -url `"$onPremUrl`" -onPremises `"true`" -task `"import`" -solutionFilePath `"$workingDir`"-solutionOrder `"$onPremSlnNames`" -username `"<insert username>`" -password `"$pw`" -Wait"
  }
  else
  {
    $psi.Arguments = "-File `"$modulePath\xrm-module-helper.ps1`" -url `"$onPremUrl`" -onPremises `"true`" -task `"export`" -solutionName `"$onPremSlnNames`" -solutionFilePath `"$workingDir`" -username `"<insert username>`" -password `"$pw`" -Wait"
  }
}
else
{
  if ($import)
  {
    $psi.Arguments = "-File `"$modulePath\xrm-module-helper.ps1`" -url `"$cloudUrl`" -onPremises `"false`" -task `"import`" -solutionFilePath `"$workingDir`" -solutionOrder `"$cloudSlnNames`" -Wait"
  }
  else
  {
    $psi.Arguments = "-File `"$modulePath\xrm-module-helper.ps1`" -url `"$cloudUrl`" -onPremises `"false`" -task `"export`" -solutionName `"$cloudSlnNames`" -solutionFilePath `"$workingDir`" -Wait"
  }
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

# https://stackoverflow.com/questions/11531068/powershell-capturing-standard-out-and-error-with-process-object
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

# If locally executed PS script does not return 0 then pipeline will fail
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
