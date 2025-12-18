#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
open_gif_folder.sh
Creates/opens your GIF folder and prints the resolved path.

Usage:
  ./open_gif_folder.sh
  ./open_gif_folder.sh "/path/to/base"
  ./open_gif_folder.sh --help

Behavior:
  - If base folder name is gif/gifs, uses it directly
  - Else uses existing child folder GIF/GIFs if present
  - Else uses <base>/GIFs

macOS:
  - Opens in Finder (open)
  - Copies path to clipboard (pbcopy)
EOF
}

arg="${1:-}"
if [[ "$arg" == "-h" || "$arg" == "--help" || "$arg" == "/?" ]]; then
  show_help
  exit 0
fi

# Pick a default base folder
if [[ -z "$arg" ]]; then
  if [[ -d "${HOME}/Pictures" ]]; then
    base="${HOME}/Pictures"
  else
    base="${HOME}"
  fi
else
  base="$arg"
fi

# Normalize: trim trailing slashes (but keep "/" intact)
if [[ "$base" != "/" ]]; then
  base="${base%/}"
fi

leaf="$(basename "$base" | tr '[:upper:]' '[:lower:]')"

# Choose GIF folder intelligently
if [[ "$leaf" == "gif" || "$leaf" == "gifs" ]]; then
  gifdir="$base"
else
  if [[ -d "$base/GIFs" ]]; then gifdir="$base/GIFs"
  elif [[ -d "$base/gifs" ]]; then gifdir="$base/gifs"
  elif [[ -d "$base/GIF"  ]]; then gifdir="$base/GIF"
  elif [[ -d "$base/gif"  ]]; then gifdir="$base/gif"
  else gifdir="$base/GIFs"
  fi
fi

# Create folder if needed (safe)
mkdir -p "$gifdir"

# Always show what we resolved (helps debugging)
echo "GIF folder: $gifdir"

# Open folder in Finder
if command -v open >/dev/null 2>&1; then
  open "$gifdir"
else
  echo "Error: 'open' not found. This script expects macOS." >&2
  exit 1
fi

# Copy folder path to clipboard (include newline for cleaner terminal UX)
if command -v /usr/bin/pbcopy >/dev/null 2>&1; then
  printf "%s\n" "$gifdir" | /usr/bin/pbcopy
  echo "Copied to clipboard."
else
  echo "Error: '/usr/bin/pbcopy' not found. Clipboard copy failed." >&2
  exit 1
fi