param(
    [string]$BaseFolder = "$env:USERPROFILE\Pictures"
)

# Prompt the user for a base folder (optional). If they press Enter, use the default.
$inputFolder = Read-Host "Enter the folder to store GIFs (press Enter for $BaseFolder)"
if ([string]::IsNullOrWhiteSpace($inputFolder)) {
    $inputFolder = $BaseFolder
}

# Normalize the input (strip quotes/trailing slashes)
$inputFolder = $inputFolder.Trim().Trim('"').TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)

# Use the chosen folder directly (no special GIFs subfolder handling)
$gifFolder = $inputFolder

# Ensure the chosen folder exists
if (-not (Test-Path -LiteralPath $gifFolder)) {
    New-Item -ItemType Directory -Path $gifFolder -Force | Out-Null
}

# Copy path to clipboard for quick paste in file pickers
try {
    Set-Clipboard -Value $gifFolder
} catch {}

Write-Host "GIF folder ready at: $gifFolder"
Write-Host "(Path copied to clipboard. Alt+P toggles Explorer's Preview pane; use tools\\gif_viewer.bat for animated previews.)"

# Launch Explorer to that folder (user can press Alt+P to toggle Preview pane)
Start-Process explorer.exe $gifFolder
