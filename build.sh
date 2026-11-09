#!/bin/bash
# 构建 dist/MaxNitsControl.app（需要 Xcode Command Line Tools）
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP="dist/MaxNitsControl.app"
rm -rf dist
mkdir -p "$APP/Contents/MacOS"
cp .build/release/MaxNitsControl "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "已生成 $APP"

# ./build.sh install：安装到 /Applications
if [ "${1:-}" = "install" ]; then
  rm -rf "/Applications/MaxNitsControl.app"
  cp -R "$APP" /Applications/
  echo "已安装到 /Applications/MaxNitsControl.app"
fi
