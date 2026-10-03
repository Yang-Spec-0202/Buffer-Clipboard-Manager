# Development

This community build is based on [Samir Patil's Buffer](https://github.com/samirpatil2000/Buffer). Preserve the upstream MIT license and attribution when redistributing.

## Build

Requirements: macOS 13 or later and Xcode Command Line Tools. No `.env`, Apple Developer ID certificate, or full Xcode installation is needed for the local scripts.

Build a native-architecture development copy (automatic updates disabled):

```sh
./build_local.sh
```

Build the universal release app, ZIP, and DMG:

```sh
./build_release.sh
```

The release app is ad-hoc signed and is not notarized. See [RELEASE.md](RELEASE.md) before publishing. The release version and build number are set in `Info.plist`; the development build marks itself with `BufferLocalDevelopment` and uses the same version.

## Tests and localization

```sh
./scripts/test_local.sh
python3 scripts/verify_localization.py
```

The localization verifier checks that English and Simplified Chinese have the same keys and format arguments. The local regression script exercises PNG path export, image formats, multi-selection, text, and error cases without using personal clipboard history.

## Terminal paste and permission

`Services/PasteController.swift` writes screenshot PNGs to a temporary `BufferPaste` directory and uses `CGEvent` to send the paste shortcut to the previously focused local app. `AXIsProcessTrusted()` gates simulated keyboard events. If permission is denied, the selected content is still copied for manual paste.

The permission is Accessibility in Apple's API. In System Settings, it is generally under **Privacy & Security → Accessibility**; some recent macOS releases show the app's control permission under **Device Control & Data Access**. Ad-hoc signatures identify a specific build, so macOS may ask users to grant permission again after a rebuilt release.

Clipboard data is stored locally. The app contacts the public GitHub Releases API only to check for updates; clipboard contents and screenshots are not sent.
