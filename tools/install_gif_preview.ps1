<#!
Guides the user to install a reliable GIF preview handler for Explorer's Preview pane.
- Opens IrfanView (64-bit) download page and the matching Plugins page in the default browser.
- Instructs the user to install IrfanView first, then Plugins, then reopen Explorer and press Alt+P.
No silent installs are performed.
#>

Write-Host "This helper will open the IrfanView 64-bit download pages so you can install GIF preview support." -ForegroundColor Cyan
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host " 1) Download and install IrfanView 64-bit." -ForegroundColor Cyan
Write-Host " 2) Download and install the IrfanView 64-bit Plugins pack." -ForegroundColor Cyan
Write-Host " 3) Reopen File Explorer, press Alt+P to show the Preview pane, and click a GIF to confirm it animates." -ForegroundColor Cyan
Write-Host "" 

$ivCore   = 'https://www.irfanview.com/64bit.htm'
$ivPlugin = 'https://www.irfanview.com/plugins.htm'

Write-Host "Opening IrfanView 64-bit download page..." -ForegroundColor Yellow
Start-Process $ivCore

Write-Host "Opening IrfanView Plugins download page..." -ForegroundColor Yellow
Start-Process $ivPlugin

Write-Host "After installing both, restart Explorer (or reboot), press Alt+P in Explorer, and try clicking a GIF." -ForegroundColor Cyan