$psi = New-object System.Diagnostics.ProcessStartInfo
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.FileName = "powershell.exe"

Write-Host "Starting Microsoft.Xrm.Data.Powershell module in new process..."
$isOnPrem = "$(onPremises)"
if ($isOnPrem -eq "true") {
  $psi.Arguments = "-File `"$(libraryPath)\module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"true`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -username `"$(adminUsername)`" -password `"$(adminPassword)`" -Wait"
} else {
  $psi.Arguments = "-File `"$(libraryPath)\module-helper.ps1`" -url `"$(environmentUrl)`" -onPremises `"false`" -task `"import`" -solutionFilePath `"$(Agent.ReleaseDirectory)\$(solutionFilePath)`" -Wait"
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
Write-Host "Microsoft.Xrm.Data.Powershell module process ended"

### V1 ###
<#
Write-Host "Importing Microsoft.Xrm.Data.Powershell module..."
$path = "$(libraryPath)/"
Import-Module -Verbose -FullyQualifiedName $path"Microsoft.Xrm.Data.Powershell"

# Increase timeout from default 2 minutes to 20
Set-CrmConnectionTimeout -TimeoutInSeconds 1200
$isOnPrem = "$(onPremises)"
Write-Host "Is on-prem:" $isOnPrem
if ($isOnPrem -eq "true") {
    $crmConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=Office365;Username=$(adminUsername);Password=$(adminPassword);Url=$(environmentUrl)" -MaxCrmConnectionTimeOutMinutes 20
} else {
    $crmConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=ClientSecret;Url=$(environmentUrl);ClientId=$(clientId);ClientSecret=$(clientSecret)" -MaxCrmConnectionTimeOutMinutes 20
}
Write-Host "Connection established with TARGET environment:"
$crmConnection

# Solution File path = Source alias + Artifact name
$solutionFilePath = "$(solutionFilePath)"
$solutionNames = Get-ChildItem -Path $solutionFilePath -Name -File -Include *.zip
Write-Host "Solutions to be imported: $solutionNames"

# Import solutions into TARGET environment
foreach ($solution in $solutionNames) {
    Write-Host "Importing solution: $solution"
    Import-CrmSolution -Verbose -conn $crmConnection -SolutionFilePath $solutionFilePath/$solution -MaxWaitTimeInSeconds 1200
}

Write-Host "Publishing all customizations..."
Publish-CrmAllCustomization -Verbose -conn $crmConnection
#>