# GIF Helper ✨

📂 Open your GIFs folder instantly, 🖼️ preview with full animations and manage with quick filter/sort/delete, and 📋 1-click to copy the full GIF file path for quick pasting into file pickers.

## Gifs got you Down?
If Explorer won’t animate your GIF previews (or OneDrive keeps “helpfully” locking them), this tiny helper gives you an Explorer-like browser with **reliable animated previews**, plus **search/sort/copy path/delete**.

Repo: https://github.com/AprilLorDrake/Gif_Helper

## Why you’ll like it
- ⚡ One-click open of a GIF folder you choose
- 🖥️ Built-in GIF viewer with animated previews plus search, sorting, copy path, and delete
- 📋 Clipboard-friendly: folder path and file paths ready to paste
- 🎯 Desktop shortcut + hotkey support (Windows)
- 🍎 Handy macOS helper for Finder + Quick Look

## What’s inside
- `tools/open_gif_folder.ps1` / `.bat` — prompt for a folder, ensure it exists, copy its path, open Explorer.
- `tools/gif_viewer.ps1` / `.bat` — WinForms GIF browser with navigation pane: browse, preview, search, sort, copy path, delete; use any folder you like (no special `GIFs` handling).
- `tools/create_shortcut.ps1` — makes a desktop shortcut (with hotkey) pointing at the viewer; uses the bundled icon.
- `tools/install_gif_preview.ps1` — jumps to IrfanView + Plugins download pages to improve Explorer thumbnail/preview support (animation still depends on Explorer).
- `tools/open_gif_folder_macos.sh` + `tools/create_shortcut_macos.sh` — Finder helper + desktop shortcut on macOS.
- `resources/icon.png` — app/shortcut icon used by the viewer window and generated shortcut.

## Quick start (Windows)
1) Double-click `tools/open_gif_folder.bat`.
2) Press **Enter** to accept `%USERPROFILE%\Pictures` or type another folder.
3) Explorer opens there. **Alt+P** toggles the Preview pane (it may be static on some systems).
4) Paste the folder path (already on your clipboard) into any file picker’s address bar, then pick your GIF.

For guaranteed animated previews, launch the built-in viewer: double-click `tools/gif_viewer.bat`.

## GIF Viewer (Windows)
- Launch: double-click `tools/gif_viewer.bat` (or use the desktop shortcut below).
- Navigate: use the left folder tree (Explorer-style) to pick any folder (no special subfolder rules).
- Preview: full animations in the right pane (not just thumbnails).
- Search: type in the Search box (case-insensitive).
- Sort: choose Name/Date Modified, toggle ▲/▼ for direction.
- Copy path: 1-click **Copy path** (or double-click/Enter/Space) to grab the full GIF file path.
- Delete: select a GIF, hit **Delete** or press the Delete key.
- Keyboard: Enter/Space = copy; Delete = delete.

### Desktop shortcut + hotkey (Windows)
```powershell
cd C:\Projects\Gif_Helper
powershell -ExecutionPolicy Bypass -File tools\create_shortcut.ps1
```
By default: targets `tools\gif_viewer.bat`, sets icon + hotkey **Ctrl+Alt+G**. Customize:
```powershell
powershell -ExecutionPolicy Bypass -File tools\create_shortcut.ps1 -Target "D:\\Media\\Gif_Helper\\tools\\gif_viewer.bat" -Hotkey "Ctrl+Shift+G"
```

PowerShell notes:
- Windows ships with Windows PowerShell already installed. If you need the newer PowerShell (pwsh), install from Microsoft Store or: `winget install --id Microsoft.PowerShell --source winget`.
- These scripts don’t require admin; the commands above use `-ExecutionPolicy Bypass` to run just this script. If your policy is stricter, you can launch PowerShell as Administrator and rerun.

## macOS helper
- Run: `chmod +x tools/open_gif_folder_macos.sh` then `./tools/open_gif_folder_macos.sh` (or pass a base folder).
- It ensures `~/Pictures/GIFs`, copies the path, and opens Finder. Press **Space** on a GIF for Quick Look animation.
- Desktop shortcut: `chmod +x tools/create_shortcut_macos.sh` then `./tools/create_shortcut_macos.sh` to drop “GIF Helper.command” on Desktop.

## Screenshots (coming soon)
- Viewer browsing/searching/sorting: _placeholder_ ← share a filename (PNG/JPG) and I’ll embed it.
- Explorer + preview pane flow: _placeholder_ ← share a filename and I’ll embed it.

## Tips & troubleshooting
- OneDrive paths: the viewer now prefers OneDrive Pictures when present. You can browse to any folder (local or OneDrive). To reset the remembered folder, run `tools/reset_viewer_defaults.ps1` (or delete `%APPDATA%\Gif_Helper\gif_viewer.lastpath`) and relaunch.
- Delete on OneDrive: sometimes Windows reports “used by another process” due to OneDrive/Explorer sync or preview. The viewer avoids locking files and will try a Recycle Bin delete fallback when possible.
- Explorer previews: **Alt+P** toggles the Preview pane, but Explorer often won’t animate GIFs. GIF Helper’s viewer animates GIFs reliably.
  - If you want to improve Explorer thumbnail/preview handling, run `tools/install_gif_preview.ps1`, then reopen Explorer (animation is still not guaranteed).
- WebP/AVIF: install Microsoft Store extensions (WebP Image Extensions; AV1/HEIF/HEVC for AVIF playback).
- If file delete fails, ensure the GIF isn’t open elsewhere; the viewer releases the image before deleting.

## Release notes
- Latest: Bundled custom icon (viewer + shortcuts); Delete button; safer thumbnail loading for tricky GIFs.

## Follow the GIFs
I post my LinkedIn GIFs here: https://giphy.com/channel/aprildrake

## Publish to GitHub (via GitHub Desktop)
1. GitHub Desktop → **File → Add local repository** → choose `C:\Projects\Gif_Helper`.
2. **Create repository** (public), choose a name, and publish to GitHub.
3. Commit the files (README, tools scripts, etc.) and click **Publish repository**.

## Optional: command-line
- `open_gif_folder.bat "D:\\Media"` prompts with `D:\\Media` and opens it.
- `gif_viewer.bat` launches the viewer; Browse to pick a folder, click a GIF to animate, Copy path to grab the full file path.
