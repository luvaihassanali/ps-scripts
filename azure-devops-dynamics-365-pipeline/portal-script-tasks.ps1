# AZURE DEV OPS TASKS
# TASK 1

$pacPath = "$(libraryPath)\$(portalPacPath)"
Write-Host "Setting PAC CLI path to: $pacPath"
echo "##vso[task.setvariable variable=pacPath]$pacPath"

# TASK 2

# https://docs.microsoft.com/en-us/power-apps/maker/portals/admin/migrate-portal-configuration?tabs=CLI
# Portal name variable must appear as website record name field in portal management application

$env:PATH = $env:PATH + ";" + "$(pacPath)"
$portalFilePath = "$(libraryPath)\portal-files"

# Create authentication profiles
Write-Host "Creating source authentication profile $(portalSourceProfile) for environment $(portalSourceEnvironment)"
pac auth create --name $(portalSourceProfile) --url $(portalSourceEnvironment) -t $(portalTenantId) -id $(portalClientId) -cs $(portalClientSecret)
Write-Host "Creating target authentication profile $(portalTargetProfile) for environment $(portalTargetEnvironment)" 
pac auth create --name $(portalTargetProfile) --url $(portalTargetEnvironment) -t $(portalTenantId) -id $(portalClientId) -cs $(portalClientSecret)

# List profiles
Write-Host "Executing pac auth list command..."
pac auth list

# Select source environment
Write-Host "Selecting source profile..."
pac auth select --name $(portalSourceProfile)

# List all website ids
pac paportal list

# If 1+ portals in environment match name to ID
$portalInfo = pac paportal list
foreach ($portalEntry in $portalInfo) {    
  if($portalEntry -like "*$(portalName)*") {
    $portalParts = $portalEntry.Split([string[]] $null, 'RemoveEmptyEntries')
    $websiteId = $portalParts[1]
  }
}

# Create portal files directory
Write-Host "Downloading portal files for $websiteId"
mkdir $portalFilePath

# Download portal config (use overwrite flag if downloading to existing portal config folder)
pac paportal download --path $portalFilePath --webSiteId $websiteId #--overwrite true

# Select target environment
Write-Host "Selecting target profile..."
pac auth select --name $(portalTargetProfile)

# Upload portal config
Write-Host "Uploading files to target environment"
$siteName = "$(portalName)".Replace(" ", "-")
pac paportal upload --path $portalFilePath\$siteName

# Clear profiles
pac auth clear
# Delete portal files directory
Remove-Item $portalFilePath -Recurse -Force
Write-Host "Cleared portal files and authentication profiles"

<#
# DRAFT TEST SCRIPT

param([string]$portalName="luv-dev",[string]$sourceAuthProfile="luv-dev", [string]$sourceEnvironment="", [string]$targetAuthProfile="luv-tst", [string]$targetEnvironment="")

# https://docs.microsoft.com/en-us/power-apps/maker/portals/admin/migrate-portal-configuration?tabs=CLI
# Portal name parameter must appear as website record name field in portal management application
$portalFilePath = "$PSScriptRoot\portal-files"

# Create authentication profiles
Write-Host "Creating source authentication profile $sourceAuthProfile for environment $sourceEnvironment"
pac auth create --name $sourceAuthProfile --url $sourceEnvironment -t tenantId -id appId -cs clientSecret
Write-Host "Creating target authentication profile $targetAuthProfile for environment $targetEnvironment" 
pac auth create --name $targetAuthProfile --url $targetEnvironment -t tenantId -id appId -cs clientSecret

# List profiles
pac auth list

# Select source environment
Write-Host "Selecting source profile..."
pac auth select --name $sourceAuthProfile

# List all website ids
pac paportal list

# If 1+ portals in environment match name to ID
$portalInfo = pac paportal list
foreach($portalEntry in $portalInfo) {    
  if($portalEntry -like "*$portalName*") {
    $portalParts = $portalEntry.Split([string[]] $null, 'RemoveEmptyEntries')
    $websiteId = $portalParts[1]
  }
}

# Create portal files directory
Write-Host "Downloading portal files for $websiteId"
mkdir $portalFilePath

# Download portal config (use overwrite flag if downloading to existing portal config folder)
pac paportal download --path $portalFilePath --webSiteId $websiteId #--overwrite true

# Select target environment
Write-Host "Selecting target profile..."
pac auth select --name $targetAuthProfile

# Upload portal config
Write-Host "Uploading files to target environment"
$siteName = $portalName.Replace(" ", "-")
pac paportal upload --path $portalFilePath\$siteName

# Clear profiles
pac auth clear

# Delete portal files directory
Remove-Item $portalFilePath -Recurse -Force
Write-Host "Cleared portal files and authentication profiles"
#>
