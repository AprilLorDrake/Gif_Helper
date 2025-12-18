param(
    [string]$Target = "C:\\Projects\\Gif_Helper\\tools\\gif_viewer.bat",
    [string]$ShortcutName = "GIF Viewer.lnk",
    [string]$Hotkey = "Ctrl+Alt+G"  # Set to '' to skip
)

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop $ShortcutName

try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($shortcutPath)
    $lnk.TargetPath = $Target
    $lnk.WorkingDirectory = Split-Path -Parent $Target
    $lnk.IconLocation = "$env:SystemRoot\System32\shell32.dll,20"
    if ($Hotkey -and $Hotkey.Trim()) { $lnk.Hotkey = $Hotkey }
    $lnk.Save()
    Write-Host "Shortcut created:" $shortcutPath
    if ($Hotkey -and $Hotkey.Trim()) { Write-Host "Hotkey set:" $Hotkey }
} catch {
    Write-Host "Failed to create shortcut:" $_.Exception.Message
    exit 1
}
