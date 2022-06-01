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

# Uncomment for positional values
#while($true) { $currPos = [System.Windows.Forms.Cursor]::Position; Write-Host $currPos; Start-Sleep -s 1 }

$offset = 8
Function ClickAtPosition($x, $y) {
    [Clicker]::LeftClickAtPoint($x, $y + $offset)
    Start-Sleep -s 1
}

while ($true) {
    Write-Host "Waiting for LastLogon"
    $isRunning = Get-Process "LastLogon" -ErrorAction SilentlyContinue
    if ($isRunning) {
        break
    }
    Start-Sleep -s 2
}

# Wait for LastLogon GUI to load
Start-Sleep -s 1
# Click LastLogon accept
ClickAtPosition 964 1016
# Wait for GUI to close
Start-Sleep -s 1

# Click Sticky Notes taskbar icon to make it stop blinking
[Clicker]::LeftClickAtPoint(57, 1063)

while ($true) {
    Write-Host "Waiting for Cisco"
    $isRunning = Get-Process "vpnui" -ErrorAction SilentlyContinue
    if ($isRunning) {
        break
    }
    Start-Sleep -s 2
}

# Wait for Cisco GUI to load
Start-Sleep -s 1
# Click Cisco tray icon
ClickAtPosition 1687 1062
# Click Cisco connect button
ClickAtPosition 1838 727
# Click Cisco input field
ClickAtPosition 1381 685

Write-Host "Waiting for VPN to connect..."
while ($true) {
    $status = (Get-NetAdapter -InterfaceIndex 2) | Select-Object -ExpandProperty Status
    Write-Host "Network adapter status:" $status
    if ($status -ne "Disabled") {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex 2 | Select-Object -ExpandProperty IPAddress)
        if ($ip.StartsWith("#")) {
            break
        }
    }
    Start-Sleep -s 2
}

# Start Outlook and Teams
Start-Process -FilePath 'path to OUTLOOK.EXE'
Start-Process -FilePath 'path to Teams.exe'