#!/usr/bin/env bash
set -euo pipefail

# macOS helper: resolve/create GIFs folder, copy path, open Finder
# Usage: ./open_gif_folder_macos.sh [base_folder]

base="${1:-$HOME/Pictures}"

trim() { printf '%s' "$1" | sed 's/[[:space:]]*$//'; }
base="$(trim "$base")"

# Resolve GIF folder
leaf="${base##*/}"
if [[ "$leaf" =~ ^(gif|gifs|GIFS|GIF)$ ]]; then
  gif_folder="$base"
elif [[ -d "$base/gifs" ]]; then
  gif_folder="$base/gifs"
elif [[ -d "$base/GIFs" ]]; then
  gif_folder="$base/GIFs"
else
  gif_folder="$base/GIFs"
fi

mkdir -p "$gif_folder"

# Copy path to clipboard (best effort)
if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$gif_folder" | pbcopy || true
fi

# Open Finder
open "$gif_folder"

printf "GIF folder: %s\n" "$gif_folder"
printf "Hint: In Finder, press Space to Quick Look and animate GIFs.\n"
