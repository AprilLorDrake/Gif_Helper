# PowerShell script to move files from one directory to another, skipping files with same name and size, renaming files with same name but different size, and prompting for deletion of originals.

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

$source = Prompt-ForFolder "Enter the SOURCE folder path:"
$dest = Prompt-ForFolder "Enter the DESTINATION folder path:"

$files = Get-ChildItem -Path $source -File -Filter *.gif
$movedFiles = @()

foreach ($file in $files) {
    $destFile = Join-Path $dest $file.Name
    if (Test-Path $destFile) {
        $destInfo = Get-Item $destFile
        if ($destInfo.Length -eq $file.Length) {
            Write-Host "Skipping (same name and size): $($file.Name)" -ForegroundColor Cyan
            continue
        } else {
            # Rename: add (n) before extension
            $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $ext = [System.IO.Path]::GetExtension($file.Name)
            $n = 1
            do {
                $newName = "${base} ($n)$ext"
                $newDestFile = Join-Path $dest $newName
                $n++
            } while (Test-Path $newDestFile)
            Move-Item $file.FullName $newDestFile
            $movedFiles += $file.FullName
            Write-Host "Renamed and moved: $($file.Name) -> $newName" -ForegroundColor Green
        }
    } else {
        Move-Item $file.FullName $destFile
        $movedFiles += $file.FullName
        Write-Host "Moved: $($file.Name)" -ForegroundColor Green
    }
}

if ($movedFiles.Count -gt 0) {
    $confirm = Read-Host "Delete original files that were moved from source? (y/n)"
    if ($confirm -match '^(y|Y)') {
        foreach ($orig in $movedFiles) {
            if (Test-Path $orig) {
                Remove-Item $orig -Force
                Write-Host "Deleted: $orig" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Original files NOT deleted." -ForegroundColor Yellow
    }
} else {
    Write-Host "No files were moved. Nothing to delete." -ForegroundColor Yellow
}
