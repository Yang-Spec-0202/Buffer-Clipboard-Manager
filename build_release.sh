#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
source scripts/macos_sdk.sh

app_name="Buffer"
minimum_macos="13.0"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
build_number=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
release_dir="${BUFFER_RELEASE_DIR:-build/release-${version}-${build_number}}"

if [[ -e "$release_dir" ]]; then
    echo "Output already exists: $release_dir" >&2
    echo "Set BUFFER_RELEASE_DIR to a fresh path, or move the old build aside." >&2
    exit 1
fi

mkdir -p "$release_dir/objects" "$release_dir/$app_name.app/Contents/MacOS" \
    "$release_dir/$app_name.app/Contents/Resources"
app="$release_dir/$app_name.app"
resources="$app/Contents/Resources"

echo "Building Buffer $version ($build_number) using $buffer_sdk"
for arch in arm64 x86_64; do
    echo "Compiling $arch"
    swiftc -sdk "$buffer_sdk" -target "$arch-apple-macosx$minimum_macos" -swift-version 5 \
        -parse-as-library -framework Cocoa -framework SwiftUI -framework Carbon \
        BufferApp.swift AppDelegate.swift Models/*.swift Services/*.swift Views/*.swift \
        -o "$release_dir/objects/Buffer-$arch"
done

lipo -create "$release_dir/objects/Buffer-arm64" "$release_dir/objects/Buffer-x86_64" \
    -output "$app/Contents/MacOS/Buffer"
cp Info.plist "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Buffer' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.samirpatil.Buffer' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Buffer' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Buffer' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile AppIcon' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $minimum_macos" "$app/Contents/Info.plist"

cp -R Resources/*.lproj "$resources/"
iconset="$release_dir/AppIcon.iconset"
mkdir -p "$iconset"
cp Assets.xcassets/AppIcon.appiconset/*.png "$iconset/"
iconutil -c icns "$iconset" -o "$resources/AppIcon.icns"
printf 'APPL????' > "$app/Contents/PkgInfo"
xattr -cr "$app"

# This project has no Developer ID certificate. Ad-hoc signing lets the app
# verify its own downloaded update ZIP, but does not provide Apple notarization.
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"

zip_path="$release_dir/Buffer_${version}_Universal.zip"
dmg_path="$release_dir/Buffer_${version}_Universal.dmg"
ditto -ck --rsrc --sequesterRsrc --keepParent "$app" "$zip_path"

dmg_root="$release_dir/dmg-root"
mkdir -p "$dmg_root"
ditto "$app" "$dmg_root/$app_name.app"
ln -s /Applications "$dmg_root/Applications"
hdiutil create -volname "Buffer $version" -srcfolder "$dmg_root" -ov -format UDZO "$dmg_path"
hdiutil verify "$dmg_path"

zip_check="$release_dir/zip-check"
mkdir -p "$zip_check"
ditto -xk "$zip_path" "$zip_check"
codesign --verify --deep --strict "$zip_check/$app_name.app"
archs=$(lipo -archs "$app/Contents/MacOS/Buffer")
[[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]]
(cd "$release_dir" && shasum -a 256 "Buffer_${version}_Universal.dmg" "Buffer_${version}_Universal.zip" \
    | tee SHA256SUMS.txt)

echo "Universal app: $app"
echo "DMG: $dmg_path"
echo "Updater ZIP: $zip_path"
echo "Architectures: $archs"
