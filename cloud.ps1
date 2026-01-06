# 1) Ensure script is running as Administrator
$admin = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList $PSCommandPath
    exit
}

$Config = @{
    ComputerName  = "CloudPC"
    WallpaperUrl  = "https://www.windowslatest.com/wp-content/uploads/2024/11/Windows-365-Link-Light.jpg"
    WallpaperPath = "C:\Users\Public\Pictures\wallpaper.png"
    OEMModel      = "Virtual Machine"
}

# Registry helper: sets a registry value, creates path if it doesn't exist
function Set-RegistryValue {
    param ([string]$Path, [string]$Name, $Value)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
}

function Download-File {
    param ([string]$Url, [string]$Path)
    if (-not (Test-Path $Path)) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Path -ErrorAction Stop
        } catch {}
    }
}


function Apply-SystemTheme {
    $themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValue $themePath "AppsUseLightTheme" 1
    Set-RegistryValue $themePath "SystemUsesLightTheme" 1
}

Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(
        int uAction, int uParam, string lpvParam, int fuWinIni
    );
}
"@

function Apply-Wallpaper {
    Download-File $Config.WallpaperUrl $Config.WallpaperPath
    if (Test-Path $Config.WallpaperPath) {
        [Wallpaper]::SystemParametersInfo(20, 0, $Config.WallpaperPath, 3) | Out-Null
    }
}


function Clean-Desktop {
    $Excluded = @("desktop.ini","This PC.lnk","Recycle Bin.lnk")
    Get-ChildItem "C:\Users" -Directory | ForEach-Object {
        $desktop = "$($_.FullName)\Desktop"
        if (Test-Path $desktop) {
            Get-ChildItem $desktop -File -ErrorAction SilentlyContinue |
                Where-Object { $Excluded -notcontains $_.Name } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Close-FileExplorer {
    try {
        $shell = New-Object -ComObject Shell.Application
        $shell.Windows() | Where-Object {
            $_.Name -in @("File Explorer", "Windows Explorer")
        } | ForEach-Object {
            $_.Quit()
        }
    } catch {
        Write-Host "Failed to close File Explorer windows." -ForegroundColor Yellow
    }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}


function Set-ComputerNameSafe {
    param ([string]$Name)
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" "ComputerName" $Name
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" "ComputerName" $Name
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "Hostname" $Name
}


function Main {
    Apply-SystemTheme
    Apply-Wallpaper
    Clean-Desktop
    Set-ComputerNameSafe $Config.ComputerName

    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" "Model" $Config.OEMModel

    Restart-Explorer
    Close-FileExplorer

    Write-Host "Script completed successfully" -ForegroundColor Green
}

Main
