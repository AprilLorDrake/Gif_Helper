param(
    [string]$BaseFolder = "$env:USERPROFILE\Pictures"
)

# Prompt the user for a base folder (optional). If they press Enter, use the default.
$inputFolder = Read-Host "Enter the folder to store GIFs (press Enter for $BaseFolder)"
if ([string]::IsNullOrWhiteSpace($inputFolder)) {
    $inputFolder = $BaseFolder
}

# Ensure the GIFs subfolder exists
$gifFolder = Join-Path -Path $inputFolder -ChildPath "GIFs"
if (-not (Test-Path -LiteralPath $gifFolder)) {
    New-Item -ItemType Directory -Path $gifFolder -Force | Out-Null
}

# Copy path to clipboard for quick paste in file pickers
try {
    Set-Clipboard -Value $gifFolder
} catch {}

Write-Host "GIF folder ready at: $gifFolder"
Write-Host "(Path copied to clipboard. Press Alt+P in Explorer to show the Preview pane.)"

# Launch Explorer to that folder (user can press Alt+P to toggle Preview pane)
Start-Process explorer.exe $gifFolder
