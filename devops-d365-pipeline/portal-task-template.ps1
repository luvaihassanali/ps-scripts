# TASK 1 Initialize PAC CLI

$pacPath = "$(libraryPath)\$(_portalPacPath)"
Write-Host "PAC CLI path set to: $pacPath"
# task.setvariable allows variable to be available to tasks in the same job
echo "##vso[task.setvariable variable=pacPath]$pacPath"

# TASK 2 Migrate portal configuration

# https://docs.microsoft.com/en-us/power-apps/maker/portals/admin/migrate-portal-configuration?tabs=CLI
# Portal name variable must appear as website record name field in portal management application

# Link initialization of PAC CLI from previous task
$env:PATH = $env:PATH + ";" + "$(pacPath)"
$portalFilePath = "$(libraryPath)\portal-files"

# Create source authentication profile
Write-Host "Creating source authentication profile $(_portalSourceProfile) for environment $(_portalSourceEnvironment)"
pac auth create --name $(_portalSourceProfile) --url $(_portalSourceEnvironment) -t $(_portalTenantId) -id $(_portalClientId) -cs $(_portalClientSecret)
# Create target authentication profile
Write-Host "Creating target authentication profile $(_portalTargetProfile) for environment $(_portalTargetEnvironment)" 
pac auth create --name $(_portalTargetProfile) --url $(_portalTargetEnvironment) -t $(_portalTenantId) -id $(_portalClientId) -cs $(_portalClientSecret)

# List profiles
Write-Host "Executing pac auth list command..."
pac auth list

# Select source environment
Write-Host "Selecting source profile..."
pac auth select --name $(_portalSourceProfile)

# List all website ids
pac paportal list

# If 1+ portals in environment match name to ID
$portalInfo = pac paportal list
foreach ($portalEntry in $portalInfo)
{    
  if ($portalEntry -like "*$(_portalName)*")
  {
    $portalParts = $portalEntry.Split([string[]] $null, 'RemoveEmptyEntries')
    $websiteId = $portalParts[1]
  }
}

# Fail pipeline if no match was found
if (!$websiteId)
{
  Write-Host "No portal named $(_portalName) found in environment $(_portalTargetEnvironment)! Rename target portal record in Portal Management to match source."
  exit 1
}

# Create portal files directory
Write-Host "Downloading portal files for $websiteId"
mkdir $portalFilePath

# Download portal config
pac paportal download --path $portalFilePath --webSiteId $websiteId #--overwrite true

# Select target environment
Write-Host "Selecting target profile..."
pac auth select --name $(_portalTargetProfile)

# Upload portal config
Write-Host "Uploading files to target environment"
$siteName = "$(_portalName)".Replace(" ", "-")
pac paportal upload --path $portalFilePath\$siteName

# Clear profiles
pac auth clear

# Delete portal files directory
Write-Host "Deleting portal files and authentication profiles"
Remove-Item $portalFilePath -Recurse -Force
