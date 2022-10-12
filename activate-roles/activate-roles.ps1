#region Instructions
#
#
# Step 1:
#
# Verify default browser is Chrome or Edge but not IE (authentication window will not load)
#
#
# Step 2: 
#
# Change $email variable 
$email = "email@domain.com"
#
#
# Step 3:
#
# Change $path for location to save AzureADPreview PowerShell and BurntToast module (provides Win 10 Toast Notifications)
# Do not use regular PowerShell module locations. It will not work due to insufficient permissions 
$path = 'C:\Users\USER\LocalPowerShellModules\'
#
#
# Step 4: 
#
# Change $useTimer if needed:
# If true the script will prompt to restore roles at 1 and 4 hour intervals, depending on what roles are activated
# If false the script will exit after roles are activated
# See advanced settings at end of instructions for more options
$useTimer = $true
#
#
# Step 5:
#
# Run script using PowerShell window. Cd to script location then enter ".\activate-roles" or enter full path:
# e.g. C:\Users\Username\Desktop\activate-roles\activate-roles.ps1
#
# OR
#
# To setup Activate shortcut in root folder:
# Copy path to where you saved the script folder. Move Activate shortcut to Desktop and right click then go to Properties. In Shortcut tab, change the Target field:
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File "C:\Users\Username\Desktop\activate-roles\activate-roles.ps1"
# Paste the path of script folder and replace the string after -File
#
#
# Step 6: 
#
# When executing script and authentication window pops up, your $email is copied to clipboard for quick entry
#
#
# Step 7 (Optional): 
#
# To set default roles and skip beginning option menu change $null to comma separated role list wrapped in quotes e,g "1,2,4"
$defaultRoles = $null
#
#
# Advanced settings for $useTimer
#
# Set toast notification to false to disable
$toastNotification = $true
# 
# Custom icons for toast notification
$redImagePath = $PSScriptRoot + "\red.png"
$yellowImagePath = $PSScriptRoot + "\yellow.png"
$greenImagePath = $PSScriptRoot + "\green.png"
#
# Set $autoShow to false to disable automatic minimize/show of console
$autoShow = $true
#
#
#endregion

#####

#region Variables 

$debug = $false

if ($debug) {
    $countdown = 5
    $minutesIndex = 6
    $secondsIndex = 1
    $printInterval = 5
} 
else {
    $countdown = 10
    $minutesIndex = 59
    $secondsIndex = 60
    $printInterval = 20
}

# Activation call will throw policy error if attempt to set duration longer than default available
$duration1hour = "PT1H"
$duration4hour = "PT4H"

$rolesList = New-Object Collections.Generic.List[int]
$tempRolesList = New-Object Collections.Generic.List[int]

$role1 = 'Global Reader'
$role2 = 'Power Platform Administrator'
$role3 = 'Cloud Application Administrator'
$role4 = 'Dynamics 365 Administrator'
$role5 = 'Application Administrator'
$role6 = 'License Administrator'
$rolesStringList = @( "", $role1, $role2, $role3, $role4, $role5, $role6 )

#endregion

#####

#region Functions

Function Set-WindowStyle {
    param(
        [Parameter()]
        [ValidateSet('MINIMIZE', 'SHOWNORMAL')]
        $Style = 'SHOWNORMAL',
        [Parameter()]
        $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
    )

    $WindowStates = @{ MINIMIZE = 6; SHOWNORMAL = 1 }

    $Win32ShowWindowAsync = Add-Type –memberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}

Function Log($message, $newLine) {
    if ($newLine) {
        Write-Host (Get-Date).ToString("h:mm:ss tt")- $message
    }
    else {
        Write-Host (Get-Date).ToString("h:mm:ss tt")- $message -NoNewLine
    }
}

Function Activate-Roles($all) {
    if ($all) {
        $currentRolesList = $rolesList
    }
    else {
        $currentRolesList = $tempRolesList
    }

    for ($i = 0; $i -lt $currentRolesList.Count; $i++) {
        $currentRole = $rolesStringList[$currentRolesList[$i]]
        Log "Activating: $currentRole role " $false

        if (!$debug) {
            # Get role definition object via DisplayName string
            $roleDefinition = Get-AzureADMSPrivilegedRoleDefinition  -ProviderId AadRoles -ResourceId $resource.Id -Filter "DisplayName eq '$currentRole'"

            # Setup schedule object for activation
            $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
            $schedule.Type = "Once"
            $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            # Adjust duration based on role
            if ((Is-Role-4-Hour $currentRolesList[$i]) -eq $true) {
                $schedule.Duration = $duration4hour
                $durationLbl = "4 hours"
            }
            else {
                $schedule.Duration = $duration1hour
                $durationLbl = "1 hour"
            }
            Write-Host "for $durationLbl..."
    
            # If role already active the call will override with new activation at current time
            Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AadRoles -Schedule $schedule -ResourceId $resource.Id -RoleDefinitionId $roleDefinition.Id `
                -SubjectId $subject.ObjectId -AssignmentState "Active" -Type "UserAdd" -Reason "Administrator work to do"
        }
        else {
            if ((Is-Role-4-Hour $currentRolesList[$i]) -eq $true) {
                Write-Host "for 4 hours..."
            }
            else {
                Write-Host "for 1 hour..."
            }
        }
        Log "Completed activation of $currentRole role`n" $true
    }

    if ($all) {
        Log "Finished activating all roles`n" $true
    }
    else {
        Log "Finished activating 1 hour roles`n" $true
    }
}

Function Is-Role-4-Hour($tmpRole) {
    if ($tmpRole -eq 1 -or $tmpRole -eq 2 -or $tmpRole -eq 4) {
        return $true
    }
    return $false
}

Function Clear-Expired-Roles($all) {
    if ($all) {
        $tempRolesList.AddRange($rolesList)
        $rolesList.RemoveRange(0, $rolesList.Count)
        return
    }

    $toRemoveList = New-Object Collections.Generic.List[int]
    for ($i = 0; $i -lt $rolesList.Count; $i++) {
        $currRole = $rolesList[$i]
        if ((Is-Role-4-Hour $currRole) -eq $false) {
            $tempRolesList.Add($currRole)
            $toRemoveList.Add($currRole)
        }
    }

    for ($i = 0; $i -lt $toRemoveList.Count; $i++) {
        $currRole = $toRemoveList[$i]
        $rolesList.Remove($currRole) | Out-Null
    }
}

Function Reactivate-Roles-Setup($all) {
    if ($all) {
        $rolesList.AddRange($tempRolesList)
        $tempRolesList.RemoveRange(0, $tempRolesList.Count)
        return
    }

    $toRemoveList = New-Object Collections.Generic.List[int]
    for ($i = 0; $i -lt $tempRolesList.Count; $i++) {
        $currRole = $tempRolesList[$i]
        $rolesList.Add($currRole)
        $toRemoveList.Add($currRole)
    } 

    for ($i = 0; $i -lt $toRemoveList.Count; $i++) {
        $currRole = $toRemoveList[$i]
        $tempRolesList.Remove($currRole) | Out-Null
    }
}

# Wait for input function disabled, all roles renewed automatically
Function Wait-For-Input($all) {
    <#if ($all) {
        Log "All roles expiring. Press R key to renew roles..." $true
    }
    else {
        Log "1 hour roles expiring. Press R key to renew roles..." $true
    }
    
    $count = 0
    while ($count -le $countdown) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            if ($key.VirtualKeyCode -eq 82) {
                # Q = 81, R = 82
                Log "Input detected" $true
                return $true
            }
        }
        Log ("Waiting for " + ($countdown - $count) + "...") $true
        $count++
        Start-Sleep -s 1
    }

    return $false#>
    return $true
}

# Assume no activation between durations for now
Function Initiate-Renewal($all) {
    if ($all) {
        if ($toastNotification) {
            New-BurntToastNotification -AppLogo $yellowImagePath -Text "All roles expiring", 'Roles are being reactivated...' #'Press R key on console to renew'
        }

        if ($autoShow) {
            try {
                (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle SHOWNORMAL $_ }
            }
            catch {}
        }

        $input = Wait-For-Input $true
        if (!$input) {
            Log "No valid input detected. Exiting..." $true
			
            if (!$debug) {
                Disconnect-AzureAD
            }

            if ($toastNotification) {
                New-BurntToastNotification -AppLogo $redImagePath -Text "All roles expired", 'Script exiting'
            }
			
            exit
        }
        else {
            Reactivate-Roles-Setup $true
            Activate-Roles $true
			
            if ($toastNotification) {
                New-BurntToastNotification -AppLogo $greenImagePath -Text "All roles successfully activated", 'Script minimizing...'
            }
      
            if ($autoShow) {
                try {
                    (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle MINIMIZE $_ }
                } 
                catch {}
            }
			
            Start-Renewal-Timer
        }
    }
    else {
        if ($toastNotification) {
            New-BurntToastNotification -AppLogo $yellowImagePath -Text "1 hour roles expiring", 'Roles are being reactivated...' #'Press R key on console to renew'
        }
        
        if ($autoShow) {
            try {
                (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle SHOWNORMAL $_ }
            }
            catch {}
        }
        
        $input = Wait-For-Input $false
        if (!$input) {
            Log "No valid input detected. Continuing...`n" $true
            $tempRolesList.RemoveRange(0, $tempRolesList.Count);
            
            if ($rolesList.Count -ne 0) {
                if ($toastNotification) {
                    New-BurntToastNotification -AppLogo $redImagePath -Text "1 hour roles expired", 'Script continuing...'
                }
            }
      
            if ($autoShow) {
                try {
                    (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle MINIMIZE $_ }
                }
                catch {}
            }
        }
        else {
            Activate-Roles $false
            Reactivate-Roles-Setup $false

            if ($toastNotification) {
                New-BurntToastNotification -AppLogo $greenImagePath -Text "1 hour roles successfully activated", 'Script minimizing...'
            }

            if ($autoShow) {
                try {
                    (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle MINIMIZE $_ }
                }
                catch {}
            }
        }
    }
}

# Find max duration of timer based on if any 4 hour roles chosen
Function Get-Hour-Tracker {
    for ($i = 0; $i -lt $rolesList.Count; $i++) {
        $currRole = $rolesList[$i]
        if ((Is-Role-4-Hour $currRole) -eq $true) {
            return 4
        }
    }
    return 1
}

Function One-Hour-Role-Activated {
    for ($i = 0; $i -lt $rolesList.Count; $i++) {
        $currRole = $rolesList[$i]
        if ((Is-Role-4-Hour $currRole) -eq $false) {
            return $true
        }
    }
    return $false
}
$WShell = New-Object -com "Wscript.Shell"
Function Start-Renewal-Timer {
    $hourTracker = Get-Hour-Tracker
    $index = 0

    while ($index -lt $hourTracker) {
        $hoursLeft = $hourTracker - ($index + 1)
		
        for ($i = 0; $i -lt $minutesIndex; $i++) {
            if (($i % $printInterval) -eq 0) {
                Print-Active-Roles $hoursLeft ($minutesIndex - $i)
            }
            Write-Host $hoursLeft ($minutesIndex - $i)
            $WShell.sendkeys("{SCROLLLOCK}")
            Start-Sleep -Seconds $secondsIndex
            $WShell.sendkeys("{SCROLLLOCK}")
        }

        if ($index -eq 3) {
            Clear-Expired-Roles $true
            Initiate-Renewal $true
            break
        }

        if (One-Hour-Role-Activated -eq $true) {
            Clear-Expired-Roles $false
            Initiate-Renewal $false
        }

        $index++
    }
}

Function Print-Active-Roles($hour, $minute) {
    $sortedRolesList = New-Object Collections.Generic.List[int]
    
    if ($rolesList.Contains(1)) {
        $sortedRolesList.Add(1);
    }
    
    if ($rolesList.Contains(2)) {
        $sortedRolesList.Add(2)
    }

    if ($rolesList.Contains(4)) {
        $sortedRolesList.Add(4)
    }

    for ($i = 0; $i -lt $rolesList.Count; $i++) {
        if ((Is-Role-4-Hour $rolesList[$i]) -eq $false) {
            $sortedRolesList.Add($rolesList[$i])
        }
    }

    Log "Activation time remaining:" $true
    for ($i = 0; $i -lt $sortedRolesList.Count; $i++) {
        $currRole = $sortedRolesList[$i]
        $roleString = $rolesStringList[$currRole]

        if ((Is-Role-4-Hour $currRole) -eq $true) {
            if ($hour -ne 0) {
                Write-Host "    · $roleString`: $hour`h and $minute minutes left"
            } 
            else {
                Write-Host "    · $roleString`: $minute minutes left"
            }
        }
        else {
            Write-Host "    · $roleString`: $minute minutes left"
        }
    }
    Write-Host ""
}

#endregion

#####

#region Main execution

if (!$defaultRoles) {
    Write-Host "Enter comma separated number list for which roles to activate (e.g 1,2,3,4) or 0 for all`n
0 - Activate all roles
a - Activate all 1 hour roles
b - Activate all 4 hours
1 - Global Reader
2 - Power Platform Administrator
3 - Cloud Application Administrator
4 - Dynamics 365 Administrator
5 - Application Administrator
6 - License Administrator`n"
  
    $rolesString = Read-Host "Enter parameter"

    if ($rolesString -eq "0") {
        $rolesString = "1,2,3,4,5,6"
    } elseif ($rolesString -eq "a") {
        $rolesString = "3,5,6"
    } elseif ($rolesString -eq "b") {
        $rolesString = "1,2,4"
    }

    Write-Host $rolesString `n
}
else {
    $rolesString = $defaultRoles
}

# Normalize parameters into list of integers
$rolesArray = $rolesString.Split(",")

for ($i = 0; $i -lt $rolesArray.Count; $i++) {
    $tempRole = [int]$rolesArray[$i]
	
    if ($tempRole -ne 1 -and $tempRole -ne 2 -and $tempRole -ne 3 -and $tempRole -ne 4 -and $tempRole -ne 5 -and $tempRole -ne 6) {
        Write-Host "Invalid parameter. Exiting..."
        Start-Sleep -s 3
        exit
    }
	
    $rolesList.Add($tempRole)
}

# Check for existence of modules and download if needed
if (!$debug) {
    if (!(test-path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    if (!(test-path $path"AzureADPreview")) {
        Write-Host "`nDownloading AzureADPreview module... (will take a few minutes)"; 
        Write-Host "A confirmation window may appear asking to confirm untrusted package sources, click Yes to all"
        Find-Module -Name 'AzureADPreview' -Repository 'PSGallery' | Save-Module -Path $path
    }

    Import-Module -FullyQualifiedName $path"AzureADPreview"
}

if (!(test-path $path"BurntToast")) {
    Write-Host "`nDownloading BurntToast module... (will take a few minutes)"; 
    Write-Host "A confirmation window may appear asking to confirm untrusted package sources, click Yes to all`n"
    Find-Module -Name 'BurntToast' -Repository 'PSGallery' | Save-Module -Path $path
}

Import-Module -FullyQualifiedName $path"BurntToast"

if (!$debug) {
    Set-Clipboard -Value $email 
  
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

    $emailWrapped = "'$email'"
    $resource = Get-AzureADMSPrivilegedResource -ProviderId AadRoles
    $subject = Get-AzureADUser -Filter "userPrincipalName eq $emailWrapped"
}

Activate-Roles $true

if (!$useTimer) {
    Write-Host "Exiting..." 
    if (!$debug) {
        Disconnect-AzureAD
    }
    Start-Sleep -s 3
    exit
}

Log "Starting renewal timer...`n" $true
Start-Sleep -s 1

if ($autoShow) {
    try {
        (Get-Process -Name powershell).MainWindowHandle | foreach { Set-WindowStyle MINIMIZE $_ }
    }
    catch {}
}

if ($toastNotification) {
    New-BurntToastNotification -AppLogo $greenImagePath -Text "Roles successfully activated", 'Script minimizing...'
}

Start-Renewal-Timer

# Check roles count to be able to renew if user initially does not select a 4 hour role
while ($rolesList.Count -ne 0) {
    Start-Renewal-Timer
}

Log "All roles expired. Exiting..." $true
if ($toastNotification) {
    New-BurntToastNotification -AppLogo $redImagePath -Text "All roles expired", 'Script exiting'
}

#endregion
