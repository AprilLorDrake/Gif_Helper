Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$ErrorActionPreference = 'Stop'

# For Recycle Bin delete fallback
try { Add-Type -AssemblyName Microsoft.VisualBasic } catch {}

$logDir = Join-Path $env:APPDATA 'Gif_Helper'
$logFile = Join-Path $logDir 'viewer.log'
function Write-Log($msg) {
    try {
        if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -LiteralPath $logFile -Value ("[{0}] {1}" -f (Get-Date), $msg)
    } catch {}
}

[System.AppDomain]::CurrentDomain.add_UnhandledException({
    param($sender,$e)
    $msg = $e.ExceptionObject.ToString()
    Write-Log "Unhandled exception: $msg"
    [System.Windows.Forms.MessageBox]::Show("GIF Viewer hit an unexpected error:`n$($e.ExceptionObject.Message)`nLog: $logFile","GIF Viewer error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    if ($debugMode) {
        try { [System.Console]::WriteLine("Press Enter to exit..."); [void][System.Console]::ReadLine() } catch {}
    }
})

# Helper: enable double-buffering to reduce flicker
function Enable-DoubleBuffer {
    param($control)
    $type = $control.GetType()
    $prop = $type.GetProperty('DoubleBuffered',[System.Reflection.BindingFlags] 'NonPublic,Instance')
    if ($prop) { $prop.SetValue($control,$true,$null) }
}

$scriptDir = Split-Path -Parent $PSCommandPath
$rootDir   = Split-Path -Parent $scriptDir
$iconPngPath = Join-Path $rootDir 'resources\icon.png'
$arrowUp = [char]0x25B2
$arrowDown = [char]0x25BC
$script:suppressTreeSelect = $false
$folderIcon = $null
$driveIcon = $null
$treeImageList = New-Object System.Windows.Forms.ImageList
$treeImageList.ColorDepth = 'Depth32Bit'
$treeImageList.ImageSize = New-Object System.Drawing.Size(16,16)
$appIcon = $null
$iconBitmap = $null
if (Test-Path -LiteralPath $iconPngPath) {
    try {
        $iconBitmap = [System.Drawing.Bitmap]::FromFile($iconPngPath)
        $appIcon = [System.Drawing.Icon]::FromHandle($iconBitmap.GetHicon())
    } catch {}
}

# Load small system folder/drive icons for the tree (use SHGFI_USEFILEATTRIBUTES for consistency)
try {
    Add-Type -Namespace ShellUtil -Name NativeMethods -MemberDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class NativeMethods {
            [StructLayout(LayoutKind.Sequential)]
            public struct SHFILEINFO {
                public IntPtr hIcon;
                public int iIcon;
                public uint dwAttributes;
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szDisplayName;
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)] public string szTypeName;
            }
            [DllImport("shell32.dll")]
            public static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbFileInfo, uint uFlags);
        }
"@
    $shinfo = New-Object ShellUtil.NativeMethods+SHFILEINFO
    $flagsFolder = 0x000000100 -bor 0x000000001 -bor 0x000000010  # SHGFI_ICON | SHGFI_SMALLICON | SHGFI_USEFILEATTRIBUTES
    $attrFolder = 0x10 # FILE_ATTRIBUTE_DIRECTORY
    [ShellUtil.NativeMethods]::SHGetFileInfo('C:\DummyFolder', $attrFolder, [ref]$shinfo, [uint32][Runtime.InteropServices.Marshal]::SizeOf($shinfo), $flagsFolder) | Out-Null
    if ($shinfo.hIcon -ne [IntPtr]::Zero) { $folderIcon = [System.Drawing.Icon]::FromHandle($shinfo.hIcon).Clone() }

    $shinfo2 = New-Object ShellUtil.NativeMethods+SHFILEINFO
    $flagsDrive = 0x000000100 -bor 0x000000001 -bor 0x000000010  # SHGFI_ICON | SHGFI_SMALLICON | SHGFI_USEFILEATTRIBUTES
    $attrDrive = 0x10 # treat as directory for icon purposes
    [ShellUtil.NativeMethods]::SHGetFileInfo('C:\', $attrDrive, [ref]$shinfo2, [uint32][Runtime.InteropServices.Marshal]::SizeOf($shinfo2), $flagsDrive) | Out-Null
    if ($shinfo2.hIcon -ne [IntPtr]::Zero) { $driveIcon = [System.Drawing.Icon]::FromHandle($shinfo2.hIcon).Clone() }

    # Fallbacks if shell calls fail
    if (-not $folderIcon) { $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon((Join-Path $env:SystemRoot 'explorer.exe')) }
    if (-not $driveIcon) { $driveIcon = $folderIcon }

    if ($folderIcon) { $treeImageList.Images.Add('folder',$folderIcon) | Out-Null }
    if ($driveIcon) { $treeImageList.Images.Add('drive',$driveIcon) | Out-Null }
} catch {
    Write-Log "Failed to load shell icons: $_"
    if (-not $folderIcon) { $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon((Join-Path $env:SystemRoot 'explorer.exe')) }
    if (-not $driveIcon) { $driveIcon = $folderIcon }
    if ($folderIcon) { $treeImageList.Images.Add('folder',$folderIcon) | Out-Null }
    if ($driveIcon) { $treeImageList.Images.Add('drive',$driveIcon) | Out-Null }
}

$argFolder = $args | Select-Object -First 1
# Ignore debug flag or non-pathy argument
if ($argFolder -and $argFolder -match '^(?i)[/-]debug$') { $argFolder = $null }
if ($argFolder -and -not [System.IO.Path]::IsPathRooted($argFolder)) { $argFolder = $null }
$configDir = Join-Path $env:APPDATA 'Gif_Helper'
$configFile = Join-Path $configDir 'gif_viewer.lastpath'
$debugMode = $env:GIF_VIEWER_DEBUG -eq '1'

function Is-OneDrivePath($path) {
    if (-not $path) { return $false }
    $roots = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial) | Where-Object { $_ -and $_.Trim() -ne '' }
    try { $full = [System.IO.Path]::GetFullPath($path) } catch { return $false }

    foreach ($r in $roots) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($r)
            if ($full.StartsWith($rootFull,[System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        } catch {}
    }

    # Heuristic: any path segment named OneDrive or OneDrive - <Org> counts as OneDrive-backed
    $segments = $full -split "[\\/]" | Where-Object { $_ -ne '' }
    foreach ($seg in $segments) {
        if ($seg -match '^OneDrive(\s*-\s*.+)?$') { return $true }
    }

    return $false
}

function Load-LastFolder {
    if (Test-Path -LiteralPath $configFile) {
        try {
            $v = Get-Content -LiteralPath $configFile -ErrorAction Stop | Select-Object -First 1
            if ($v -and (Test-Path -LiteralPath $v) -and [System.IO.Path]::IsPathRooted($v)) {
                $leaf = Split-Path -Path $v -Leaf
                if (-not $argFolder -and $leaf -eq 'debug') { return $null }
                return $v
            }
        } catch {}
    }
    return $null
}

function Save-LastFolder($path) {
    try {
        if (-not (Test-Path -LiteralPath $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        Set-Content -LiteralPath $configFile -Value $path -Force -Encoding UTF8
    } catch {}
}

function Resolve-DefaultFolder {
    $candidates = @()
    if ($argFolder) { $candidates += $argFolder }
    $last = Load-LastFolder
    if ($last) { $candidates += $last }
    $candidates += @(
        (Join-Path $env:OneDrive "Pictures"),
        (Join-Path $env:OneDrive "Pictures\GIFs"),
        (Join-Path $env:USERPROFILE "Pictures"),
        (Join-Path $env:USERPROFILE "Downloads"),
        $env:USERPROFILE
    ) | Where-Object { $_ -and $_.Trim() -ne '' }

    # If no explicit argument, ignore any stray "debug" folders when choosing defaults
    if (-not $argFolder) {
        $candidates = $candidates | Where-Object { (Split-Path $_ -Leaf) -ne 'debug' }
    }

    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    # Fallback: create the first candidate
    $first = $candidates | Select-Object -First 1
    if ($first -and -not (Is-OneDrivePath $first) -and -not (Test-Path -LiteralPath $first)) {
        New-Item -ItemType Directory -Path $first -Force | Out-Null
    }
    return $first
}

$defaultFolder = Resolve-DefaultFolder

$state = [ordered]@{
    Folder = $defaultFolder
    Selection = $null
    Files = @()
    Search = ''
    Sort   = 'Name'
    SortDir = 'Asc'
}

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "GIF Helper"
$form.Width         = 1100
$form.Height        = 750
$form.StartPosition = 'CenterScreen'
$form.KeyPreview    = $true
$form.ShowInTaskbar = $true
$form.BackColor     = [System.Drawing.Color]::FromArgb(248,248,248)
$form.Font          = New-Object System.Drawing.Font('Segoe UI',10)
if ($appIcon) { $form.Icon = $appIcon }
Enable-DoubleBuffer $form

$toolStrip = New-Object System.Windows.Forms.ToolStrip
$toolStrip.GripStyle = 'Hidden'
$toolStrip.Dock = 'Top'
$toolStrip.RenderMode = 'System'
$toolStrip.Padding = '6,6,6,6'

$browseBtn = New-Object System.Windows.Forms.ToolStripButton
$browseBtn.Text = 'Browse'
$browseBtn.DisplayStyle = 'Text'
$browseBtn.ToolTipText = 'Browse for a folder'

$refreshBtn = New-Object System.Windows.Forms.ToolStripButton
$refreshBtn.Text = 'Refresh'
$refreshBtn.DisplayStyle = 'Text'
$refreshBtn.ToolTipText = 'Reload the current folder'

$copyBtn = New-Object System.Windows.Forms.ToolStripButton
$copyBtn.Text = 'Copy path'
$copyBtn.DisplayStyle = 'Text'
$copyBtn.ToolTipText = 'Copy selected GIF full path'

$deleteBtn = New-Object System.Windows.Forms.ToolStripButton
$deleteBtn.Text = 'Delete'
$deleteBtn.DisplayStyle = 'Text'
$deleteBtn.ToolTipText = 'Delete selected GIF'

$sortDrop = New-Object System.Windows.Forms.ToolStripDropDownButton
$sortDrop.Text = "Sort"
$sortDrop.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::Text

$sortByName = New-Object System.Windows.Forms.ToolStripMenuItem "Name"
$sortByDate = New-Object System.Windows.Forms.ToolStripMenuItem "Date Modified"
$sortDrop.DropDownItems.AddRange(@($sortByName,$sortByDate))

$sortDirBtn = New-Object System.Windows.Forms.ToolStripButton
$sortDirBtn.Text = $arrowUp
$sortDirBtn.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::Text
$sortDirBtn.Font = New-Object System.Drawing.Font($form.Font.FontFamily,11,[System.Drawing.FontStyle]::Regular)
$sortDirBtn.ToolTipText = "Toggle sort direction"

$searchLabel = New-Object System.Windows.Forms.ToolStripLabel
$searchLabel.Text = 'Search'

$searchBox = New-Object System.Windows.Forms.ToolStripTextBox
$searchBox.AutoSize = $false
$searchBox.Width = 200
$searchBox.ToolTipText = 'Search GIF names (case-insensitive)'

$folderLabel = New-Object System.Windows.Forms.ToolStripLabel
$folderLabel.Text = 'Folder'

$folderBox = New-Object System.Windows.Forms.ToolStripTextBox
$folderBox.AutoSize = $false
$folderBox.Width = 320
$folderBox.ReadOnly = $true
$folderBox.Enabled = $true
$folderBox.BorderStyle = 'FixedSingle'
$folderBox.ToolTipText = 'Current local folder (full path)'

$toolStrip.Items.AddRange(@(
    $browseBtn,
    $refreshBtn,
    $copyBtn,
    $deleteBtn,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $sortDrop,
    $sortDirBtn,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $folderLabel,
    $folderBox,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $searchLabel,
    $searchBox
))

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Panel1MinSize = 320
$split.Panel2MinSize = 1  # set low initially to avoid SplitterDistance errors; adjusted on Shown
$split.BackColor = [System.Drawing.Color]::FromArgb(230,230,230)

$navSplit = New-Object System.Windows.Forms.SplitContainer
$navSplit.Dock = 'Fill'
$navSplit.Panel1MinSize = 220
$navSplit.Panel2MinSize = 1   # set low initially to avoid size errors; adjusted on Shown
$navSplit.SplitterDistance = 260
$navSplit.BackColor = [System.Drawing.Color]::FromArgb(235,235,235)
$navSplit.BorderStyle = 'None'

$folderTree = New-Object System.Windows.Forms.TreeView
$folderTree.Dock = 'Fill'
$folderTree.HideSelection = $false
$folderTree.ShowLines = $true
$folderTree.ShowRootLines = $true
$folderTree.ShowPlusMinus = $true
$folderTree.PathSeparator = [System.IO.Path]::DirectorySeparatorChar
$folderTree.BorderStyle = 'None'
$folderTree.Font = New-Object System.Drawing.Font('Segoe UI',9)
$folderTree.ImageList = $treeImageList

$listView = New-Object System.Windows.Forms.ListView
$listView.Dock = 'Fill'
$listView.View = 'LargeIcon'
$listView.MultiSelect = $false
$listView.HideSelection = $false
$listView.FullRowSelect = $true
$listView.LabelEdit = $false
$listView.Sorting = 'None'
$listView.UseCompatibleStateImageBehavior = $false
$listView.BorderStyle = 'None'
Enable-DoubleBuffer $listView

$imageList = New-Object System.Windows.Forms.ImageList
$imageList.ColorDepth = 'Depth32Bit'
$imageList.ImageSize = New-Object System.Drawing.Size(128,128)
$listView.LargeImageList = $imageList

$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = 'Fill'
$previewPanel.Padding = '5,5,5,5'
$previewPanel.BackColor = [System.Drawing.Color]::White

$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = 'Fill'
$picture.SizeMode = 'Zoom'
$picture.BorderStyle = 'FixedSingle'

# Timer used to drive animated GIF playback without holding file locks.
$animTimer = New-Object System.Windows.Forms.Timer
$animTimer.Interval = 50
$script:previewStream = $null
$animTimer.Add_Tick({
    try {
        if ($picture.Image -and [System.Drawing.ImageAnimator]::CanAnimate($picture.Image)) {
            [System.Drawing.ImageAnimator]::UpdateFrames($picture.Image)
            $picture.Invalidate()
        }
    } catch {}
})

$emptyLabel = New-Object System.Windows.Forms.Label
$emptyLabel.Dock = 'Fill'
$emptyLabel.TextAlign = 'MiddleCenter'
$emptyLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Regular)
$emptyLabel.ForeColor = [System.Drawing.Color]::Gray
$emptyLabel.Visible = $false
$emptyLabel.Text = ''

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Dock = 'Bottom'
$pathLabel.AutoSize = $false
$pathLabel.Height = 30
$pathLabel.TextAlign = 'MiddleLeft'
$pathLabel.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
$pathLabel.Padding = '6,6,6,6'

$previewPanel.Controls.Add($picture)
$previewPanel.Controls.Add($emptyLabel)
$previewPanel.Controls.Add($pathLabel)
$split.Panel1.Controls.Add($listView)
$split.Panel2.Controls.Add($previewPanel)

$navSplit.Panel1.Controls.Add($folderTree)
$navSplit.Panel2.Controls.Add($split)

$status = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$status.Items.Add($statusLabel) | Out-Null

$form.Controls.Add($navSplit)
$form.Controls.Add($toolStrip)
$form.Controls.Add($status)

function Set-Status($text) {
    $statusLabel.Text = $text
}

function Format-FileSize {
    param(
        [Parameter(Mandatory=$true)][long]$Bytes
    )

    if ($Bytes -lt 1024) { return "$Bytes B" }
    if ($Bytes -lt 1MB)  { return ("{0:N0} KB" -f [Math]::Round($Bytes / 1KB)) }
    if ($Bytes -lt 1GB)  { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    return ("{0:N1} GB" -f ($Bytes / 1GB))
}

function Update-FolderDisplay {
    $folderBox.Text = $state.Folder
}

function Load-ImageUnlocked {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    # Load without holding an on-disk file lock by reading via stream, then cloning.
    $fs = $null
    $img = $null
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $img = [System.Drawing.Image]::FromStream($fs)
        return (New-Object System.Drawing.Bitmap $img)
    } finally {
        if ($img) { try { $img.Dispose() } catch {} }
        if ($fs) { try { $fs.Dispose() } catch {} }
    }
}

function Load-AnimatedImageUnlocked {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    # Read into memory so no on-disk lock is held, but keep the MemoryStream alive
    # because Image.FromStream may rely on it for multi-frame images.
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    return [pscustomobject]@{ Image = $img; Stream = $ms }
}

function Stop-PreviewAnimation {
    try { $animTimer.Stop() } catch {}
    try { if ($picture.Image) { $picture.Image.Dispose() } } catch {}
    $picture.Image = $null
    try { if ($script:previewStream) { $script:previewStream.Dispose() } } catch {}
    $script:previewStream = $null
}

function Try-DeleteFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    # Returns: @{ Deleted = $true/$false; Method = 'Remove-Item'/'RecycleBin'/'Failed'; Error = <string or $null> }
    $result = [ordered]@{ Deleted = $false; Method = 'Failed'; Error = $null }

    # Attempt direct delete first
    try {
        Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        $result.Deleted = $true
        $result.Method = 'Remove-Item'
        return $result
    } catch {
        $result.Error = $_.Exception.Message
    }

    # Fallback: send to Recycle Bin (often friendlier for OneDrive)
    try {
        $vbFsType = [Type]::GetType('Microsoft.VisualBasic.FileIO.FileSystem, Microsoft.VisualBasic', $false)
        $uiType = [Type]::GetType('Microsoft.VisualBasic.FileIO.UIOption, Microsoft.VisualBasic', $false)
        $recycleType = [Type]::GetType('Microsoft.VisualBasic.FileIO.RecycleOption, Microsoft.VisualBasic', $false)
        if ($vbFsType -and $uiType -and $recycleType) {
            $ui = [Enum]::Parse($uiType, 'OnlyErrorDialogs')
            $recycle = [Enum]::Parse($recycleType, 'SendToRecycleBin')
            $vbFsType::DeleteFile($Path, $ui, $recycle)
            $result.Deleted = $true
            $result.Method = 'RecycleBin'
            $result.Error = $null
            return $result
        }
    } catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Clear-Selection {
    $state.Selection = $null
    Stop-PreviewAnimation
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    $emptyLabel.Visible = $false
    Set-CopyButtonState
}

function Resolve-GifFolderPath {
    param(
        [string]$BasePath,
        [switch]$AllowExact
    )

    return $BasePath
}

function Set-CopyButtonState {
    if ($state.Selection) {
        $copyBtn.Enabled = $true
        $deleteBtn.Enabled = $true
    } else {
        $copyBtn.Enabled = $false
        $deleteBtn.Enabled = $false
    }
}

function Set-SortDirButton {
    if ($state.SortDir -eq 'Desc') {
        $sortDirBtn.Text = $arrowDown
    } else {
        $sortDirBtn.Text = $arrowUp
    }
}

function Add-PlaceholderNode($node) {
    $node.Nodes.Clear()
    $node.Nodes.Add('(loading...)') | Out-Null
}

function Populate-ChildDirectories($node) {
    if (-not $node -or -not $node.Tag) { return }
    $path = $node.Tag
    $node.Nodes.Clear()
    try {
        $dirs = Get-ChildItem -LiteralPath $path -Directory -ErrorAction Stop | Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::System) }
        foreach ($d in $dirs) {
            $child = New-Object System.Windows.Forms.TreeNode($d.Name)
            $child.Tag = $d.FullName
            if ($folderIcon) { $child.ImageKey = 'folder'; $child.SelectedImageKey = 'folder' }
            Add-PlaceholderNode $child
            $node.Nodes.Add($child) | Out-Null
        }
    } catch {}
}

function Populate-FolderTree {
    $folderTree.Nodes.Clear()
    $roots = @()
    if ($state.Folder) { $roots += $state.Folder }
    $roots += @(Join-Path $env:USERPROFILE 'Pictures')
    $roots += $env:USERPROFILE
    try {
        $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
        $roots += $drives
    } catch {}

    $roots = $roots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
    foreach ($r in $roots) {
        try {
            $name = Split-Path -Path $r -Leaf
            if (-not $name) { $name = $r }
            $node = New-Object System.Windows.Forms.TreeNode($name)
            $node.Tag = $r
            if ($folderIcon) { $node.ImageKey = 'folder'; $node.SelectedImageKey = 'folder' }
            Add-PlaceholderNode $node
            $folderTree.Nodes.Add($node) | Out-Null
        } catch {}
    }
}

function Select-TreeNodeForPath($path) {
    if (-not $path) { return }
    $fullTarget = [System.IO.Path]::GetFullPath($path)
    $script:suppressTreeSelect = $true
    foreach ($root in $folderTree.Nodes) {
        if (-not $root.Tag) { continue }
        $rootPath = [System.IO.Path]::GetFullPath($root.Tag)
        if (-not $fullTarget.StartsWith($rootPath,[System.StringComparison]::OrdinalIgnoreCase)) { continue }

        $folderTree.SelectedNode = $root
        Populate-ChildDirectories $root
        $root.Expand()

        $current = $root
        while ($true) {
            $next = $null
            $nextPath = $null
            foreach ($child in $current.Nodes) {
                if (-not $child.Tag) { continue }
                $candidatePath = [System.IO.Path]::GetFullPath($child.Tag)
                if ($fullTarget.StartsWith($candidatePath,[System.StringComparison]::OrdinalIgnoreCase)) {
                    $next = $child
                    $nextPath = $candidatePath
                    break
                }
            }

            if (-not $next) { break }

            $folderTree.SelectedNode = $next
            Populate-ChildDirectories $next
            $next.Expand()
            $current = $next

            if ($nextPath -and $nextPath.Equals($fullTarget,[System.StringComparison]::OrdinalIgnoreCase)) { break }
        }

        if ($folderTree.SelectedNode) { $folderTree.SelectedNode.EnsureVisible() }
        $script:suppressTreeSelect = $false
        return
    }
    $script:suppressTreeSelect = $false
}

function Set-Folder($path) {
    if (-not [string]::IsNullOrWhiteSpace($path)) {
        $resolved = Resolve-GifFolderPath -BasePath $path -AllowExact:$true
        try {
            if ($resolved -and -not (Test-Path -LiteralPath $resolved)) {
                New-Item -ItemType Directory -Path $resolved -Force | Out-Null
            }
        } catch {}
        $state.Folder = $resolved
        Update-FolderDisplay
        Save-LastFolder $resolved
    }
}

function Build-ImagesAndList {
    # Dispose old thumbnails to avoid leaking handles and potential file locks.
    try {
        foreach ($im in @($imageList.Images)) {
            try { $im.Dispose() } catch {}
        }
    } catch {}
    $imageList.Images.Clear()
    $listView.Items.Clear()

    $files = $state.Files

    # Apply search
    $search = $state.Search
    if ($search) {
        $files = $files | Where-Object { $_.Name -ilike "*${search}*" }
    }

    # Apply sort
    $descending = $false
    if ($state.SortDir -eq 'Desc') { $descending = $true }
    if ($state.Sort -eq 'Date Modified') {
        $files = $files | Sort-Object LastWriteTime -Descending:$descending
    } else {
        $files = $files | Sort-Object Name -Descending:$descending
    }

    $index = 0
    foreach ($f in $files) {
        $tag = [pscustomobject]@{ Path = $f.FullName; Valid = $false }

        try {
            $thumb = Load-ImageUnlocked -Path $f.FullName
            $w = $thumb.Width; $h = $thumb.Height
            if ($w -le 0 -or $h -le 0 -or $w -gt 8000 -or $h -gt 8000) { throw [System.ArgumentException] "Invalid image dimensions" }
            # Add clone to ImageList (do not dispose clone to avoid ImageList handle issues)
            $imageList.Images.Add($thumb) | Out-Null
            $tag.Valid = $true
        } catch {
            $tag.Valid = $false
            # Fallback blank image so the list stays aligned even for invalid/corrupt files
            $bmp = New-Object System.Drawing.Bitmap 128,128
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.Clear([System.Drawing.Color]::LightGray)
            $g.Dispose()
            $imageList.Images.Add($bmp) | Out-Null
        }

        $item = New-Object System.Windows.Forms.ListViewItem($f.Name, $index)
        $item.Tag = $tag
        $listView.Items.Add($item) | Out-Null
        $index++
    }

    if ($files.Count -eq 0) {
        Set-Status "No GIFs found in $($state.Folder)"
        $emptyLabel.Text = "No GIFs found in:`n$($state.Folder)"
        $emptyLabel.Visible = $true
    } else {
        $flt = ''
        if ($state.Search) { $flt = " (search: '$($state.Search)')" }
        Set-Status "Showing $($files.Count) GIF(s) from $($state.Folder)$flt | Sort: $($state.Sort) $($state.SortDir)"
        $emptyLabel.Visible = $false
    }
}

function Load-Files {
    Clear-Selection
    if (-not (Test-Path -LiteralPath $state.Folder)) {
        Set-Status "Folder not found: $($state.Folder)"
        return
    }
    Select-TreeNodeForPath $state.Folder
    $state.Files = Get-ChildItem -LiteralPath $state.Folder -Filter '*.gif' -File -ErrorAction SilentlyContinue
    Build-ImagesAndList
    Set-CopyButtonState
    Update-FolderDisplay
}

function Show-Preview($tag) {
    $state.Selection = $null
    Stop-PreviewAnimation
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    $emptyLabel.Visible = $false
    $path = $null
    $valid = $true
    if ($tag -is [string]) { $path = $tag }
    elseif ($tag) { $path = $tag.Path; $valid = $tag.Valid }
    if (-not $path) { Set-CopyButtonState; return }
    $state.Selection = $path

    $sizeText = $null
    $modifiedText = $null
    try {
        $fi = Get-Item -LiteralPath $path -ErrorAction Stop
        $sizeText = Format-FileSize -Bytes ([long]$fi.Length)
        $modifiedText = $fi.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    } catch {}

    if ($sizeText) {
        $pathLabel.Text = "$path  ($sizeText)"
    } else {
        $pathLabel.Text = $path
    }
    if (-not $valid) {
        $name = [System.IO.Path]::GetFileName($path)
        if ($sizeText) {
            Set-Status "Cannot preview (invalid image): $name | $sizeText"
        } else {
            Set-Status "Cannot preview (invalid image): $name"
        }
        Set-CopyButtonState
        return
    }
    try {
        $loaded = Load-AnimatedImageUnlocked -Path $path
        $script:previewStream = $loaded.Stream
        $picture.Image = $loaded.Image
        if ($picture.Image -and [System.Drawing.ImageAnimator]::CanAnimate($picture.Image)) {
            try { $animTimer.Start() } catch {}
        }
        $name = [System.IO.Path]::GetFileName($path)
        if ($sizeText -and $modifiedText) {
            Set-Status "Selected: $name | $sizeText | Modified: $modifiedText"
        } elseif ($sizeText) {
            Set-Status "Selected: $name | $sizeText"
        } else {
            Set-Status "Selected: $name"
        }
    } catch {
        $name = [System.IO.Path]::GetFileName($path)
        if ($sizeText) {
            Set-Status "Failed to preview: $name | $sizeText"
        } else {
            Set-Status "Failed to preview: $name"
        }
    }
    Set-CopyButtonState
}

function Copy-Selection {
    if (-not $state.Selection) { return }
    try {
        Set-Clipboard -Value $state.Selection
        Set-Status "Copied path: $state.Selection"
    } catch {
        Set-Status "Failed to copy path"
    }
}

function Delete-Selection {
    if (-not $state.Selection) { return }
    $path = $state.Selection
    $name = [System.IO.Path]::GetFileName($path)
    $resp = [System.Windows.Forms.MessageBox]::Show("Delete '${name}'? This cannot be undone.", 'Delete GIF', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    Write-Log "Delete requested: $path"

    # Release any loaded image/selection to avoid file locks on delete
    try { $listView.SelectedItems.Clear() } catch {}
    try { Clear-Selection } catch {}

    # Encourage .NET to release any lingering file handles quickly
    try { [GC]::Collect(); [GC]::WaitForPendingFinalizers(); [GC]::Collect() } catch {}

    $state.Selection = $null
    Set-CopyButtonState

    $deleted = $false
    $method = $null
    try {
        # First attempt (direct delete; fallback to Recycle Bin)
        $r = Try-DeleteFile -Path $path

        # Wait for the file to actually disappear (cloud sync can lag)
        for ($i=0; $i -lt 60; $i++) {
            if (-not (Test-Path -LiteralPath $path)) { $deleted = $true; $method = $r.Method; break }
            Start-Sleep -Milliseconds 75
        }

        if (-not $deleted) {
            # Second attempt after a short pause + GC
            try { [GC]::Collect(); [GC]::WaitForPendingFinalizers(); [GC]::Collect() } catch {}
            $r2 = Try-DeleteFile -Path $path
            for ($i=0; $i -lt 60; $i++) {
                if (-not (Test-Path -LiteralPath $path)) { $deleted = $true; $method = $r2.Method; break }
                Start-Sleep -Milliseconds 75
            }
        }

        if ($deleted) {
            $suffix = ''
            if ($method -eq 'RecycleBin') { $suffix = ' (moved to Recycle Bin)' }
            Set-Status "Deleted: $name$suffix"
            Write-Log "Deleted OK ($method): $path"
        } else {
            Set-Status "Delete may have failed (file still exists): $name"
            Write-Log "Delete did not remove file (still exists): $path"
            [System.Windows.Forms.MessageBox]::Show(
                "Tried to delete, but the file still exists.\n\nThis is usually caused by the file being in use (locked) or cloud-sync lag.\n\nPath:\n$path",
                'Delete failed',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    } catch {
        Set-Status "Failed to delete: $name"
        Write-Log "Delete failed: $path | $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Delete failed:\n$($_.Exception.Message)\n\nPath:\n$path\n\nLog:\n$logFile",
            'Delete failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    Load-Files
    try { $listView.Refresh(); [System.Windows.Forms.Application]::DoEvents() } catch {}
}

$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select a folder containing your GIFs'
    $dlg.SelectedPath = $state.Folder
    if ($dlg.ShowDialog() -eq 'OK') {
        Set-Folder $dlg.SelectedPath
        Load-Files
        Populate-FolderTree
        Select-TreeNodeForPath $state.Folder
    }
})

$refreshBtn.Add_Click({ Load-Files })
$copyBtn.Add_Click({ Copy-Selection })
$deleteBtn.Add_Click({ Delete-Selection })

$searchBox.Add_TextChanged({
    Clear-Selection
    $state.Search = $searchBox.Text
    Build-ImagesAndList
})

$sortByName.Add_Click({
    Clear-Selection
    $state.Sort = 'Name'
    $sortByName.Checked = $true; $sortByDate.Checked = $false
    Build-ImagesAndList
})

$sortByDate.Add_Click({
    Clear-Selection
    $state.Sort = 'Date Modified'
    $sortByName.Checked = $false; $sortByDate.Checked = $true
    Build-ImagesAndList
})

$sortDirBtn.Add_Click({
    if ($state.SortDir -eq 'Asc') { $state.SortDir = 'Desc' } else { $state.SortDir = 'Asc' }
    Set-SortDirButton
    Clear-Selection
    Build-ImagesAndList
})

$folderTree.add_BeforeExpand({
    param($sender,$e)
    Populate-ChildDirectories $e.Node
})

$folderTree.add_AfterSelect({
    param($sender,$e)
    if ($script:suppressTreeSelect) { return }
    $selectedPath = $e.Node.Tag
    if ($selectedPath) {
        Set-Folder $selectedPath
        Load-Files
    }
})

$listView.Add_ItemSelectionChanged({
    param($sender,$e)
    if ($e.IsSelected) {
        Show-Preview $e.Item.Tag
    }
})

$listView.Add_Resize({
    # Keep scroll performance reasonable by deferring layout work
    $listView.BeginUpdate()
    $listView.EndUpdate()
})

$listView.Add_DoubleClick({ Copy-Selection })

$form.Add_KeyDown({
    param($sender,$e)
    if ($e.KeyCode -in @('Enter','Space')) { Copy-Selection; $e.Handled = $true; return }
    if ($e.KeyCode -eq 'Delete') { Delete-Selection; $e.Handled = $true; return }
})

Populate-FolderTree
Set-Folder $defaultFolder
Select-TreeNodeForPath $state.Folder
Load-Files
Set-Status "Use Browse to pick the folder that contains your GIFs."
Set-CopyButtonState
Set-SortDirButton
$sortByName.Checked = $true; $sortByDate.Checked = $false

$form.add_FormClosing([System.Windows.Forms.FormClosingEventHandler]{
    param($sender,$e)
    if ($state.Folder) { Save-LastFolder $state.Folder }
    try {
        if ($appIcon) { $appIcon.Dispose() }
        if ($iconBitmap) { $iconBitmap.Dispose() }
    } catch {}
})

# After the form is shown, set a safe splitter distance based on the current client width
$form.Add_Shown({
    try {
        $split.Panel2MinSize = 360
        $available = $split.Width
        $minLeft = $split.Panel1MinSize
        $minRight = $split.Panel2MinSize
        $fallback = [Math]::Max($minLeft, [Math]::Min([int]($available * 0.45), $available - $minRight))
        if ($fallback -lt $minLeft) { $fallback = $minLeft }
        if ($fallback -gt ($available - $minRight)) { $fallback = $available - $minRight }
        if ($fallback -gt 0) { $split.SplitterDistance = $fallback }
    } catch {
        Write-Log "Main split sizing failed: $_"
    }

    try {
        $navSplit.Panel2MinSize = 320
        $navAvail = $navSplit.Width
        $navMinLeft = $navSplit.Panel1MinSize
        $navMinRight = $navSplit.Panel2MinSize
        $navFallback = [Math]::Max($navMinLeft, [Math]::Min([int]($navAvail * 0.32), $navAvail - $navMinRight - 20))
        if ($navFallback -lt $navMinLeft) { $navFallback = $navMinLeft }
        $maxNav = $navAvail - $navMinRight
        if ($navFallback -gt $maxNav) { $navFallback = $maxNav }
        if ($navFallback -gt 0) { $navSplit.SplitterDistance = $navFallback }
    } catch {
        Write-Log "Nav split sizing failed: $_"
    }
})

try {
    [System.Windows.Forms.Application]::Run($form)
} catch {
    Write-Log "Application.Run error: $_"
    [System.Windows.Forms.MessageBox]::Show("GIF Viewer failed to start:`n$($_.Exception.Message)`nLog: $logFile","GIF Viewer error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    if ($debugMode) {
        try { [System.Console]::WriteLine("Press Enter to exit..."); [void][System.Console]::ReadLine() } catch {}
    }
}
