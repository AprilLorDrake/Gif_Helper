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

# Choose the GIF folder intelligently:
# - If the user already pointed at a folder named gif/gifs, use it directly.
# - Else, if the provided folder already contains a gif/gifs child, use that.
# - Else, default to <input>/GIFs.
$gifFolder = $null
$leaf = Split-Path -Path $inputFolder -Leaf
if ($leaf -match '^(?i)gif(s)?$') {
    $gifFolder = $inputFolder
} else {
    $gifCandidates = @("GIFs", "Gifs", "gifs", "GIF", "gif") | ForEach-Object { Join-Path -Path $inputFolder -ChildPath $_ }
    $gifFolder = $gifCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $gifFolder) {
        $gifFolder = Join-Path -Path $inputFolder -ChildPath "GIFs"
    }
}

# Ensure the chosen folder exists
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
