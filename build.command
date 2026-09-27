#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="${1:-$HOME/Applications/鼠标连点器.app}"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mouse-clicker-build.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
mkdir -p "$APP/Contents/MacOS"
for ARCH in arm64 x86_64; do
  xcrun swiftc -swift-version 5 -O -target "$ARCH-apple-macosx13.0" main.swift -o "$BUILD_DIR/MouseClicker-$ARCH" -framework AppKit -framework SwiftUI -framework Carbon -framework ApplicationServices
done
xcrun lipo -create "$BUILD_DIR/MouseClicker-arm64" "$BUILD_DIR/MouseClicker-x86_64" -output "$APP/Contents/MacOS/MouseClicker"
cp Info.plist "$APP/Contents/Info.plist"
xattr -cr "$APP"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "已生成：$APP"
