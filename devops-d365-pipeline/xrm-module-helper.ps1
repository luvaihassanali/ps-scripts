param([string]$url = "default", [string]$username = "user", [string]$password = "pass", [string]$solutionNames = "", [string]$onPremises = "true", [string]$task = "export", [string]$solutionFilePath = "path", [string]$solutionOrder = "dependencyOrder")

# https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell/blob/master/Microsoft.Xrm.Data.PowerShell/Microsoft.Xrm.Data.PowerShell.psm1
Import-Module -FullyQualifiedName $modulePath # -Verbose

# Convert linearized xml into readable format
function Format-XML([xml]$xml)
{
  $stringWriter = New-Object System.IO.StringWriter
  $xmlWriter = New-Object System.XMl.XmlTextWriter $stringWriter
  $xmlWriter.Formatting = “indented”
  $xmlWriter.Indentation = 2
  $xml.WriteContentTo($xmlWriter)
  $xmlWriter.Flush()
  $stringWriter.Flush()
  return $stringWriter.ToString()
}

function Export-Solutions
{
  # Get solution names from pipeline variable
  $slnNames = "$solutionNames".Split(',')
  Write-Host "Solutions to be exported: $slnNames"
  # If flag remains false no solutions were exported
  $exportFlag = $false
  # Create solutions folder if it does not exist in working directory
  if (-not (Test-Path -Path "$solutionFilePath\solutions"))
  {
    # Out-Null to prevent directory info from logging
    New-Item -Path "$solutionFilePath" -Name "solutions" -ItemType "directory" | Out-Null 
  }
  # Loop through all solutions set in pipeline variable
  foreach ($solution in $slnNames)
  {
    Write-Host "-" # log separator
    Write-Host "Exporting solution: $solution to $solutionFilePath\solutions"
    try
    {
      # Out-Null to prevent final export result from logging
      Export-CrmSolution -Verbose -conn $crmConnection -SolutionName $solution -SolutionFilePath "$solutionFilePath\solutions" | Out-Null
      $exportFlag = $true
    } 
    catch
    {
      Write-Host "Exception: $_"
      $host.ui.WriteErrorLine("Export-CrmSolution operation encountered an exception.")
      exit 1
    }
  }
  # If no solutions were exported pipeline will fail
  if (!$exportFlag)
  {
    $host.ui.WriteErrorLine("No solutions were exported, check variable names.")
    exit 1
  }
  Write-Host "-" # log separator
  Write-Host "Completed exporting solutions."
}

# Convert dateTime from Get-CrmRecord calls
function Convert-UtcToEst
{
  param([string] $time)
  $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
  $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($time, $tz)
  return $localTime.ToString()
}

function Import-Solutions
{
  # Second interval between querying async job status
  $pollingInterval = 5
  # Collect .zip artifacts from pipeline working directory
  $slnNames = Get-ChildItem -Path $solutionFilePath -Name -File -Include *.zip
  # Pipeline variable to manage solution dependency order
  $slnOrder = $solutionOrder.Split(',')
  # If flag remains false no solutions were imported
  $publishFlag = $false
  Write-Host "Solutions to be imported: $slnOrder"
  
  # Verify solution order variable in case of any dependencies
  foreach ($solutionOrderName in $slnOrder)
  {
    foreach ($solution in $slnNames)
    {
      $startTime = Get-Date
      if ($solutionOrderName -eq $solution.Split('_')[0])
      {
        Write-Host "-" # log separator
        Write-Host "Importing solution: $solutionFilePath\$solution"
        try
        {
          $startTime = Get-Date
          # Issue with Import-CrmSolution synchronous method https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell.Samples/issues/23
          $asyncId = Import-CrmSolutionAsync -OverwriteUnManagedCustomizations -ActivateWorkflows -conn $crmConnection -SolutionFilePath "$solutionFilePath\$solution"

          # Query System Jobs table for async operations filtered by ID returned
          Write-Host "Querying async job ID:" $asyncId.AsyncJobId "| Start time:" $startTime.ToString();
          while ($true)
          {
            try
            {
              $asyncResult = Get-CrmRecord -conn $crmConnection -EntityLogicalName asyncoperation -Id $asyncId.AsyncJobId -Fields * 
            } 
            catch
            {
              Write-Host "Exception: $_"
              $host.ui.WriteErrorLine("Get-CrmRecord operation encountered an exception.")
              # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
              Start-Sleep -s 1
              exit 1
            }

            # Keep track of elapsed time
            $stopTime = Get-Date
            $elapsedTimeSpan = $stopTime - $startTime

            # Gather details from async job record
            $stateCode = $asyncResult.statecode
            $friendlyMsg = $asyncResult.friendlymessage
            # Format details for output
            if ($friendlyMsg)
            {
              $xmlMsg = "`nXML content:" 
            }
            $completedOn = $asyncResult.completedon
            if ($completedOn)
            {
              $completedOn = Convert-UtcToEst $completedOn
              $completedOn = "| End time: $completedOn" 
            }
            # Log output details
            Write-Host "Elapsed time: $elapsedTimeSpan | State code: $stateCode $completedOn $xmlMsg"

            # Return error for import failure
            if ($friendlyMsg -and $friendlyMsg.ToLower().Contains("failure"))
            {
              # Format xml string from record (trim first sentence before xml message)
              $friendlyMsgArr = $friendlyMsg -split '<', 2
              $xmlcontent = "<" + ($friendlyMsgArr[1] -split ',', -1)[0].Trim()
              # Load xml string into xml object
              $xml = New-Object -TypeName System.Xml.XmlDocument
              $xml.LoadXml($xmlcontent)
              # Pretty print xml message
              $xmlString = Format-XML $xml
              Write-Host $xmlString
              $host.ui.WriteErrorLine("Solution import failed.")
              # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
              Start-Sleep -s 1
              exit 1
            }
            
            # Return error when import of solution is unable to start
            if ($friendlyMsg -and $friendlyMsg.ToLower().Contains("cannot start"))
            {     
              $errMsg = "Cannot start the requested operation [Import] because there is another [EntityCustomization] running at this moment. Please try re-deploying the pipeline at a later time."
              Write-Host $errMsg
              $host.ui.WriteErrorLine($errMsg)
              # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
              Start-Sleep -s 1
              exit 1;
            }

            # Move to next solution when completed on $asyncResult.completedon != null
            if ($completedOn)
            {
              $id = $asyncId.AsyncJobId
              Write-Host "Async job $id complete"
              $publishFlag = $true
              break;
            }

            # Solution import timeout of 20 minutes
            if ($elapsedTimeSpan.TotalMinutes -gt 20)
            {
              $host.ui.WriteErrorLine("Solution exceeded timeout.")
              # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
              Start-Sleep -s 1
              exit 1
            }

            # Delay next async job query
            Start-Sleep -s $pollingInterval
          }
        } 
        catch
        {
          Write-Host "Exception: $_"
          $host.ui.WriteErrorLine("Import-CrmSolutionAsync operation encountered an exception.")
          # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
          Start-Sleep -s 1
          exit 1
        }
      }
    }
  }
  # Publish all imported solutions
  if ($publishFlag)
  {
    Write-Host "-" # log separator
    Write-Host "Completed exporting solutions"
    Write-Host "Publishing all customizations..."
    Publish-CrmAllCustomization -Verbose -conn $crmConnection
  }
  else
  {
    Write-Host "Exception: $_"
    $host.ui.WriteErrorLine("No solutions were imported, check variable names.")
    # Sleep for a second to ensure log received fully on process xrm-module-caller.ps1
    Start-Sleep -s 1
    exit 1
  }
}

# If environment is on-premises collect administrator username and password from pipeline variables
# Provide parameters for xrm-module-helper.ps1 script to start Microsoft.Xrm.Data module
if ($onPremises -eq "true")
{
  $crmConnection = Get-CrmConnection -ConnectionString "AuthType=Office365;Username=$username;Password=$password;Url=$url" -MaxCrmConnectionTimeOutMinutes 60 #-Verbose
}
else
{
  $crmConnection = Get-CrmConnection -ConnectionString "AuthType=ClientSecret;Url=$url;ClientId=$clientId;ClientSecret=$clientSecret" -MaxCrmConnectionTimeOutMinutes 60 #-Verbose
}
Write-Host "Connection established with TARGET environment:" $crmConnection.ConnectedOrgFriendlyName

if ($task -eq "export")
{
  Export-Solutions
}
elseif ($task -eq "import")
{
  Import-Solutions
}

exit 0
