# 1) Ensure script is running as Administrator
$admin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb runAs -ArgumentList $PSCommandPath
    exit
}

# 2) Change Computer Name and Update OEM Information
$newComputerName = "VirtualMachine"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -Value $newComputerName -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name "ComputerName" -Value $newComputerName -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value $newComputerName -Force

$OEMPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
if (-not (Test-Path $OEMPath)) {
    New-Item -Path $OEMPath -Force | Out-Null
}

Set-ItemProperty -Path $OEMPath -Name "Model" -Value "Github runner" -Force

# 3) Apply Theme (Light/Dark) based on time
function Apply-Theme {
    $currentHour = (Get-Date).Hour
    $themePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $requiredTheme = if ($currentHour -ge 6 -and $currentHour -lt 18) { 1 } else { 0 }

    try {
        $currentTheme = (Get-ItemProperty -Path $themePath -Name AppsUseLightTheme).AppsUseLightTheme
        if ($currentTheme -ne $requiredTheme) {
            Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value $requiredTheme
            Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value $requiredTheme
        }
    } catch {}
}

# 4) Clean Desktop (with exclusions)
function Clean-Desktop {
    $Excluded = @("desktop.ini","This PC.lnk","Recycle Bin.lnk")
    $users = Get-ChildItem "C:\Users" -Directory

    foreach ($u in $users) {
        $desk = "$($u.FullName)\Desktop"
        if (Test-Path $desk) {
            Get-ChildItem $desk -File |
            Where-Object { $Excluded -notcontains $_.Name } |
            Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

# 5) Download Wallpaper
function Download-Wallpaper {
    param([string]$URL, [string]$Path)

    if (-not (Test-Path $Path)) {
        try { Invoke-WebRequest -Uri $URL -OutFile $Path -ErrorAction Stop } catch {}
    }
}

# 6) Set Wallpaper
function Set-Wallpaper {
    param([string]$ImagePath)
    if (-not (Test-Path $ImagePath)) { return }

    Add-Type @"
using System.Runtime.InteropServices;
public class WP {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    [WP]::SystemParametersInfo(20, 0, $ImagePath, 3) | Out-Null
}

# 7) Hide Windows Terminal and File Explorer
function Hide-Windows {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

    $wt = Get-Process | Where-Object {
        $_.ProcessName -eq "WindowsTerminal" -and $_.MainWindowHandle -ne 0
    }
    foreach ($proc in $wt) {
        [void][Win32]::ShowWindow($proc.MainWindowHandle, 0)
    }

    $shell = New-Object -ComObject Shell.Application
    $windows = $shell.Windows() | Where-Object { $_.Name -eq "File Explorer" }
    foreach ($window in $windows) {
        $window.Quit()
    }
}

# Main Execution
$wallURL  = "https://microsoft.design/wp-content/uploads/2025/07/Brand-Flowers-Static-1.png"
$wallPath = "C:\Users\Public\Pictures\wallpaper.png"

Apply-Theme

Clean-Desktop

Download-Wallpaper -URL $wallURL -Path $wallPath

reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Set-Wallpaper -ImagePath $wallPath

Hide-Windows
