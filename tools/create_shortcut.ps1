param(
    [string]$Target = $null,
    [string]$ShortcutName = "GIF Helper.lnk",
    [string]$Hotkey = "Ctrl+Alt+G"  # Set to '' to skip
)

Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $PSCommandPath
$rootDir   = Split-Path -Parent $scriptDir
$defaultTarget = Join-Path $scriptDir 'gif_viewer.bat'
if (-not $Target -or -not [System.IO.Path]::IsPathRooted($Target)) {
    $Target = $defaultTarget
}
$iconPng   = Join-Path $rootDir 'resources\icon.png'
$iconDir   = Join-Path $env:APPDATA 'Gif_Helper'
$iconIco   = Join-Path $iconDir 'icon.ico'

function Ensure-ShortcutIcon {
    param(
        [string]$PngPath,
        [string]$IcoPath
    )

    if (-not (Test-Path -LiteralPath $PngPath)) { return $null }
    try {
        $dir = Split-Path -Parent $IcoPath
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        # Build a real .ico (DIB/BMP based) to ensure Windows Shell can render it reliably.
        $src = [System.Drawing.Bitmap]::FromFile($PngPath)
        try {
            $w = [Math]::Min(256, [Math]::Max(16, $src.Width))
            $h = [Math]::Min(256, [Math]::Max(16, $src.Height))
            $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.DrawImage($src, 0, 0, $w, $h)
            $g.Dispose()

            $data = $bmp.LockBits(
                (New-Object System.Drawing.Rectangle 0,0,$w,$h),
                [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
            )
            try {
                $stride = $data.Stride
                $raw = New-Object byte[] ($stride * $h)
                [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $raw, 0, $raw.Length)

                # XOR (BGRA) bottom-up
                $xor = New-Object byte[] ($w * $h * 4)
                for ($y=0; $y -lt $h; $y++) {
                    $srcRow = $y * $stride
                    $dstRow = ($h - 1 - $y) * ($w * 4)
                    [Array]::Copy($raw, $srcRow, $xor, $dstRow, $w * 4)
                }

                # AND mask (1bpp) padded to 32 bits per row
                $andStride = ((($w + 31) / 32) -as [int]) * 4
                $and = New-Object byte[] ($andStride * $h)
                for ($y=0; $y -lt $h; $y++) {
                    for ($x=0; $x -lt $w; $x++) {
                        $a = $raw[($y * $stride) + ($x * 4) + 3]
                        if ($a -eq 0) {
                            $row = ($h - 1 - $y)  # AND mask is also bottom-up
                            $byteIndex = ($row * $andStride) + [int]($x / 8)
                            $bit = 7 - ($x % 8)
                            $and[$byteIndex] = $and[$byteIndex] -bor (1 -shl $bit)
                        }
                    }
                }

                $imgSize = 40 + $xor.Length + $and.Length
                $offset = 6 + 16

                $fs = [System.IO.File]::Open($IcoPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
                try {
                    $bw = New-Object System.IO.BinaryWriter($fs)

                    # ICONDIR
                    $bw.Write([UInt16]0)  # reserved
                    $bw.Write([UInt16]1)  # type = icon
                    $bw.Write([UInt16]1)  # count

                    # ICONDIRENTRY
                    $wByte = if ($w -ge 256) { [Byte]0 } else { [Byte]$w }
                    $hByte = if ($h -ge 256) { [Byte]0 } else { [Byte]$h }
                    $bw.Write($wByte)
                    $bw.Write($hByte)
                    $bw.Write([Byte]0)    # color count
                    $bw.Write([Byte]0)    # reserved
                    $bw.Write([UInt16]1)  # planes
                    $bw.Write([UInt16]32) # bitcount
                    $bw.Write([UInt32]$imgSize)
                    $bw.Write([UInt32]$offset)

                    # BITMAPINFOHEADER
                    $bw.Write([UInt32]40)
                    $bw.Write([Int32]$w)
                    $bw.Write([Int32]($h * 2))
                    $bw.Write([UInt16]1)
                    $bw.Write([UInt16]32)
                    $bw.Write([UInt32]0)  # BI_RGB
                    $bw.Write([UInt32]($xor.Length + $and.Length))
                    $bw.Write([Int32]0)
                    $bw.Write([Int32]0)
                    $bw.Write([UInt32]0)
                    $bw.Write([UInt32]0)

                    $bw.Write($xor)
                    $bw.Write($and)

                    $bw.Flush()
                } finally {
                    $fs.Close()
                }

                if (Test-Path -LiteralPath $IcoPath) { return $IcoPath }
                Write-Host "Icon generation failed: ICO not found after write" -ForegroundColor Yellow
                return $null
            } finally {
                $bmp.UnlockBits($data)
            }
        } finally {
            $src.Dispose()
        }
    } catch {
        Write-Host "Icon generation error: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop $ShortcutName
$shortcutIcon = Ensure-ShortcutIcon -PngPath $iconPng -IcoPath $iconIco

try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($shortcutPath)
    $lnk.TargetPath = $Target
    $lnk.WorkingDirectory = Split-Path -Parent $Target
    if ($shortcutIcon -and (Test-Path -LiteralPath $shortcutIcon)) {
        $lnk.IconLocation = "$shortcutIcon,0"
    } else {
        $lnk.IconLocation = "$env:SystemRoot\System32\shell32.dll,20"  # folder icon fallback
    }
    if ($Hotkey -and $Hotkey.Trim()) { $lnk.Hotkey = $Hotkey }
    $lnk.Save()
    Write-Host "Shortcut created:" $shortcutPath
    if ($shortcutIcon) { Write-Host "Icon set:" $shortcutIcon } else { Write-Host "Icon fallback: shell32.dll,20" }
    if ($Hotkey -and $Hotkey.Trim()) { Write-Host "Hotkey set:" $Hotkey }
} catch {
    Write-Host "Failed to create shortcut:" $_.Exception.Message
    exit 1
}
