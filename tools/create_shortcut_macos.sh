#!/usr/bin/env bash
set -euo pipefail

# Creates a desktop shortcut (.command) to run the macOS GIF folder helper.
# Usage: ./tools/create_shortcut_macos.sh

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
helper="$repo_dir/tools/open_gif_folder_macos.sh"
shortcut="$HOME/Desktop/GIF Helper.command"

cat > "$shortcut" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
"$REPO_DIR/tools/open_gif_folder_macos.sh" "$@"
EOF

# Replace placeholder paths
perl -pi -e "s|REPO_DIR=\"\$SCRIPT_DIR/\.\.\"|REPO_DIR=\"$repo_dir\"|" "$shortcut"

chmod +x "$shortcut"

osascript -e 'display notification "GIF Helper shortcut created on Desktop" with title "GIF Helper"'

echo "Shortcut created: $shortcut"
echo "Double-click it to open/create your GIFs folder and copy its path."
