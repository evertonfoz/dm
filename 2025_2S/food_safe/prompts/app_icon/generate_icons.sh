#!/usr/bin/env bash
# Gera ícones Android (mipmap) e iOS (AppIcon.appiconset) a partir de
# assets/images/brand/icon_light.png e icon_dark.png
# Requisitos: ImageMagick (convert, mogrify) e jq (opcional)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BRAND_DIR="$ROOT_DIR/../assets/images/brand"
OUT_DIR="$ROOT_DIR/generated_icons"
LIGHT_ICON="$BRAND_DIR/icon_light.png"
DARK_ICON="$BRAND_DIR/icon_dark.png"

if [ ! -f "$LIGHT_ICON" ]; then
  echo "Arquivo base light não encontrado: $LIGHT_ICON"
  exit 1
fi

if [ ! -f "$DARK_ICON" ]; then
  echo "Aviso: arquivo dark não encontrado: $DARK_ICON"
  echo "Continuando apenas com light"
  USE_DARK=0
else
  USE_DARK=1
fi

mkdir -p "$OUT_DIR/android"
mkdir -p "$OUT_DIR/ios/AppIcon.appiconset"

# Android mipmap sizes (launcher icons)
declare -A ANDROID_SIZES=(
  [mipmap-mdpi]=48
  [mipmap-hdpi]=72
  [mipmap-xhdpi]=96
  [mipmap-xxhdpi]=144
  [mipmap-xxxhdpi]=192
)

echo "Gerando ícones Android em $OUT_DIR/android"
for folder in "${!ANDROID_SIZES[@]}"; do
  size=${ANDROID_SIZES[$folder]}
  mkdir -p "$OUT_DIR/android/$folder"
  convert "$LIGHT_ICON" -resize ${size}x${size} "$OUT_DIR/android/$folder/ic_launcher.png"
  if [ "$USE_DARK" -eq 1 ]; then
    mkdir -p "$OUT_DIR/android/${folder}-night"
    convert "$DARK_ICON" -resize ${size}x${size} "$OUT_DIR/android/${folder}-night/ic_launcher.png"
  fi
done

# iOS sizes list for AppIcon.appiconset (subset common sizes)
iOS_JSON='{
  "images": [],
  "info": {"version":1, "author":"xcode"}
}'

# We'll append entries as we generate files
images_json="[]"

# Sizes and scales per Apple's spec (name used for filenames only)
read -r -d '' IOS_SIZES <<'JSON'
60@2x,60@3x,76@2x,83.5@2x,40@2x,40@3x,1024@1x
JSON

# Helper to add image entry (idiom omitted for brevity)
add_image_entry() {
  local size=$1
  local scale=$2
  local filename=$3
  cat <<EOF
    { "size": "$size", "idiom": "iphone", "filename": "$filename", "scale": "${scale}x" }
EOF
}

# We'll create specific sizes explicitly
# List of (size_in_pt scale filename)
IOS_FILES=(
  "20 2 AppIcon-20@2x.png"
  "20 3 AppIcon-20@3x.png"
  "29 2 AppIcon-29@2x.png"
  "29 3 AppIcon-29@3x.png"
  "40 2 AppIcon-40@2x.png"
  "40 3 AppIcon-40@3x.png"
  "60 2 AppIcon-60@2x.png"
  "60 3 AppIcon-60@3x.png"
  "76 2 AppIcon-76@2x.png"
  "83.5 2 AppIcon-83.5@2x.png"
  "1024 1 AppIcon-1024@1x.png"
)

# Generate images for light
for item in "${IOS_FILES[@]}"; do
  read -r pt scale filename <<<"$item"
  # compute px = pt * scale (note: 83.5 may be float)
  px=$(awk "BEGIN{printf \"%d\", ($pt * $scale)}")
  convert "$LIGHT_ICON" -resize ${px}x${px} "$OUT_DIR/ios/AppIcon.appiconset/$filename"
  # append JSON entry (approximate size string)
  img_entry=$(add_image_entry "$pt x $pt" "$scale" "$filename")
  images_json=$(echo "$images_json" | jq ". + [$img_entry]")
done

# If dark provided, create dark variants by appending `-dark` to filename
if [ "$USE_DARK" -eq 1 ]; then
  for item in "${IOS_FILES[@]}"; do
    read -r pt scale filename <<<"$item"
    px=$(awk "BEGIN{printf \"%d\", ($pt * $scale)}")
    dark_filename="${filename%.png}-dark.png"
    convert "$DARK_ICON" -resize ${px}x${px} "$OUT_DIR/ios/AppIcon.appiconset/$dark_filename"
    img_entry=$(add_image_entry "$pt x $pt" "$scale" "$dark_filename")
    images_json=$(echo "$images_json" | jq ". + [$img_entry]")
  done
fi

# Compose final Contents.json
final_json=$(jq -n --argjson imgs "$images_json" '{images: $imgs, info: {version:1, author: "xcode"}}')
echo "$final_json" > "$OUT_DIR/ios/AppIcon.appiconset/Contents.json"

echo "Geração concluída em $OUT_DIR"

echo "Observação: Para iOS, abra o Xcode e edite o AppIcon asset para adicionar variações de aparência (Dark) apontando para os arquivos *-dark.png gerados." 

exit 0
