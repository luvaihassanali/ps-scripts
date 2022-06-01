$isOnPrem= "false"
$import = "false"
$url = "url" 
$url2 = "https://env.crm.dynamics.com/"#
$path = "C:\Users\Username\agent-dir\libs"

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
    $psi.Arguments = "-File `"C:\Users\Username\agent-dir\libs\module-helper.ps1`" -url `"$url`" -onPremises `"true`" -task `"import`" -solutionFilePath `"${PSScriptRoot}`" -username `"email`" -password `"$pw`" -Wait"
  } else {
    $psi.Arguments = "-File `"C:\Users\Username\agent-dir\libs\module-helper.ps1`" -url `"$url`" -onPremises `"true`" -task `"export`" -solutionName `"JLDTransfer`" -solutionFilePath `"${PSScriptRoot}`" -username `"email`" -password `"$pw`" -Wait"
  }
} else { # Cloud test 
  if ($import -eq "true") {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url2`" -onPremises `"false`" -task `"import`" -solutionFilePath `"${PSScriptRoot}`" -Wait"
  } else {
    $psi.Arguments = "-File `"$path\module-helper.ps1`" -url `"$url2`" -onPremises `"false`" -task `"export`" -solutionName `"Solution1,Solution2`" -solutionFilePath `"${PSScriptRoot}`" -Wait"
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

Write-Host "Microsoft.Xrm.Data.Powershell module process ended"
