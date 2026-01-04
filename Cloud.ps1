#region Administrator Check
$admin = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList $PSCommandPath
    exit
}
#endregion

#region Configuration
$Config = @{
    ComputerName = "VirtualMachine"

    Wallpaper = @{
        Day = @{
            Url  = "https://4kwallpapers.com/images/wallpapers/blue-background-windows-365-windows-11-stock-3840x2400-7920.png"
            Path = "C:\Users\Public\Pictures\wallpaper_day.png"
        }
        Night = @{
            Url  = "https://4kwallpapers.com/images/wallpapers/blue-background-windows-365-windows-11-stock-dark-3840x2400-7928.png"
            Path = "C:\Users\Public\Pictures\wallpaper_night.png"
        }
    }
}
#endregion

#region Helper Functions
function Write-Warn($Message) {
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        $Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
}

function Download-File {
    param (
        [string]$Url,
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Path -ErrorAction Stop
        } catch {
            Write-Warn "Failed to download: $Url"
        }
    }
}
#endregion

#region Theme & Wallpaper
function Apply-SystemTheme {
    $hour = (Get-Date).Hour
    $themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $isDay = ($hour -ge 6 -and $hour -lt 18)
    $value = if ($isDay) { 1 } else { 0 }

    try {
        Set-RegistryValue $themePath "AppsUseLightTheme" $value
        Set-RegistryValue $themePath "SystemUsesLightTheme" $value
    } catch {
        Write-Warn "Failed to apply system theme"
    }
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

function Set-Wallpaper {
    param ([string]$Path)
    if (Test-Path $Path) {
        [Wallpaper]::SystemParametersInfo(20, 0, $Path, 3) | Out-Null
    }
}

function Apply-TimeBasedWallpaper {
    $hour = (Get-Date).Hour
    $isDay = ($hour -ge 6 -and $hour -lt 18)

    if ($isDay) {
        Download-File $Config.Wallpaper.Day.Url $Config.Wallpaper.Day.Path
        Set-Wallpaper $Config.Wallpaper.Day.Path
    } else {
        Download-File $Config.Wallpaper.Night.Url $Config.Wallpaper.Night.Path
        Set-Wallpaper $Config.Wallpaper.Night.Path
    }
}
#endregion

#region System Cleanup
function Clean-Desktop {
    $Excluded = @("desktop.ini","This PC.lnk","Recycle Bin.lnk")
    $users = Get-ChildItem "C:\Users" -Directory

    foreach ($user in $users) {
        $desktop = "$($user.FullName)\Desktop"
        if (Test-Path $desktop) {
            Get-ChildItem $desktop -File |
                Where-Object { $Excluded -notcontains $_.Name } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}
#endregion

#region System Identity
function Set-ComputerNameSafe {
    param ([string]$Name)

    Set-RegistryValue `
        "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" `
        "ComputerName" $Name

    Set-RegistryValue `
        "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" `
        "ComputerName" $Name

    Set-RegistryValue `
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        "Hostname" $Name
}
#endregion

#region Main
function Main {

    Apply-SystemTheme
    Apply-TimeBasedWallpaper
    Clean-Desktop
    Set-ComputerNameSafe $Config.ComputerName

    Restart-Explorer

    Write-Host "[✓] Script completed successfully" -ForegroundColor Green
}
#endregion

Main
