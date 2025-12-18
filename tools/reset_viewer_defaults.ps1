# Reset GIF Viewer defaults by removing the remembered last folder.
$lastPathFile = Join-Path $env:APPDATA 'Gif_Helper/gif_viewer.lastpath'
try {
    if (Test-Path -LiteralPath $lastPathFile) {
        Remove-Item -LiteralPath $lastPathFile -ErrorAction Stop
        Write-Output "Removed: $lastPathFile"
    } else {
        Write-Output "No lastpath file to remove at: $lastPathFile"
    }
    Write-Output "Defaults reset. Next launch will fall back to the standard Pictures/GIFs path unless you pick another folder."
} catch {
    Write-Output "Failed to reset defaults: $_"
    exit 1
}
