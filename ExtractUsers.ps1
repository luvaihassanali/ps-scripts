# Uncomment Install-Module lines on first execution to download modules
#Install-Module -Name azuread -Scope CurrentUser -Force
#Install-Module -name ImportExcel -Scope CurrentUser -Force
Import-Module azuread
Import-Module ImportExcel

# Login with account that has privileges to read groups
try {
    Connect-AzureAD | Out-Null
}
catch {
    $message = $_.Exception.message
    # Don't fix typo otherwise if statement won't execute
    if ($message.Contains("User canceled authentication")) {
        Write-Host "User cancelled authentication. Exit"
    }
    else {
        Write-Host "An error occurred during connection to AzureAD that could not be resolved. Wait a few minutes and try again. Exit"
    }
    exit
}

# Get all groups then filter if string contains the word target (can take time on larger tenants)
$azureGroups = Get-AzureADGroup -All $True | Where-Object { $_.DisplayName -like ('*target*') }

# Loop through every target group
foreach ($group in $azureGroups) {
  $groupName = $group.DisplayName
  Write-Host "Exporting group $groupName"
  # Get all users from group
  $users = $group | Get-AzureADGroupMember -All $true
  # Filter relevant columns
  $data = $users | Select-Object ObjectId, DisplayName, Mail, LastDirSyncTime, Department, JobTitle, City, Country
  # Remove previous downloaded sheet if exists
  Remove-Item $PSScriptRoot\$groupName.xlsx -Force -ErrorAction SilentlyContinue
  # Export data as xlsx file
  $data | Export-Excel -Path $PSScriptRoot\$groupName.xlsx -KillExcel -WorkSheetname "$groupName" -ClearSheet -BoldTopRow -AutoSize -TableName $groupName -TableStyle Medium6 -FreezeTopRow
}

# Create excel COM object
$excelObject = New-Object -ComObject excel.application
# Hide excel windows
$excelObject.Visible = $false
# Hide user prompts
$excelObject.DisplayAlerts = $false

# Collect generated sheets
$excelFiles = Get-ChildItem -Path $PSScriptRoot -Filter *.xlsx
# Create new workbook object
$workbook = $excelObject.Workbooks.add()
# Create temporary sheet for copying
$worksheet = $Workbook.Sheets.Item("Sheet1")

# Loop through all files and copy sheet into one workbook
foreach ($file in $excelFiles) {
  # Skip files that have already been generated
  if (!$file.FullName.Contains("All-Licenses-")) {
    Write-Host "Merging $file"
    $currWorkbook = $excelObject.Workbooks.Open($file.FullName)
    $currSheet = $currWorkbook.Sheets.Item(1)
    $currSheet.Copy($worksheet)
    $currWorkbook.Close()
  }
}

# Delete temporary sheet
$worksheet = $workbook.Sheets.Item("Sheet1")
$worksheet.Delete()
# Save merged file with current date
$date = "{0:s}" -f (get-date)
$date = $date.Replace(":",".")
$workbook.SaveAs("$PSScriptRoot\All-Licenses-$date.xlsx")
$excelObject.Quit()

# Remove temp sheets
cd $PSScriptRoot
$excelFiles = Get-ChildItem -Path $PSScriptRoot -Filter String*.xlsx
Remove-Item $excelFiles -Force