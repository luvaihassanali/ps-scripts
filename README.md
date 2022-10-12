# PowerShell scripts

### activate-roles
Activates, tracks, and renews Azure Administrator PIM roles. Uses AzureAD Preview module and BurntToast for Windows 10 notifications.

### azure-devops-dynamics-365-pipeline
Setup Azure DevOps pipeline to work with on-prem/cloud Dynamics 365 solutions

### bak-to-cloud
Simple backup script with progress bar. Deletes files in existing target location and copies source directory.

### dynamics-multi-upload
Script for Dynamics 365 on-premise solutions to avoid having to manually upload files. Created to facilitate upload of client written help guide (Word document converted to HTML page) with ~300 images.

### ExtractUsers
Uses Azure module to export list of users from filtered groups to a formatted excel table. 

### startup 
Script which waits for processes on power on, makes certain clicks, and launches certain programs to make mornings easier.

### Notes
```
$date = "{0:s}" -f (get-date)
$date = $date.Replace(":","-")
$apps = Get-AdminPowerApp
$apps | Export-Csv -Path ".\Get-AdminPowerApp-$date.csv" -NoTypeInformation
```
