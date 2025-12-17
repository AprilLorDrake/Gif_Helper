<#
.SYNOPSIS
  Create (if needed) and open a GIF folder in File Explorer.

.DESCRIPTION
  Prompts for a base folder (default: %USERPROFILE%\Pictures) and then chooses a GIF folder:
    - If the chosen folder name is gif/gifs, use it directly
    - Else if it contains a child folder named GIF/GIFs (common casing), use that
    - Else default to <base>\GIFs

  Copies the resolved GIF folder path to the clipboard and opens it in Explorer.

.PARAMETER BaseFolder
  The default base folder used when you press Enter at the prompt (or when -NonInteractive is used).

.PARAMETER NonInteractive
  Skip the prompt and use -BaseFolder directly.

.PARAMETER Help
  Show usage and exit.

.EXAMPLE
  .\open_gif_folder.ps1

.EXAMPLE
  .\open_gif_folder.ps1 -BaseFolder "D:\Media" -NonInteractive
#>

[CmdletBinding()]
param(
    [string]$BaseFolder = "$env:USERPROFILE\Pictures",
    [switch]$NonInteractive,
    [switch]$Help
)

function Show-Help {
    Write-Host "open_gif_folder.ps1" -ForegroundColor Cyan
    Write-Host "Creates/opens your GIF folder and copies the path to clipboard." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  powershell -File .\open_gif_folder.ps1" -ForegroundColor Yellow
    Write-Host "  powershell -File .\open_gif_folder.ps1 -BaseFolder `"D:\Media`" -NonInteractive" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tip: In Explorer, press Alt+P to toggle the Preview pane." -ForegroundColor Cyan
}

if ($Help) { Show-Help; exit 0 }

# Decide base folder
$inputFolder = $BaseFolder
if (-not $NonInteractive) {
    $prompt = "Enter the folder to store GIFs (press Enter for $BaseFolder)"
    $typed = Read-Host $prompt
    if (-not [string]::IsNullOrWhiteSpace($typed)) {
        $inputFolder = $typed
    }
}

# Normalize input (strip quotes/trailing slashes)
$inputFolder = $inputFolder.Trim().Trim('"').TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
if (-not $inputFolder) { $inputFolder = "$env:USERPROFILE\Pictures" }

# Choose the GIF folder intelligently
$gifFolder = $null
$leaf = Split-Path -Path $inputFolder -Leaf
if ($leaf -match '^(?i)gif(s)?$') {
    $gifFolder = $inputFolder
} else {
    $gifCandidates = @("GIFs","Gifs","gifs","GIF","gif") | ForEach-Object { Join-Path -Path $inputFolder -ChildPath $_ }
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
try { Set-Clipboard -Value $gifFolder } catch {}

Write-Host "GIF folder ready at: $gifFolder" -ForegroundColor Green
Write-Host "Path copied to clipboard." -ForegroundColor Green
Write-Host "Explorer tip: press Alt+P to toggle the Preview pane." -ForegroundColor Cyan

# Launch Explorer to that folder
Start-Process explorer.exe $gifFolder