# Mockup script for Azure DevOps YAML

# Initial setup for baseline comparison
# Export solutions manually from Dynamics and upload to /solutions at root of repository
# To extract multiple .zip, place in one directory and run PS commands:
<#$filenames = Get-ChildItem -Path $PSScriptRoot -Name -Include *.zip;
foreach ($item in $filenames){ 
    $splitFilename = $item -split '_',2
    $folderName = $splitFilename[0] + '_unmanaged_' + $splitFilename[1]
    SolutionPackager /action:Extract /zipfile:$item /folder $folderName.Split('.')[0]
 }#>

# Debug switch
$release = $false;
# SOURCE environment
$devUrl = 'https://env.crm.dynamics.com/'
# TARGET environment
#$uatUrl = 'https://env-uat.crm.dynamics.com/'
# Credentials for Dynamics environments
$adminUsername = 'email'
# Git set up
$gitEmail = 'email'
$gitUsername = 'First Lastname'
$gitCommitMsg = 'tempCommit' #Read-Host 'Enter commit message'

#region Download tools 

# Download SolutionPackager tool
if (!(Test-Path "SolutionPackager")) {
    mkdir SolutionPackager
    Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile nuget.exe
    ./nuget.exe install Microsoft.CrmSdk.CoreTools
    $coreToolsFolder = Get-ChildItem | Where-Object { $_.Name -match 'Microsoft.CrmSdk.CoreTools.' }
    Move-Item "$coreToolsFolder\content\bin\\coretools\*.*" SolutionPackager
    Remove-Item $coreToolsFolder -Force -Recurse
    Remove-Item nuget.exe
}

# Download Microsoft.Xrm.Data.Powershell module
if (!(Test-Path $PSScriptRoot"\Microsoft.Xrm.Data.Powershell")) { Find-Module -Name 'Microsoft.Xrm.Data.Powershell' -Repository 'PSGallery' | Save-Module -Path $PSScriptRoot }
Import-Module -Verbose -FullyQualifiedName $PSScriptRoot"\Microsoft.Xrm.Data.Powershell"

#endregion

# Setup working directory (s folder)
Set-Location $PSScriptRoot
Write-Host "Creating solutions directory..."
if (!(Test-Path "solutions")) {
    New-Item "solutions" -ItemType "directory"
}
else {
    Remove-Item "solutions" -Force -Recurse #-ErrorAction SilentlyContinue
    New-Item "solutions" -ItemType "directory"
}

# Get solution names from environment variable
$solutionNames = "SecurityIntake".Split(',')
$adminPassword = Read-Host 'Enter administrator password' -AsSecureString
# Decrypt secure string
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
# Get connection object for SOURCE Dynamics environment
Set-CrmConnectionTimeout -TimeoutInSeconds 600
#$devConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=Office365;Username=$adminUsername;Password=$pw;Url=$devUrl" -MaxCrmConnectionTimeOutMinutes 10
#$devConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=ClientSecret;Url=$devUrl;ClientId=guid;ClientSecret=secret" -MaxCrmConnectionTimeOutMinutes 10
$isOnPrem = "false"
Write-Host "Is on-prem:" $isOnPrem
if ($isOnPrem -eq "true") {
    devConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=Office365;Username=$adminUsername;Password=$pw;Url=$devUrl" -MaxCrmConnectionTimeOutMinutes 10
} else {
    $devConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=ClientSecret;Url=$devUrl;ClientId=guid;ClientSecret=secret" -MaxCrmConnectionTimeOutMinutes 10
}
Write-Host "Connection established with SOURCE environment:"
$devConnection
# Get connection object for TARGET Dynamics environment
#$uatConnection = Get-CrmConnection -ConnectionString "AuthType=Office365;Username=$adminUsername;Password=$pw;Url=$uatUrl"

# Export solutions from SOURCE environment solutions for version control
Write-Host "Solutions to be exported: $solutionNames"
foreach ($solution in $solutionNames) {
    Write-Host "Exporting solution: $solution"
    Export-CrmSolution -Verbose -conn $devConnection -SolutionName $solution -SolutionFilePath solutions
}

<#$solutionNames = Get-ChildItem -Path solutions -Name -File -Include *.zip
# Extract solutions for version control
foreach ($solution in $solutionNames) {
    $solutionFolder = $solution.Split(".")[0]
    Write-Host "Extracting solution: $solution"
    Start-Process SolutionPackager/SolutionPackager.exe -NoNewWindow -ArgumentList `
        "/action: Extract", `
        "/zipfile: solutions\$solution", `
        "/folder: solutions\$solutionFolder"
}#>

<#
# Copy .zip solution files to artifacts output folder (a folder)
if(!(Test-Path "artifact-output")) {
    New-Item -Path "artifact-output" -ItemType "directory" | Out-Null
} else {
    Remove-Item "artifact-output" -Force -Recurse
    New-Item "artifact-output" -ItemType "directory"
}

Write-Host "Copying solution zip files to staging directory"
Copy-Item -Path solutions\* -Destination artifact-output -Include *.zip
Write-Host "Deleting solution zip files from source directory"
Remove-Item solutions -Force -Recurse -Include *.zip
#>

<# 
# Push changes to Git (https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/git-commands?view=azure-devops&tabs=yaml&WT.mc_id=DOP-MVP-5001511)
git config --global user.email $gitEmail
git config --global user.name  $gitUsername
git add .
git commit -m $gitCommitMsg
git push origin master # git push origin HEAD:master
#>

###### Release pipeline task ######

<#
#Set-CrmConnectionTimeout -TimeoutInSeconds 600
#$uatConnection = Get-CrmConnection -Verbose -ConnectionString "AuthType=Office365;Username=$(adminUsername);Password=$(adminPassword);Url=$(environmentUrl)" -MaxCrmConnectionTimeOutMinutes 10
#Write-Host "Connection established with SOURCE environment:"
#$uatConnection

$solutionNames = Get-ChildItem -Path artifact-output -Name -File -Include *.zip
# Import solutions into TARGET environment
foreach ($solution in $solutionNames) {
    Write-Host "Importing solution: $solution"
    #Import-CrmSolution -Verbose -conn $uatConnection -SolutionFilePath artifact-output\$solution
}
#>
         
#Write-Host "Publishing all customizations..."
#Publish-CrmAllCustomization -Verbose -conn $uatConnection

###### end of task ######
