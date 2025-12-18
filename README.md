# GIF Helper (Windows + macOS)

A tiny helper to open **File Explorer or Finder** at a dedicated `GIFs` folder (creating it if needed), copy the folder path to your clipboard, and let you quickly **drag, drop, or select animated GIFs** in upload dialogs (e.g., LinkedIn).

- On **Windows 11**, use the Explorer **Preview pane** (`Alt + P`) to see GIFs animate. Browser upload dialogs themselves stay static.
- On **macOS**, Finder and Quick Look show animated GIFs natively. No extra setup required.

---

## What this tool is (and is not)

**This tool does:**
- Create a predictable `GIFs` folder
- Open that folder immediately
- Copy the folder path to your clipboard

**This tool does NOT:**
- Create or edit GIFs
- Upload files automatically
- Copy GIF files themselves

Its job is **fast navigation**, not file manipulation.

---

## Quick start (Windows)

1. Run `tools/open_gif_folder.bat` (double-click).
2. When prompted, press Enter to use `%USERPROFILE%\Pictures` or enter any base folder.
   - The script will create or reuse a `GIFs` subfolder there.
3. Explorer opens to that folder.
4. Press **Alt + P** to enable the Preview pane so GIFs animate.
5. The folder path is already on your clipboard.
   - Paste it into a browser file picker’s address bar (e.g., LinkedIn) or drag a GIF directly.

---

## Quick start (macOS)

1. Open **Terminal** in the repo root.
2. Make the script executable (one time):
   ```bash
   chmod +x tools/open_gif_folder.sh
   ```
3. Run the helper:
   ```bash
   ./tools/open_gif_folder.sh
   ```
   Or specify a base folder:
   ```bash
   ./tools/open_gif_folder.sh ~/Pictures
   ```

### What you should see on macOS
- A folder opens in **Finder** (default: `~/Pictures/GIFs`)
- Animated GIFs preview normally
- The folder path is copied to your clipboard

### Quick clipboard check (optional)
Paste anywhere with **Cmd + V**, or in Terminal:
```bash
pbpaste
```

---

## How you actually use this with LinkedIn (or any site)

1. Run the helper
2. Finder / Explorer opens to your GIFs
3. Pick the GIF you want (preview animation first)
4. Upload by either:
   - Dragging the GIF into the browser
   - Pasting the folder path into the file picker and clicking the file

---

## Files

- `tools/open_gif_folder.ps1`  
  PowerShell helper with prompts, clipboard copy, and Explorer launch.

- `tools/open_gif_folder.bat`  
  Double-click friendly Windows wrapper.

- `tools/open_gif_folder.sh`  
  macOS shell helper that opens Finder and copies the folder path.

- `tools/enable_preview_and_thumbnails.ps1`  
  Windows helper to enable Explorer thumbnails and Preview pane.

- `tools/install_gif_preview.ps1`  
  Opens IrfanView + Plugins pages to add a reliable GIF preview handler on Windows.

---

## Notes

- Browser upload dialogs generally **do not animate GIF previews**. This is expected.
- Windows users must use Explorer’s Preview pane (`Alt + P`) to see animation.
- macOS users get animated previews by default.
- If GIFs do not animate in Explorer:
  1. Run `enable_preview_and_thumbnails.ps1`
  2. Run `install_gif_preview.ps1`
  3. Restart Explorer and press `Alt + P`

---

## Optional: command-line usage

- Windows (BAT):
  ```bat
  open_gif_folder.bat "D:\Media"
  ```

- Windows (PowerShell):
  ```powershell
  .\tools\open_gif_folder.ps1 -BaseFolder "D:\Media" -NonInteractive
  ```

- macOS:
  ```bash
  ./tools/open_gif_folder.sh "/Volumes/Media"
  ```

---

## Publish to GitHub (via GitHub Desktop)

1. Open GitHub Desktop → **File → Add local repository**
2. Create the repository and publish
3. Commit files and push
