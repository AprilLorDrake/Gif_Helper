param(
    [string]$Target = "C:\\Projects\\Gif_Helper\\tools\\gif_viewer.bat",
    [string]$ShortcutName = "GIF Viewer.lnk"
)

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop $ShortcutName

try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($shortcutPath)
    $lnk.TargetPath = $Target
    $lnk.WorkingDirectory = Split-Path -Parent $Target
    $lnk.IconLocation = "$env:SystemRoot\System32\shell32.dll,20"
    $lnk.Save()
    Write-Host "Shortcut created:" $shortcutPath
} catch {
    Write-Host "Failed to create shortcut:" $_.Exception.Message
    exit 1
}
