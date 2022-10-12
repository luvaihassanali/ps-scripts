param([string]$url="default",[string]$username="user", [string]$password="pass", [string]$solutionNames="", [string]$onPremises="true", [string]$task="export", [string]$solutionFilePath="path")

Import-Module -Verbose -FullyQualifiedName "C:\Users\Username\agent-dir\libs\Microsoft.Xrm.Data.Powershell"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Set-CrmConnectionTimeout -TimeoutInSeconds 1200

if ($onPremises -eq "true") {
  $crmConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=Office365;Username=$username;Password=$password;Url=$url" -MaxCrmConnectionTimeOutMinutes 20
} else {
  $crmConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=ClientSecret;Url=$url;ClientId=guid;ClientSecret=secret" -MaxCrmConnectionTimeOutMinutes 20
}
Write-Host "Connection established with TARGET environment:"
$crmConnection

if ($task -eq "export") {
  $slnNames = "$solutionNames".Split(',')
  Write-Host "Solutions to be exported: $slnNames"
  foreach ($solution in $slnNames) {
    Write-Host "Exporting solution: $solution to $solutionFilePath\solutions"
    Export-CrmSolution -Verbose -conn $crmConnection -SolutionName $solution -SolutionFilePath "$solutionFilePath\solutions"
  }
} 

if ($task -eq "import") {
  $slnNames = Get-ChildItem -Path $solutionFilePath -Name -File -Include *.zip
  $slnOrder = $solutionOrder.Split(',')
  Write-Host "Solutions to be imported: $slnNames"
  foreach($solutionOrderName in $slnOrder) {
    foreach($solution in $slnNames) {
      if ($solutionOrderName -eq $solution.Split('_')[0]) {
        Write-Host "Importing solution: $solutionFilePath\$solution"
        Import-CrmSolutionAsync -Verbose -BlockUntilImportComplete -OverwriteUnManagedCustomizations -ActivateWorkflows -conn $crmConnection -SolutionFilePath "$solutionFilePath\$solution" -MaxWaitTimeInSeconds 1200    
      }
    }
  }
  Write-Host "Publishing all customizations..."
  Publish-CrmAllCustomization -Verbose -conn $crmConnection
}