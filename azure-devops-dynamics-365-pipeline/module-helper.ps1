param([string]$url="default",[string]$username="user", [string]$password="pass", [string]$solutionNames="", [string]$onPremises="true", [string]$task="export", [string]$solutionFilePath="path", [string]$solutionOrder="dependencyOrder")

# https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell/blob/master/Microsoft.Xrm.Data.PowerShell/Microsoft.Xrm.Data.PowerShell.psm1
Import-Module -FullyQualifiedName "***REMOVED***" # -Verbose

function Format-XML ([xml]$xml, $indent=2)
{
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
    $xmlWriter.Formatting = “indented”
    $xmlWriter.Indentation = $Indent
    $xml.WriteContentTo($XmlWriter)
    $XmlWriter.Flush()
    $StringWriter.Flush()
    return $StringWriter.ToString()
}

if ($onPremises -eq "true") {
  $crmConnection = Get-CrmConnection -ConnectionString "AuthType=Office365;Username=$username;Password=$password;Url=$url" -MaxCrmConnectionTimeOutMinutes 20 #-Verbose
} else {
  $crmConnection = Get-CrmConnection -ConnectionString "AuthType=ClientSecret;Url=$url;ClientId=$clientId;ClientSecret=$clientSecret" -MaxCrmConnectionTimeOutMinutes 20 #-Verbose
}
Write-Host "Connection established with TARGET environment:" $crmConnection.ConnectedOrgFriendlyName

if ($task -eq "export") {
  $slnNames = "$solutionNames".Split(',')
  Write-Host "Solutions to be exported: $slnNames"
  foreach ($solution in $slnNames) {
    $exportFlag = $false
    Write-Host "Exporting solution: $solution to $solutionFilePath\solutions"
    try {
      $result = Export-CrmSolution -Verbose -conn $crmConnection -SolutionName $solution -SolutionFilePath "$solutionFilePath\solutions"
      $exportFlag = $true
    } 
    catch {
      Write-Host "Exception: $_"
      $host.ui.WriteErrorLine("!!! Export-CrmSolution operation has encountered an exception !!!")
      exit 1
    }
  }
  if (!$exportFlag) {
    $host.ui.WriteErrorLine("!!! No solutions were exported !!!")
    exit 1
  }
  Write-Host "Completed exporting solutions."
} 

if ($task -eq "import") {
  $pollingInterval = 5 #seconds
  $slnNames = Get-ChildItem -Path $solutionFilePath -Name -File -Include *.zip
  $slnOrder = $solutionOrder.Split(',')
  Write-Host "Solutions to be imported: $slnNames"
  foreach($solutionOrderName in $slnOrder) {
    $publishFlag = $false
    foreach($solution in $slnNames) {
      $startTime = Get-Date
      if ($solutionOrderName -eq $solution.Split('_')[0]) {
        Write-Host "Importing solution: $solutionFilePath\$solution"
        try {
          $startTime = Get-Date
          $asyncId = Import-CrmSolutionAsync -OverwriteUnManagedCustomizations -ActivateWorkflows -conn $crmConnection -SolutionFilePath "$solutionFilePath\$solution" #-MaxWaitTimeInSeconds 1200 -BlockUntilImportComplete -Verbose

          Write-Host "Querying async job ID:" $asyncId.AsyncJobId
          while ($true) {
            # https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell.Samples/issues/23
            try {
              $asyncResult = Get-CrmRecord -conn $crmConnection -EntityLogicalName asyncoperation -Id $asyncId.AsyncJobId -Fields * 
            } 
            catch {
              Write-Host "Exception: $_"
              $host.ui.WriteErrorLine("!!! Get-CrmRecord operation has encountered an exception !!!")
              exit 1
            }

            $friendlyMsg = $asyncResult.friendlymessage
            $completedOn = $asyncResult.completedon
            $stateCode = $asyncResult.statecode
            $stopTime = Get-Date
            $timeSpan = $stopTime - $startTime
            
            Write-Host "Elapsed time:"$timeSpan.ToString()
            Write-Host "State code:" $stateCode
            Write-Host "Completed on:" $completedOn
            Write-Host "Friendly message:" $friendlyMsg
            Write-Host "-"

            if ($friendlyMsg -and $friendlyMsg.ToLower().Contains("failure")) {
              $fMArr = $friendlyMsg -split '<', 2
              $xmlcontent = "<" + ($fMArr[1] -split ',', -1)[0].Trim()
              $xml = New-Object -TypeName System.Xml.XmlDocument
              $xml.LoadXml($xmlcontent)
              $xmlString = Format-XML $xml
              Write-Host $xmlString
              $host.ui.WriteErrorLine("!!! Solution import failed !!!")
              exit 1
            }
            
            if ($completedOn) {     
              $publishFlag = $true
              break;
            }

            if ($timeSpan.TotalMinutes -gt 20) {
              $host.ui.WriteErrorLine("!!! Solution exceeded timeout !!!")
              exit 1
            }
            Start-Sleep -s $pollingInterval
          }
        } 
        catch {
          Write-Host "Exception: $_"
          $host.ui.WriteErrorLine("!!! Import-CrmSolutionAsync operation has encountered an exception !!!")
          exit 1
        }
      }
    }
  }
  if ($publish) {
    Write-Host "Publishing all customizations..."
    Publish-CrmAllCustomization -Verbose -conn $crmConnection
  }
}

exit 0
