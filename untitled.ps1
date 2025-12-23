# 1) Ensure script is running as Administrator
$admin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb runAs -ArgumentList $PSCommandPath
    exit
}

# Function: Set registry value safely (create path if needed)
function Set-RegistryValue {
    param($Path, $Name, $Value)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
}

# Function: Apply Light/Dark Theme based on time
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
    } catch {
        Write-Host "Unable to apply theme." -ForegroundColor Yellow
    }
}

# Function: Clean Desktop files (with exclusions)
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

# Function: Download Wallpaper from URL
function Download-Wallpaper {
    param([string]$URL, [string]$Path)

    if (-not (Test-Path $Path)) {
        try { Invoke-WebRequest -Uri $URL -OutFile $Path -ErrorAction Stop } 
        catch { Write-Host "Failed to download wallpaper." -ForegroundColor Yellow }
    }
}

# Function: Set Wallpaper
Add-Type @"
using System.Runtime.InteropServices;
public class WP {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
function Set-Wallpaper {
    param([string]$ImagePath)
    if (-not (Test-Path $ImagePath)) { return }
    [WP]::SystemParametersInfo(20, 0, $ImagePath, 3) | Out-Null
}

# Function: Hide Windows Terminal and File Explorer
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
function Hide-Windows {
    # Hide Windows Terminal
    $wt = Get-Process | Where-Object { $_.ProcessName -eq "WindowsTerminal" -and $_.MainWindowHandle -ne 0 }
    foreach ($proc in $wt) { [void][Win32]::ShowWindow($proc.MainWindowHandle, 0) }

    # Close File Explorer windows
    $shell = New-Object -ComObject Shell.Application
    $windows = $shell.Windows() | Where-Object { $_.Name -eq "File Explorer" }
    foreach ($window in $windows) { $window.Quit() }
}

# Variables / Settings
$newComputerName = "VirtualMachine"
$OEMModel = "Github runner"
$wallURL  = "https://microsoft.design/wp-content/uploads/2025/07/Brand-Flowers-Static-1.png"
$wallPath = "C:\Users\Public\Pictures\wallpaper.png"

# Main Execution
function Main {

    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -Value $newComputerName
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name "ComputerName" -Value $newComputerName
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value $newComputerName

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Model" -Value $OEMModel

    Apply-Theme

    Clean-Desktop

    Download-Wallpaper -URL $wallURL -Path $wallPath
    Set-Wallpaper -ImagePath $wallPath

    Hide-Windows

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe

    New-Item 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Force | 
        Set-ItemProperty -Name '(Default)' -Value ''
}

Main
