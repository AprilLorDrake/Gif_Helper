<#
.SYNOPSIS
  Opens a folder in Explorer and helps ensure thumbnails + Preview pane are enabled.

.DESCRIPTION
  Best-effort helper that:
    - Ensures the folder exists
    - Sets "Always show icons, never thumbnails" to OFF (IconsOnly=0) for current user
    - Opens Explorer to the folder
    - Optionally sends Alt+P to toggle Preview pane (unless -SkipSendKeys)

  This does not install a GIF preview handler. If GIFs still do not animate in the Preview pane,
  run install_gif_preview.ps1.

.PARAMETER Folder
  Folder to open in Explorer (default: %USERPROFILE%\Pictures\GIFs)

.PARAMETER SkipSendKeys
  Do not attempt to send Alt+P automatically.

.PARAMETER Help
  Show usage and exit.

.EXAMPLE
  .\enable_preview_and_thumbnails.ps1

.EXAMPLE
  .\enable_preview_and_thumbnails.ps1 -Folder "D:\Media\GIFs" -SkipSendKeys
#>

[CmdletBinding()]
param(
    [string]$Folder = "$env:USERPROFILE\Pictures\GIFs",
    [switch]$SkipSendKeys,
    [switch]$Help
)

function Show-Help {
    Write-Host "enable_preview_and_thumbnails.ps1" -ForegroundColor Cyan
    Write-Host "Opens a folder in Explorer and best-effort enables thumbnails + Preview pane." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  powershell -File .\enable_preview_and_thumbnails.ps1" -ForegroundColor Yellow
    Write-Host "  powershell -File .\enable_preview_and_thumbnails.ps1 -Folder `"D:\Media\GIFs`"" -ForegroundColor Yellow
    Write-Host "  powershell -File .\enable_preview_and_thumbnails.ps1 -SkipSendKeys" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If GIFs still do not animate in Preview pane, run install_gif_preview.ps1." -ForegroundColor Cyan
}

if ($Help) { Show-Help; exit 0 }

# Normalize input
$Folder = $Folder.Trim().Trim('"').TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
if (-not $Folder) { $Folder = "$env:USERPROFILE\Pictures\GIFs" }

# Ensure folder exists
if (-not (Test-Path -LiteralPath $Folder)) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
}

# Enable thumbnails (turn off "Always show icons, never thumbnails")
try {
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }
    New-ItemProperty -Path $adv -Name "IconsOnly" -PropertyType DWord -Value 0 -Force | Out-Null
    Write-Host "Set thumbnails setting (IconsOnly=0) for current user." -ForegroundColor Green
} catch {
    Write-Host "Could not set thumbnail registry value: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Opening folder in Explorer: $Folder" -ForegroundColor Cyan
Start-Process explorer.exe $Folder
Start-Sleep -Seconds 2

if (-not $SkipSendKeys) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        # Alt+P toggles Preview pane in Explorer
        [System.Windows.Forms.SendKeys]::SendWait('%p')
        Write-Host "Tried to toggle Preview pane (Alt+P)." -ForegroundColor Green
    } catch {
        Write-Host "Preview pane toggle attempt failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Press Alt+P manually in Explorer." -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipped Alt+P send-keys; press Alt+P manually if needed." -ForegroundColor Yellow
}