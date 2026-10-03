#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source scripts/macos_sdk.sh
buffer_arch="$(uname -m)"
buffer_app="$PWD/build/local/Buffer.app"
mkdir -p "$buffer_app/Contents/MacOS" "$buffer_app/Contents/Resources"
echo "Building Buffer for $buffer_arch using $buffer_sdk"
swiftc -sdk "$buffer_sdk" -target "$buffer_arch-apple-macosx13.0" -swift-version 5 \
    -parse-as-library -framework Cocoa -framework SwiftUI -framework Carbon \
    BufferApp.swift AppDelegate.swift Models/*.swift Services/*.swift Views/*.swift \
    -o "$buffer_app/Contents/MacOS/Buffer"
cp Info.plist "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Buffer' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.samirpatil.Buffer' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Buffer' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile AppIcon' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :LSMinimumSystemVersion 13.0' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString 3.0.2' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion 9002' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Buffer 开发版' "$buffer_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :BufferLocalDevelopment bool true' "$buffer_app/Contents/Info.plist"
cp -R Resources/*.lproj "$buffer_app/Contents/Resources/"
mkdir -p build/local/AppIcon.iconset
cp Assets.xcassets/AppIcon.appiconset/*.png build/local/AppIcon.iconset/
iconutil -c icns build/local/AppIcon.iconset -o "$buffer_app/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$buffer_app/Contents/PkgInfo"
xattr -cr "$buffer_app"
codesign --force --sign - "$buffer_app"
codesign --verify --deep --strict "$buffer_app"
echo "Built: $buffer_app"
if [[ "${1:-}" == --install ]]; then
    # Fail rather than replace a running app or another installed copy without inspection.
    if pgrep -x Buffer >/dev/null || [[ -e /Applications/Buffer.app ]]; then
        echo 'Quit and remove the previous installed copy before using --install.' >&2
        exit 1
    fi
    ditto --norsrc --noextattr "$buffer_app" /Applications/Buffer.app
    xattr -cr /Applications/Buffer.app
    codesign --verify --deep --strict /Applications/Buffer.app
    open /Applications/Buffer.app
    echo 'Installed and launched /Applications/Buffer.app'
fi
