# GIF Helper (Windows)

A tiny helper to open File Explorer at a GIFs folder (creating it if needed), copy the folder path to your clipboard, and let you quickly pick animated GIFs in upload dialogs (e.g., LinkedIn). On Windows 11, use the Explorer **Preview pane** (Alt+P) to see GIFs animate; the browser upload dialog itself stays static.

## Quick start
1. Run `tools/open_gif_folder.bat` (double-click).  
2. When prompted, press Enter to use `%USERPROFILE%\Pictures` or enter any base folder. The script will create/ensure a `GIFs` subfolder there.  
3. Explorer opens to that folder. Press **Alt+P** to show the Preview pane so GIFs animate.  
4. The folder path is already on your clipboard—paste it into the file picker’s address bar (e.g., LinkedIn) and select your GIF. The picker’s thumbnail will be static, but you’ve already verified the animation in Explorer.

## Files
- `tools/open_gif_folder.ps1` — prompts for a base folder, creates `GIFs`, copies the path, opens Explorer.
- `tools/open_gif_folder.bat` — double-click-friendly wrapper around the PowerShell script.
- `tools/install_gif_preview.ps1` — opens IrfanView + Plugins download pages to add a reliable animated GIF preview handler for Explorer.

## Notes
- GIF animation preview works in Explorer’s Preview pane, not in the browser’s Open dialog.  
- For WebP/AVIF animation, install the Microsoft Store extensions (WebP Image Extensions; AV1/HEIF/HEVC for AVIF).
- If GIFs don’t animate in Explorer’s Preview pane on your machine, run `tools/install_gif_preview.ps1` to install IrfanView (64-bit) and the Plugins pack, then reopen Explorer and press Alt+P.

## Publish to GitHub (via GitHub Desktop)
1. Open GitHub Desktop → **File → Add local repository** → choose `C:\Projects\Gif_Helper`.  
2. **Create repository** (public), choose a name, and publish to GitHub.  
3. Commit the files (README, tools scripts, etc.) and click **Publish repository**.

## Optional: command-line
- `open_gif_folder.bat "D:\Media"` will prompt with `D:\Media` as the base, then create/use `D:\Media\GIFs`.
