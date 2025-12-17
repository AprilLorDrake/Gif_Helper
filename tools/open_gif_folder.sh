#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
open_gif_folder.sh
Creates/opens your GIF folder and prints the resolved path.

Usage:
  ./open_gif_folder.sh
  ./open_gif_folder.sh "/path/to/base"

Behavior:
  - If base folder name is gif/gifs, uses it directly
  - Else uses existing child folder GIF/GIFs if present
  - Else uses <base>/GIFs

On macOS:
  - Opens in Finder
  - Copies path to clipboard (pbcopy)
EOF
}

arg="${1:-}"
if [[ "${arg}" == "-h" || "${arg}" == "--help" ]]; then
  show_help
  exit 0
fi

# Default base folder
if [[ -z "${arg}" ]]; then
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    base="${HOME}/Pictures"
  else
    base="${HOME}"
  fi
else
  base="${arg}"
fi

# Normalize: trim trailing slashes
base="${base%/}"

leaf="$(basename "$base" | tr '[:upper:]' '[:lower:]')"
if [[ "$leaf" == "gif" || "$leaf" == "gifs" ]]; then
  gifdir="$base"
else
  if [[ -d "$base/GIFs" ]]; then gifdir="$base/GIFs"
  elif [[ -d "$base/gifs" ]]; then gifdir="$base/gifs"
  elif [[ -d "$base/GIF" ]]; then gifdir="$base/GIF"
  elif [[ -d "$base/gif" ]]; then gifdir="$base/gif"
  else gifdir="$base/GIFs"
  fi
fi

mkdir -p "$gifdir"

if [[ "${OSTYPE:-}" == darwin* ]]; then
  open "$gifdir"
  printf "%s" "$gifdir" | pbcopy || true
  echo "GIF folder: $gifdir (copied to clipboard)"
else
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$gifdir" >/dev/null 2>&1 || true
  fi
  echo "GIF folder: $gifdir"
fi