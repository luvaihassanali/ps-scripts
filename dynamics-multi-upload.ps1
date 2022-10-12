#region C# import

# https://stackoverflow.com/questions/39353073/how-i-can-send-mouse-click-in-powershell
# https://www.reddit.com/r/PowerShell/comments/m1hztx/move_mouse_and_click_using_powershell/

$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{ 
    public int        type; // 0 = INPUT_MOUSE,
                            // 1 = INPUT_KEYBOARD
                            // 2 = INPUT_HARDWARE
    public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
    public int    dx ;
    public int    dy ;
    public int    mouseData ;
    public int    dwFlags;
    public int    time;
    public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void LeftClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}

public static void RightClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}

}
'@
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms, System.Drawing

#Send a click at a specified point
#[Clicker]::RightClickAtPoint(600,600)
#Start-Sleep -Seconds 1.5
#$Pos = [System.Windows.Forms.Cursor]::Position
#[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point( (($Pos.X) + 10) , (($Pos.Y)+240) )
#[Clicker]::LeftClickAtPoint((($Pos.X) + 10) , (($Pos.Y)+240))

#endregion

#region Readme

##############################################
#    ____                _                   #
#   |  _ \ ___  __ _  __| |_ __ ___   ___    #
#   | |_) / _ \/ _` |/ _` | '_ ` _ \ / _ \   #
#   |  _ <  __/ (_| | (_| | | | | | |  __/   #
#   |_| \_\___|\__,_|\__,_|_| |_| |_|\___|   #
#                                            #
##############################################

<# WARNING: All local copies of files to be uploaded will be renamed with prefix "_"

This script automates uploading of web resource files to an on-prem dynamics solution. 
Place script in a directory with files to be uploaded and go through configuration steps: 
 
 # Step 1: 
     a) Open on premise Dynamics solution page and click Web Resource tab
     b) Move window inline with start bar at bottom left corner

 # Step 2:
     a) Uncomment line below (while loop) and run script. The console will print cursor x, y values every 1 second.
     b) Fill in the positional values for variablesby hovering mouse over area defined by variable and log x, y values into respective variables below
     c) Once new values are logged, re-comment the while loop line
     Note: If you find while running the script mouse clicks are not on target, adjust the offset values below
     Another note: If running 1920x1080 and you do not maximize browser windows, editing these variables may not be required #>

#while($true) { $currPos = [System.Windows.Forms.Cursor]::Position; Write-Host $currPos; Start-Sleep -s 1 }

# New button
$newX = 236
$newY = 609
# Resource type dropdown
$typeDropdownX = 835
$typeDropdownY = 650
# For the following 4 options, click the resource type drop down then hover over the selection
# JPG option
$jpgX = 745
$jpgY = 765
# PNG option
$pngX = 745
$pngY = 747
# HTML option
$htmlX = 745
$htmlY = 683
# XML option
$xmlX = 745
$xmlY = 730
# Choose File button
$chooseFileX = 760
$chooseFileY = 700
# Save button
$saveX = 606
$saveY = 309
# Close button
$closeX = 1355
$closeY = 200

# !!! WARNING: Edit only as required !!! 
# Offset covers discrepancy (added to x, y values) between read cursor values and click function
# Try the script first and if clicks are not on target then edit the values
$xOffset = 0
$yOffset = 8

<# Step 3 (read step b before executing step a):
     a) Upload first file maunally so Dynamics remembers directory
     b) Take note of time (in seconds) is takes for the actions listed below (newDelay, uploadDelay, etc.) and update variables below if necessary
       i. Open a new resource page dialog from the solution web resource tab
       ii. Upload a file
       iii. Save a new resource
     c) Rename first file with prefix "_" so script will skip it during execution #>

# The actions for variables below are heavily dependent on connection speed, choose higher values for slower connection
# Delay for opening new resource dialog
$newDelay = 3
# Delay for saving the resource (for larger files increase)
$saveDelay = 2

<# Step 4
     a) If uploading files to a sub directory edit variable below as required (leave as empty string otherwise)
     b) Update solution prefix variable to match the current solution publisher (can be left as "" too) #>

# Sub directory path
$subdir = "dir_files/"
# Publisher prefix
$pubPrefix = "prefix_"

<# Step 5
     a) Read notes below to prepare for any caveats while running script

--- NOTES ---
1. Script can be stopped/started at anytime but if last file processed was marked "Done" but was not uploaded, rename the file to remove "_" prefix
2. Using 1920x1080 resolution and browser windows are not maximized, script should work out of box without any edits
3. I assume filename does not contain '.' char. Filename is split by '.' to get extension so an update to script will be required to cover if filename contains '.'
4. If filetype is not jpg, png, html, or xml an update to script will be required
5. I suggest to monitor the script since dynamics can be prone to crashes, with default delay values at about ~100 uploads Chrome browser window freeze has been observed
6. The largest file size upload tested was ~300KB with 2s save delay. The save delay would need to be increased for larger files
7. With default delay values 4 uploads/min was achieved
8. Main for loop uses file count for condition but can be changed to any number lower then that to upload in batches instead of all at once
9. First upload of the day is slower then rest and script usually is too fast. Manually upload first file to get Dynamics warmed up to workaround
10. If save click does not work and Leave page prompt shows it means Dynamics crashed, refresh 
11. I did not add delay between typing filename and in some cases name is left blank but web resource still saves because all requirements are filled. To detect situation see error checking below:

ERROR CHECKING: Using edge with dev tools open, browse to HTML page web resources are being uploaded for and the console will 4output 04 error for any missing resource files

#>

################# END README #################
#endregion

Function ClickAtPosition($x, $y) {
    [Clicker]::LeftClickAtPoint($x + $xOffset, $y + $yOffset)
    Start-Sleep -s 1
}

# Debug variable used for script development (no save/rename if true)
$debug = $false
# List all filenames in directory excluding those prefixed with "_"
# Note: Can update Get-ChildItem command for more complex uploads i.e. multi folder structure
$filenames = Get-ChildItem -Path $PSScriptRoot -Name -Exclude "_*" -File

# Edit right side of condition to upload in batches instead of all at once
for ($i = 0; $i -lt $filenames.Count; $i++) { 
    $currFile = $filenames[$i]
    # Do not process script itself
    if ($currFile -eq "dynamics-multi-upload.ps1") {
        continue
    }
    Write-Host "Processing file:" $currFile
    # Edit here to deal with filenames containing '.'
    $currFileExt = $currFile.Split('.')[1]
    
    # Click New button
    ClickAtPosition $newX $newY
    Start-Sleep -s $newDelay
    # Type Name
    $name = $subdir + $currFile
    [System.Windows.Forms.SendKeys]::SendWait($name)
    # Type Tab to move to next field
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    # Type Display Name
    $displayName = $pubPrefix + $name
    [System.Windows.Forms.SendKeys]::SendWait($displayName)

    # Click Resource type dropdown
    ClickAtPosition $typeDropdownX $typeDropdownY
    # Click type selection based off file extension
    if ($currFileExt -eq "jpg") {
      ClickAtPosition $jpgX $jpgY
    } elseif ($currFileExt -eq "png") {
        ClickAtPosition $pngX $pngY
    } elseif ($currFileExt -eq "html") {
        ClickAtPosition $htmlX $htmlY
    } elseif ($currFileExt -eq "xml") {
        ClickAtPosition $xmlX $xmlY
    }

    # Click Choose File 
    ClickAtPosition $chooseFileX $chooseFileY
    # Wait for dialog to open 
    Start-Sleep -s 2
    # Type filename
    [System.Windows.Forms.SendKeys]::SendWait($currFile)
    # Type Enter to close new file dialog
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -s 1

    if (!$debug) {
        # Click Save button
        ClickAtPosition $saveX $saveY
        Start-Sleep -s $saveDelay
        # Click Close button
        ClickAtPosition $closeX $closeY
        # Rename file with prefix "_" so script does not process if it is run again
        Rename-Item -Path $PSScriptRoot\$currFile -NewName _$currFile
    }

    Write-Host "Done"
    # Wait a second before continuing
    Start-Sleep -s 1
}