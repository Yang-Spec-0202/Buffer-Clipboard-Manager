#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/macos_sdk.sh
mkdir -p build/tests
buffer_arch="$(uname -m)"
swiftc -sdk "$buffer_sdk" -target "$buffer_arch-apple-macosx13.0" -swift-version 5 \
    -parse-as-library -framework Cocoa -framework SwiftUI -framework Carbon \
    -emit-library -emit-module -enable-testing -module-name Buffer \
    AppDelegate.swift Models/*.swift Services/*.swift Views/*.swift \
    -emit-module-path build/tests/Buffer.swiftmodule -o build/tests/libBuffer.dylib
buffer_test_app="$PWD/build/tests/BufferChecks.app"
mkdir -p "$buffer_test_app/Contents/MacOS" "$buffer_test_app/Contents/Resources"
cp -R Resources/*.lproj "$buffer_test_app/Contents/Resources/"
cat > "$buffer_test_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BufferChecks</string>
<key>CFBundleIdentifier</key><string>local.BufferChecks</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>BufferLocalDevelopment</key><true/>
</dict></plist>
PLIST
# This machine has Command Line Tools without XCTest. Run real pasteboard/file checks
# in a standalone harness; BufferTests remains the XCTest suite for full Xcode installs.
swiftc -sdk "$buffer_sdk" -swift-version 5 -I build/tests -L build/tests -lBuffer \
    -Xlinker -rpath -Xlinker "$PWD/build/tests" \
    -parse-as-library scripts/verify_paste.swift -o "$buffer_test_app/Contents/MacOS/BufferChecks"
BUFFER_EXPECT_LANGUAGE=en "$buffer_test_app/Contents/MacOS/BufferChecks" -AppleLanguages '(en)'
BUFFER_EXPECT_LANGUAGE=zh "$buffer_test_app/Contents/MacOS/BufferChecks" -AppleLanguages '(zh-Hans)'
