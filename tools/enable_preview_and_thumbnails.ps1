param(
    [string]$Folder = "$env:USERPROFILE\Pictures\GIFs",
    [switch]$SkipSendKeys
)

# Normalize input
$Folder = $Folder.Trim().Trim('"').TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
if (-not $Folder) {
    $Folder = "$env:USERPROFILE\Pictures\GIFs"
}

# Ensure folder exists (best effort)
if (-not (Test-Path -LiteralPath $Folder)) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
}

# Ensure preview-friendly settings
$reg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if (-not (Test-Path -Path $reg)) {
    New-Item -Path $reg -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $reg -Name IconsOnly -Type DWord -Value 0 -ErrorAction SilentlyContinue              # thumbnails on
Set-ItemProperty -Path $reg -Name DisablePreviewPane -Type DWord -Value 0 -ErrorAction SilentlyContinue     # allow preview pane
Set-ItemProperty -Path $reg -Name ShowPreviewHandlers -Type DWord -Value 1 -ErrorAction SilentlyContinue    # enable preview handlers

# Restart Explorer to apply
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Launch Explorer to the folder
Start-Process explorer.exe $Folder
Start-Sleep -Seconds 2

if (-not $SkipSendKeys) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait('%p')
    } catch {
        Write-Host "Preview pane toggle attempt failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipped Alt+P send-keys; press Alt+P manually if needed." -ForegroundColor Yellow
}
