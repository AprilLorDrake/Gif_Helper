# GIF Helper (Windows)

A tiny helper to manage your GIFs folder (creating it if needed), copy the folder path to your clipboard, and quickly pick animated GIFs in upload dialogs (e.g., LinkedIn). For animation, use the built-in GIF viewer; Explorer’s Preview pane (Alt+P) is optional if you prefer Explorer.

## Quick start
1. Run `tools/open_gif_folder.bat` (double-click).  
2. When prompted, press Enter to use `%USERPROFILE%\Pictures` or enter any base folder. The script will create/ensure a `GIFs` subfolder there.  
3. Explorer opens to that folder. Press **Alt+P** to show the Preview pane so GIFs animate.  
4. The folder path is already on your clipboard—paste it into the file picker’s address bar (e.g., LinkedIn) and select your GIF. The picker’s thumbnail will be static, but you’ve already verified the animation in Explorer.
5. (Optional) Run `tools/gif_viewer.bat` to browse and preview GIFs with the built-in viewer (supports filtering, sorting, copy path, and delete).

## Files
- `tools/open_gif_folder.ps1` — prompts for a base folder, creates `GIFs`, copies the path, opens Explorer.
- `tools/open_gif_folder.bat` — double-click-friendly wrapper around the PowerShell script.
- `tools/install_gif_preview.ps1` — opens IrfanView + Plugins download pages to add a reliable animated GIF preview handler for Explorer.
- `tools/gif_viewer.ps1` — WinForms desktop GIF browser: browse folders, preview animated GIFs, copy file paths, delete unwanted GIFs. Pick your base folder and it will use/create a `GIFs` subfolder automatically.
- `tools/gif_viewer.bat` — double-click wrapper for `gif_viewer.ps1`.
- `tools/create_shortcut.ps1` — create a desktop shortcut to launch the GIF viewer (Windows only).

## Notes
- GIF animation preview works in Explorer’s Preview pane, not in the browser’s Open dialog.  
- For WebP/AVIF animation, install the Microsoft Store extensions (WebP Image Extensions; AV1/HEIF/HEVC for AVIF).
- If GIFs don’t animate in Explorer’s Preview pane on your machine, run `tools/install_gif_preview.ps1` to install IrfanView (64-bit) and the Plugins pack, then reopen Explorer and press Alt+P.
- If Explorer previews stay static, you can still browse and preview animations via `tools/gif_viewer.ps1` (or the .bat wrapper); click a GIF to animate, use “Copy path” to paste into file pickers, or Delete to clean up. When browsing, select your root folder; the viewer will create/use a `GIFs` subfolder automatically.

## Desktop shortcut (Windows)
Run this once to add a desktop shortcut for the viewer:

```powershell
cd C:\Projects\Gif_Helper
powershell -ExecutionPolicy Bypass -File tools\create_shortcut.ps1
```

The shortcut targets `tools\gif_viewer.bat`. Adjust the path if you installed the repo elsewhere.

## Release notes
- Latest: Added a Delete button (and Delete-key shortcut) to the GIF viewer, plus safer thumbnail loading for problematic GIFs.

## Follow the GIFs
I post these weird LinkedIn GIFs here: https://giphy.com/channel/aprildrake/weirdlinkedin

## Publish to GitHub (via GitHub Desktop)
1. Open GitHub Desktop → **File → Add local repository** → choose `C:\Projects\Gif_Helper`.  
2. **Create repository** (public), choose a name, and publish to GitHub.  
3. Commit the files (README, tools scripts, etc.) and click **Publish repository**.

## Optional: command-line
- `open_gif_folder.bat "D:\Media"` will prompt with `D:\Media` as the base, then create/use `D:\Media\GIFs`.
- `gif_viewer.bat` opens the animated GIF browser; use Browse to pick a folder, click a GIF to animate, and “Copy path” to put the full file path on your clipboard.
