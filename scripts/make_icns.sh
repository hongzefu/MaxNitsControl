#!/bin/bash
# 由 make_icon.swift 重新生成 Resources/AppIcon.icns
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
swift scripts/make_icon.swift "$TMP/icon.png"
SET="$TMP/AppIcon.iconset"
mkdir "$SET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$SET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d "$TMP/icon.png" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
cp "$TMP/icon.png" Resources/AppIcon.png
rm -rf "$TMP"
echo "已生成 Resources/AppIcon.icns"
