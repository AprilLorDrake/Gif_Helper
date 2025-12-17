Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$defaultFolder = Join-Path $env:USERPROFILE "Pictures\GIFs"
$state = [ordered]@{
    Folder = $defaultFolder
    Selection = $null
}

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "GIF Viewer"
$form.Width         = 1000
$form.Height        = 700
$form.StartPosition = 'CenterScreen'
$form.KeyPreview    = $true

$topPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$topPanel.FlowDirection = 'LeftToRight'
$topPanel.WrapContents  = $false
$topPanel.Dock          = 'Top'
$topPanel.Height        = 40
$topPanel.Padding       = '5,5,5,5'
$topPanel.AutoSize      = $false
$topPanel.AutoScroll    = $true

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text      = 'Folder:'
$folderLabel.AutoSize  = $true
$folderLabel.Margin    = '0,10,5,0'

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.ReadOnly = $true
$folderBox.Width    = 500
$folderBox.Margin   = '0,5,5,0'

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text    = 'Browse...'
$browseBtn.Margin  = '0,5,5,0'

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text   = 'Refresh'
$refreshBtn.Margin = '0,5,5,0'

$openBtn = New-Object System.Windows.Forms.Button
$openBtn.Text   = 'Open in Explorer'
$openBtn.Margin = '0,5,5,0'

$copyBtn = New-Object System.Windows.Forms.Button
$copyBtn.Text   = 'Copy path'
$copyBtn.Margin = '0,5,5,0'

$topPanel.Controls.AddRange(@($folderLabel,$folderBox,$browseBtn,$refreshBtn,$openBtn,$copyBtn))

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.SplitterDistance = 320
$split.Panel1MinSize = 200
$split.Panel2MinSize = 300

$list = New-Object System.Windows.Forms.ListBox
$list.Dock = 'Fill'
$list.SelectionMode = 'One'
$list.DisplayMember = 'Name'
$list.HorizontalScrollbar = $true

$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = 'Fill'
$previewPanel.Padding = '5,5,5,5'

$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = 'Fill'
$picture.SizeMode = 'Zoom'
$picture.BorderStyle = 'FixedSingle'

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Dock = 'Bottom'
$pathLabel.AutoSize = $false
$pathLabel.Height = 30
$pathLabel.TextAlign = 'MiddleLeft'

$previewPanel.Controls.Add($picture)
$previewPanel.Controls.Add($pathLabel)
$split.Panel1.Controls.Add($list)
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

function Set-Folder($path) {
    if (-not [string]::IsNullOrWhiteSpace($path)) {
        $state.Folder = $path
        $folderBox.Text = $path
    }
}

function Load-Files {
    $list.Items.Clear()
    $picture.Image = $null
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    if (-not (Test-Path -LiteralPath $state.Folder)) {
        Set-Status "Folder not found: $($state.Folder)"
        return
    }
    $files = Get-ChildItem -LiteralPath $state.Folder -Filter '*.gif' -File -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($f in $files) {
        $list.Items.Add([pscustomobject]@{ Name = $f.Name; FullName = $f.FullName }) | Out-Null
    }
    Set-Status "Loaded $($files.Count) GIF(s) from $($state.Folder)"
}

function Show-Preview($item) {
    $state.Selection = $null
    $picture.Image = $null
    $picture.ImageLocation = $null
    $pathLabel.Text = ''
    if (-not $item) { return }
    $path = $item.FullName
    $state.Selection = $path
    $pathLabel.Text = $path
    try {
        $picture.ImageLocation = $path
        $picture.LoadAsync()
        Set-Status "Selected: $([System.IO.Path]::GetFileName($path))"
    } catch {
        Set-Status "Failed to preview: $path"
    }
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

function Open-Folder {
    if (-not (Test-Path -LiteralPath $state.Folder)) { return }
    Start-Process explorer.exe $state.Folder
}

$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select a GIF folder'
    $dlg.SelectedPath = $state.Folder
    if ($dlg.ShowDialog() -eq 'OK') {
        Set-Folder $dlg.SelectedPath
        Load-Files
    }
})

$refreshBtn.Add_Click({ Load-Files })
$openBtn.Add_Click({ Open-Folder })
$copyBtn.Add_Click({ Copy-Selection })

$list.Add_SelectedIndexChanged({
    $item = $list.SelectedItem
    Show-Preview $item
})

$list.Add_MouseDoubleClick({ Copy-Selection })

$form.Add_KeyDown({
    param($sender,$e)
    if ($e.Control -and $e.KeyCode -eq 'E') { Open-Folder; $e.Handled = $true; return }
    if ($e.KeyCode -in @('Enter','Space')) { Copy-Selection; $e.Handled = $true; return }
})

Set-Folder $defaultFolder
Load-Files

[void]$form.ShowDialog()
