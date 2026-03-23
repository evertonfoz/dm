#!/usr/bin/env bash
# Merge two AppIcon.appiconset directories (light and dark) into a single AppIcon.appiconset
# Usage: merge_appiconsets.sh <light_appiconset_dir> <dark_appiconset_dir> <out_dir>

set -euo pipefail

LIGHT_DIR="${1:-}"
DARK_DIR="${2:-}"
OUT_DIR="${3:-}"

if [ -z "$LIGHT_DIR" ] || [ -z "$DARK_DIR" ] || [ -z "$OUT_DIR" ]; then
  echo "Uso: $0 <light_appiconset_dir> <dark_appiconset_dir> <out_dir>"
  exit 2
fi

if [ ! -d "$LIGHT_DIR" ]; then
  echo "Light dir not found: $LIGHT_DIR"
  exit 1
fi
if [ ! -d "$DARK_DIR" ]; then
  echo "Dark dir not found: $DARK_DIR"
  exit 1
fi

mkdir -p "$OUT_DIR"

# Copy all files from light to out
rsync -a --exclude 'Contents.json' "$LIGHT_DIR/" "$OUT_DIR/"

# Copy dark files with suffix -dark before extension if filename differs
for f in "$DARK_DIR"/*.png; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  # If exact same filename exists in light, write a -dark sibling; otherwise copy normally
  if [ -f "$OUT_DIR/$base" ]; then
    name="${base%.png}-dark.png"
    cp "$f" "$OUT_DIR/$name"
  else
    cp "$f" "$OUT_DIR/$base"
  fi
done

# Build Contents.json by merging image entries
if command -v jq >/dev/null 2>&1; then
  light_json=$(jq '.images' "$LIGHT_DIR/Contents.json")
  dark_json=$(jq '.images' "$DARK_DIR/Contents.json")

  # For each dark entry, try to map to the light one and set appearance
  merged=$(jq -n '{images: [], info: {version:1, author:"xcode"}}')

  # Add light images
  merged=$(echo "$merged" | jq --argjson imgs "$light_json" '.images = $imgs')

  # For each dark image create an entry with filename suffixed by -dark.png and appearance dark
  idx=0
  echo "$dark_json" | jq -c '.[]' | while read -r item; do
    filename=$(echo "$item" | jq -r '.filename')
    # compute dark filename
    if [[ "$filename" == *.png ]]; then
      dark_filename="${filename%.png}-dark.png"
    else
      dark_filename="$filename"
    fi
    # create a new object with appearance
    new_item=$(echo "$item" | jq --arg df "$dark_filename" '. + {filename: $df, appearances: [{appearance: "luminosity", value: "dark"}] }')
    # append to merged.images
    merged=$(echo "$merged" | jq --argjson it "$new_item" '.images += [$it]')
  done

  echo "$merged" > "$OUT_DIR/Contents.json"
  echo "Merged Contents.json written to $OUT_DIR/Contents.json"
else
  echo "jq not found; copying light Contents.json and leaving dark files suffixed with -dark.png"
  cp "$LIGHT_DIR/Contents.json" "$OUT_DIR/Contents.json"
fi

echo "Merge complete: $OUT_DIR"

exit 0
