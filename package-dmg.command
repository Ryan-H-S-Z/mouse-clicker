#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/mouse-clicker-dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/volume" dist
./build.command "$STAGING/volume/鼠标连点器.app"
ln -s /Applications "$STAGING/volume/Applications"
cp INSTALL.txt "$STAGING/volume/安装说明.txt"
cp INSTALL.en.txt "$STAGING/volume/Installation.txt"
hdiutil create -volname "鼠标连点器 $VERSION" -srcfolder "$STAGING/volume" -format UDZO -ov "$STAGING/MouseClicker-$VERSION-universal.dmg"
hdiutil verify "$STAGING/MouseClicker-$VERSION-universal.dmg"
cp "$STAGING/MouseClicker-$VERSION-universal.dmg" dist/
cd dist
shasum -a 256 "MouseClicker-$VERSION-universal.dmg" > SHA256SUMS.txt
echo "已生成：$PWD/MouseClicker-$VERSION-universal.dmg"
