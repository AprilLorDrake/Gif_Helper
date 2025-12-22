# PowerShell script to de-duplicate .gif files in a folder
# Removes files with the same base name (ignoring trailing special characters/numbering) and same size

param()

function Prompt-ForFolder($prompt) {
    while ($true) {
        $folder = Read-Host $prompt
        if ([string]::IsNullOrWhiteSpace($folder)) {
            Write-Host "Path cannot be empty. Try again." -ForegroundColor Yellow
            continue
        }
        if (-not (Test-Path $folder -PathType Container)) {
            Write-Host "Folder does not exist: $folder" -ForegroundColor Yellow
            continue
        }
        return (Resolve-Path $folder).Path
    }
}

$folder = Prompt-ForFolder "Enter the folder to de-duplicate (.gif files only):"
$files = Get-ChildItem -Path $folder -File -Filter *.gif

# Helper: get base name without trailing (n) or special chars
function Get-BaseName($name) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
    # Remove trailing ' (n)' or ' - Copy' or similar patterns
    $base = $base -replace ' \([0-9]+\)$',''
    $base = $base -replace ' - Copy$',''
    $base = $base -replace '[-_ ]+$',''
    return $base.ToLower()
}

$seen = @{}
$dups = @()

foreach ($file in $files) {
    $base = Get-BaseName $file.Name
    $key = "$base|$($file.Length)"
    if ($seen.ContainsKey($key)) {
        $dups += $file
    } else {
        $seen[$key] = $file.FullName
    }
}

if ($dups.Count -eq 0) {
    Write-Host "No duplicates found." -ForegroundColor Green
    exit
}

Write-Host "Found $($dups.Count) duplicate(s):" -ForegroundColor Yellow
$dups | ForEach-Object { Write-Host $_.FullName -ForegroundColor Cyan }

$confirm = Read-Host "Delete these duplicate files? (y/n)"
if ($confirm -match '^(y|Y)') {
    foreach ($dup in $dups) {
        Remove-Item $dup.FullName -Force
        Write-Host "Deleted: $($dup.FullName)" -ForegroundColor Red
    }
} else {
    Write-Host "No files deleted." -ForegroundColor Yellow
}
