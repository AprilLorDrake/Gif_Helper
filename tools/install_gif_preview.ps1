<#
.SYNOPSIS
  Opens pages to install a reliable GIF preview handler for Windows Explorer.

.DESCRIPTION
  Many Windows setups do not animate GIFs in Explorer's Preview pane by default.
  This helper opens IrfanView (64-bit) and the Plugins page so you can install support.

  After installing:
    - Close all Explorer windows (or reboot)
    - Open the GIF folder
    - Press Alt+P to show the Preview pane
    - Click a GIF to confirm it animates

.PARAMETER Help
  Show usage and exit.
#>

[CmdletBinding()]
param(
    [switch]$Help
)

function Show-Help {
    Write-Host "install_gif_preview.ps1" -ForegroundColor Cyan
    Write-Host "Opens IrfanView + Plugins download pages to improve GIF preview support." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  powershell -File .\install_gif_preview.ps1" -ForegroundColor Yellow
}

if ($Help) { Show-Help; exit 0 }

Write-Host "This helper opens download pages for IrfanView (64-bit) and its Plugins pack." -ForegroundColor Cyan
Write-Host "After installing both, restart Explorer (or reboot), then press Alt+P and click a GIF." -ForegroundColor Cyan
Write-Host ""

$ivCore   = 'https://www.irfanview.com/64bit.htm'
$ivPlugin = 'https://www.irfanview.com/plugins.htm'

Write-Host "Opening IrfanView 64-bit download page..." -ForegroundColor Yellow
Start-Process $ivCore

Write-Host "Opening IrfanView Plugins download page..." -ForegroundColor Yellow
Start-Process $ivPlugin