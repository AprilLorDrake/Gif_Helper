# GIF Helper (Windows + macOS)

A small, practical helper to **organize, preview, and quickly select animated GIFs** for uploads (LinkedIn, GitHub, Slack, etc.).  
It creates and opens a dedicated `GIFs` folder, copies the folder path to your clipboard, and lets you preview animations **before** you upload.

This tool is about **speed and clarity**, not editing or generating GIFs.

---

## What this tool does (and does not)

**It does:**
- Create (if needed) and open a predictable `GIFs` folder
- Copy the folder path to your clipboard
- Let you preview animations locally (Explorer, Finder, or built‑in viewer)
- Make drag‑and‑drop or file‑picker uploads fast and reliable

**It does NOT:**
- Create or edit GIFs
- Upload files automatically
- Bypass browser upload limitations

---

## Quick start (Windows)

1. Double‑click:
   ```text
   tools/open_gif_folder.bat
   ```
2. Press **Enter** to use `%USERPROFILE%\Pictures`, or type a custom base folder.
   - A `GIFs` subfolder will be created or reused.
3. Explorer opens to that folder.
4. Press **Alt + P** to enable the Preview pane so GIFs animate.
5. The folder path is already on your clipboard.
   - Paste it into a browser file picker or drag a GIF directly.

### Optional: built‑in GIF viewer
Run:
```text
tools/gif_viewer.bat
```

This opens a desktop GIF browser with:
- Animated previews
- Sorting and filtering
- Copy‑path button
- Delete support for cleanup

---

## Quick start (macOS)

Finder and Quick Look handle animated GIFs natively.

```bash
cd ~/Projects/Gif_Helper
chmod +x tools/open_gif_folder_macos.sh
./tools/open_gif_folder_macos.sh
```

**What happens:**
- Creates or reuses `~/Pictures/GIFs` (or your supplied base)
- Opens the folder in Finder
- Copies the folder path to your clipboard

Preview any GIF with **Space** (Quick Look), then drag it into the browser or paste the folder path.

---

## Files

### Core helpers
- `tools/open_gif_folder.ps1`  
  Prompts for a base folder, creates/opens `GIFs`, copies path, opens Explorer.
- `tools/open_gif_folder.bat`  
  Double‑click wrapper for the PowerShell helper.
- `tools/open_gif_folder_macos.sh`  
  macOS helper: create/open `GIFs`, copy path, open Finder.

### Preview & cleanup
- `tools/gif_viewer.ps1`  
  WinForms desktop GIF browser with animation preview, copy path, and delete.
- `tools/gif_viewer.bat`  
  Double‑click wrapper for the GIF viewer.

### Setup helpers
- `tools/install_gif_preview.ps1`  
  Opens IrfanView + Plugins pages to add a reliable animated preview handler on Windows.
- `tools/create_shortcut.ps1`  
  Creates a Desktop shortcut for the GIF viewer (Windows).
- `tools/create_shortcut_macos.sh`  
  Creates a Desktop shortcut for the macOS helper.

---

## Notes & tips

- Browser upload dialogs usually **do not animate GIFs**. This is expected.
- On Windows, animation preview works best in Explorer’s Preview pane (**Alt + P**).
- On macOS, Finder + Quick Look animate GIFs by default.
- If Explorer previews stay static:
  1. Run `tools/install_gif_preview.ps1`
  2. Restart Explorer
  3. Press **Alt + P**
- You can always fall back to `gif_viewer.bat` to preview animations and copy paths.

---

## Desktop shortcut (Windows)

Create a Desktop shortcut to the GIF viewer:

```powershell
cd C:\Projects\Gif_Helper
powershell -ExecutionPolicy Bypass -File tools\create_shortcut.ps1
```

Customize target or hotkey:
```powershell
powershell -ExecutionPolicy Bypass -File tools\create_shortcut.ps1 `
  -Target "D:\Media\Gif_Helper\tools\gif_viewer.bat" `
  -Hotkey "Ctrl+Shift+G"
```

---

## Desktop shortcut (macOS)

```bash
cd ~/Projects/Gif_Helper
chmod +x tools/create_shortcut_macos.sh
./tools/create_shortcut_macos.sh
```

Creates a **GIF Helper.command** file on your Desktop.

---

## Release notes

- Latest:
  - Added Delete button and Delete‑key shortcut to the GIF viewer
  - Safer thumbnail loading for problematic GIFs

---

## Follow the GIFs

Weird LinkedIn GIFs live here:  
https://giphy.com/channel/aprildrake/weirdlinkedin

---

## Publish to GitHub (GitHub Desktop)

1. GitHub Desktop → **File → Add local repository**
2. Choose your `Gif_Helper` folder
3. Create and publish the repository
4. Commit README and tools

---

## Optional: command‑line examples

- Open GIF folder at a custom location:
  ```bat
  open_gif_folder.bat "D:\Media"
  ```
- Launch the animated GIF viewer:
  ```bat
  gif_viewer.bat
  ```
