# GIF Helper (Windows + macOS)

A tiny helper to open File Explorer or Finder at a GIFs folder (creating it if needed), copy the folder path to your clipboard, and let you quickly pick animated GIFs in upload dialogs (e.g., LinkedIn).  

On **Windows 11**, use the Explorer **Preview pane** (Alt+P) to see GIFs animate; the browser upload dialog itself stays static.  
On **macOS**, Finder and Quick Look handle animated GIFs natively.

---

## Quick start (Windows)
1. Run `tools/open_gif_folder.bat` (double-click).  
2. When prompted, press Enter to use `%USERPROFILE%\Pictures` or enter any base folder. The script will create/ensure a `GIFs` subfolder there.  
3. Explorer opens to that folder. Press **Alt+P** to show the Preview pane so GIFs animate.  
4. The folder path is already on your clipboard. Paste it into the file picker’s address bar (e.g., LinkedIn) and select your GIF.

---

## Quick start (macOS)
1. Open Terminal in the repo root.  
2. Make the script executable (one time):
   ```bash
   chmod +x tools/open_gif_folder.sh
   ```
3. Run:
   ```bash
   ./tools/open_gif_folder.sh
   ```
   or specify a base folder:
   ```bash
   ./tools/open_gif_folder.sh ~/Pictures
   ```

---

## Files
- `tools/open_gif_folder.ps1` — PowerShell helper with prompts and clipboard support  
- `tools/open_gif_folder.bat` — Double-click friendly Windows wrapper  
- `tools/open_gif_folder.sh` — macOS/Linux shell helper  
- `tools/enable_preview_and_thumbnails.ps1` — Enables Explorer previews  
- `tools/install_gif_preview.ps1` — Opens IrfanView + Plugins download pages

---

## Notes
- GIF animation preview works in Explorer’s Preview pane, not browser upload dialogs  
- macOS supports animated GIFs natively  
- If GIFs do not animate on Windows, run:
  1. `enable_preview_and_thumbnails.ps1`
  2. `install_gif_preview.ps1`
  3. Restart Explorer and press Alt+P

---

## Optional: command-line usage
- Windows:
  ```bat
  open_gif_folder.bat "D:\Media"
  ```
- PowerShell:
  ```powershell
  .\tools\open_gif_folder.ps1 -BaseFolder "D:\Media" -NonInteractive
  ```
- macOS:
  ```bash
  ./tools/open_gif_folder.sh "/Volumes/Media"
  ```

---

## Publish to GitHub (via GitHub Desktop)
1. Open GitHub Desktop → File → Add local repository  
2. Create repository and publish  
3. Commit files and push
