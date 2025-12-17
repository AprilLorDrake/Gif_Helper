Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Helper: enable double-buffering to reduce flicker
function Enable-DoubleBuffer {
    param($control)
    $type = $control.GetType()
    $prop = $type.GetProperty('DoubleBuffered',[System.Reflection.BindingFlags] 'NonPublic,Instance')
    if ($prop) { $prop.SetValue($control,$true,$null) }
}

$argFolder = $args | Select-Object -First 1
$configDir = Join-Path $env:APPDATA 'Gif_Helper'
$configFile = Join-Path $configDir 'gif_viewer.lastpath'

function Load-LastFolder {
    if (Test-Path -LiteralPath $configFile) {
        try {
            $v = Get-Content -LiteralPath $configFile -ErrorAction Stop | Select-Object -First 1
            if ($v -and (Test-Path -LiteralPath $v)) { return $v }
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
        (Join-Path $env:USERPROFILE "Pictures\GIFs"),
        (Join-Path $env:USERPROFILE "Pictures\gifs"),
        (Join-Path $env:OneDrive "Pictures\GIFs"),
        (Join-Path $env:OneDrive "Pictures\gifs")
    ) | Where-Object { $_ -and $_.Trim() -ne '' }

    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    # Fallback: create the first candidate
    $first = $candidates | Select-Object -First 1
    if ($first -and -not (Test-Path -LiteralPath $first)) {
        New-Item -ItemType Directory -Path $first -Force | Out-Null
    }
    return $first
}

$defaultFolder = Resolve-DefaultFolder

$state = [ordered]@{
    Folder = $defaultFolder
    Selection = $null
    Files = @()
    Filter = ''
    Sort   = 'Name'
    SortDir = 'Asc'
}

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "GIF Viewer"
$form.Width         = 1100
$form.Height        = 750
$form.StartPosition = 'CenterScreen'
$form.KeyPreview    = $true
$form.BackColor     = [System.Drawing.Color]::FromArgb(248,248,248)
$form.Font          = New-Object System.Drawing.Font('Segoe UI',10)
Enable-DoubleBuffer $form

$topPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$topPanel.FlowDirection = 'LeftToRight'
$topPanel.WrapContents  = $false
$topPanel.Dock          = 'Top'
$topPanel.Height        = 64
$topPanel.Padding       = '8,8,8,8'
$topPanel.AutoSize      = $false
$topPanel.AutoScroll    = $true
$topPanel.BackColor     = [System.Drawing.Color]::FromArgb(235,238,243)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text      = 'Folder:'
$folderLabel.AutoSize  = $true
$folderLabel.Margin    = '0,10,6,0'

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.ReadOnly = $true
$folderBox.Width    = 420
$folderBox.Margin   = '0,6,10,0'
$folderBox.Height   = 28

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text    = 'Browse...'
$browseBtn.Margin  = '0,6,6,0'
$browseBtn.FlatStyle = 'System'
$browseBtn.AutoSize = $true
$browseBtn.AutoSizeMode = 'GrowAndShrink'
$browseBtn.Padding = '6,3,6,3'

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text   = 'Refresh'
$refreshBtn.Margin = '0,6,6,0'
$refreshBtn.FlatStyle = 'System'
$refreshBtn.AutoSize = $true
$refreshBtn.AutoSizeMode = 'GrowAndShrink'
$refreshBtn.Padding = '6,3,6,3'

$copyBtn = New-Object System.Windows.Forms.Button
$copyBtn.Text   = 'Copy path'
$copyBtn.Margin = '0,6,6,0'
$copyBtn.FlatStyle = 'System'
$copyBtn.AutoSize = $true
$copyBtn.AutoSizeMode = 'GrowAndShrink'
$copyBtn.Padding = '6,3,6,3'
$copyBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 241, 220)
$copyBtn.UseVisualStyleBackColor = $false

$deleteBtn = New-Object System.Windows.Forms.Button
$deleteBtn.Text   = 'Delete'
$deleteBtn.Margin = '0,6,6,0'
$deleteBtn.FlatStyle = 'System'
$deleteBtn.AutoSize = $true
$deleteBtn.AutoSizeMode = 'GrowAndShrink'
$deleteBtn.Padding = '6,3,6,3'
$deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(248, 221, 221)
$deleteBtn.UseVisualStyleBackColor = $false

$filterLabel = New-Object System.Windows.Forms.Label
$filterLabel.Text = 'Filter:'
$filterLabel.AutoSize = $true
$filterLabel.Margin = '12,10,6,0'

$filterBox = New-Object System.Windows.Forms.TextBox
$filterBox.Width = 160
$filterBox.Margin = '0,6,10,0'
$filterBox.Height = 28

$sortLabel = New-Object System.Windows.Forms.Label
$sortLabel.Text = 'Sort:'
$sortLabel.AutoSize = $true
$sortLabel.Margin = '12,10,6,0'

$sortCombo = New-Object System.Windows.Forms.ComboBox
$sortCombo.DropDownStyle = 'DropDownList'
$sortCombo.Items.AddRange(@('Name','Date Modified'))
$sortCombo.SelectedIndex = 0
$sortCombo.Width = 140
$sortCombo.Margin = '0,6,10,0'
$sortCombo.Height = 28

$sortDirLabel = New-Object System.Windows.Forms.Label
$sortDirLabel.Text = 'Dir:'
$sortDirLabel.AutoSize = $true
$sortDirLabel.Margin = '10,10,6,0'

$sortDirCombo = New-Object System.Windows.Forms.ComboBox
$sortDirCombo.DropDownStyle = 'DropDownList'
$sortDirCombo.Items.AddRange(@('Asc','Desc'))
$sortDirCombo.SelectedIndex = 0
$sortDirCombo.Width = 80
$sortDirCombo.Margin = '0,6,0,0'
$sortDirCombo.Height = 28

$topPanel.Controls.AddRange(@($folderLabel,$folderBox,$browseBtn,$refreshBtn,$copyBtn,$deleteBtn,$filterLabel,$filterBox,$sortLabel,$sortCombo,$sortDirLabel,$sortDirCombo))

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Panel1MinSize = 320
$split.Panel2MinSize = 360
# Set a safe initial splitter distance after min sizes are defined
$split.SplitterDistance = [Math]::Max($split.Panel1MinSize, [Math]::Min(450, $form.Width - $split.Panel2MinSize - 50))
$split.BackColor = [System.Drawing.Color]::FromArgb(230,230,230)

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

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Dock = 'Bottom'
$pathLabel.AutoSize = $false
$pathLabel.Height = 30
$pathLabel.TextAlign = 'MiddleLeft'
$pathLabel.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
$pathLabel.Padding = '6,6,6,6'

$previewPanel.Controls.Add($picture)
$previewPanel.Controls.Add($pathLabel)
$split.Panel1.Controls.Add($listView)
$split.Panel2.Controls.Add($previewPanel)

$status = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$status.Items.Add($statusLabel) | Out-Null

$form.Controls.Add($split)
$form.Controls.Add($topPanel)
$form.Controls.Add($status)

function Set-Status($text) {
    $statusLabel.Text = $text
}

function Resolve-GifFolderPath($basePath) {
    if (-not $basePath) { return $basePath }
    $leaf = Split-Path -Path $basePath -Leaf
    if ($leaf -match '^(gif|gifs)$') { return $basePath }

    $gifChild = Join-Path $basePath 'GIFs'
    $altChild = Join-Path $basePath 'gifs'
    if (Test-Path -LiteralPath $gifChild) { return $gifChild }
    if (Test-Path -LiteralPath $altChild) { return $altChild }
    return $gifChild
}

function Set-CopyButtonState {
    if ($state.Selection) {
        $copyBtn.Enabled = $true
        $copyBtn.BackColor = [System.Drawing.Color]::FromArgb(184, 233, 184)
        $deleteBtn.Enabled = $true
        $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(244, 193, 193)
    } else {
        $copyBtn.Enabled = $false
        $copyBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 241, 220)
        $deleteBtn.Enabled = $false
        $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(234, 213, 213)
    }
}

function Set-Folder($path) {
    if (-not [string]::IsNullOrWhiteSpace($path)) {
        $resolved = Resolve-GifFolderPath $path
        try {
            if ($resolved -and -not (Test-Path -LiteralPath $resolved)) {
                New-Item -ItemType Directory -Path $resolved -Force | Out-Null
            }
        } catch {}
        $state.Folder = $resolved
        $folderBox.Text = $resolved
        Save-LastFolder $resolved
    }
}

function Build-ImagesAndList {
    $imageList.Images.Clear()
    $listView.Items.Clear()

    $files = $state.Files

    # Apply filter
    $filter = $state.Filter
    if ($filter) {
        $files = $files | Where-Object { $_.Name -like "*${filter}*" }
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

        $img = $null
        try {
            $img = [System.Drawing.Image]::FromFile($f.FullName)
            $w = $img.Width; $h = $img.Height
            if ($w -le 0 -or $h -le 0 -or $w -gt 8000 -or $h -gt 8000) { throw [System.ArgumentException] "Invalid image dimensions" }
            # Add clone to ImageList (do not dispose clone to avoid ImageList handle issues)
            $bmpClone = New-Object System.Drawing.Bitmap $img
            $imageList.Images.Add($bmpClone) | Out-Null
            $tag.Valid = $true
        } catch {
            $tag.Valid = $false
            # Fallback blank image so the list stays aligned even for invalid/corrupt files
            $bmp = New-Object System.Drawing.Bitmap 128,128
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.Clear([System.Drawing.Color]::LightGray)
            $g.Dispose()
            $imageList.Images.Add($bmp) | Out-Null
        } finally {
            if ($img) { $img.Dispose() }
        }

        $item = New-Object System.Windows.Forms.ListViewItem($f.Name, $index)
        $item.Tag = $tag
        $listView.Items.Add($item) | Out-Null
        $index++
    }

    if ($files.Count -eq 0) {
        Set-Status "No GIFs found in $($state.Folder)"
    } else {
        Set-Status "Showing $($files.Count) GIF(s) from $($state.Folder)"
    }
}

function Load-Files {
    $state.Selection = $null
    $picture.Image = $null
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    if (-not (Test-Path -LiteralPath $state.Folder)) {
        Set-Status "Folder not found: $($state.Folder)"
        return
    }
    $folderBox.Text = $state.Folder
    $state.Files = Get-ChildItem -LiteralPath $state.Folder -Filter '*.gif' -File -ErrorAction SilentlyContinue
    Build-ImagesAndList
    Set-CopyButtonState
}

function Show-Preview($tag) {
    $state.Selection = $null
    $picture.Image = $null
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    $path = $null
    $valid = $true
    if ($tag -is [string]) { $path = $tag }
    elseif ($tag) { $path = $tag.Path; $valid = $tag.Valid }
    if (-not $path) { Set-CopyButtonState; return }
    $state.Selection = $path
    $pathLabel.Text = $path
    if (-not $valid) {
        Set-Status "Cannot preview (invalid image): $([System.IO.Path]::GetFileName($path))"
        Set-CopyButtonState
        return
    }
    try {
        $picture.Load($path)
        Set-Status "Selected: $([System.IO.Path]::GetFileName($path))"
    } catch {
        Set-Status "Failed to preview: $path"
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
    try {
        Remove-Item -LiteralPath $path -Force
        Set-Status "Deleted: $name"
    } catch {
        Set-Status "Failed to delete: $name"
    }
    Load-Files
}

$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select your GIF root folder (a GIFs subfolder will be created/used)'
    $dlg.SelectedPath = $state.Folder
    if ($dlg.ShowDialog() -eq 'OK') {
        Set-Folder $dlg.SelectedPath
        Load-Files
    }
})

$refreshBtn.Add_Click({ Load-Files })
$copyBtn.Add_Click({ Copy-Selection })
$deleteBtn.Add_Click({ Delete-Selection })

$filterBox.Add_TextChanged({
    $state.Filter = $filterBox.Text
    Build-ImagesAndList
})

$sortCombo.Add_SelectedIndexChanged({
    $state.Sort = $sortCombo.SelectedItem
    Build-ImagesAndList
})

$sortDirCombo.Add_SelectedIndexChanged({
    $state.SortDir = $sortDirCombo.SelectedItem
    Build-ImagesAndList
})

$listView.Add_ItemSelectionChanged({
    param($sender,$e)
    if ($e.IsSelected) {
        Show-Preview $e.Item.Tag
    }
})

$listView.Add_DoubleClick({ Copy-Selection })

$form.Add_KeyDown({
    param($sender,$e)
    if ($e.KeyCode -in @('Enter','Space')) { Copy-Selection; $e.Handled = $true; return }
    if ($e.KeyCode -eq 'Delete') { Delete-Selection; $e.Handled = $true; return }
})

Set-Folder $defaultFolder
Load-Files
Set-Status "Use Browse to pick your GIF root; a GIFs subfolder will be created/used automatically."
Set-CopyButtonState

$form.add_FormClosing([System.Windows.Forms.FormClosingEventHandler]{
    param($sender,$e)
    if ($state.Folder) { Save-LastFolder $state.Folder }
})

[void]$form.ShowDialog()
