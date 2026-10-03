# Release process

## Build and verify

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. Run localization and clipboard regression checks:

   ```sh
   ./scripts/test_local.sh
   python3 scripts/verify_localization.py
   ```

3. Build the universal app and packages:

   ```sh
   ./build_release.sh
   ```

4. Confirm that the app contains both architectures, the signature verifies, and the DMG can be mounted:

   ```sh
   lipo -archs build/release-<version>-<build>/Buffer.app/Contents/MacOS/Buffer
   codesign --verify --deep --strict build/release-<version>-<build>/Buffer.app
   hdiutil verify build/release-<version>-<build>/Buffer_<version>_Universal.dmg
   shasum -a 256 build/release-<version>-<build>/Buffer_*
   ```

The ZIP contains `Buffer.app` at its root; the app updater selects this universal ZIP asset from GitHub Releases. The DMG contains the app and an Applications shortcut for manual installation.

## Publish

Push the release commit to `main`, then create a release from the matching tag and attach both generated assets:

```sh
gh release create v<version> \
  build/release-<version>-<build>/Buffer_<version>_Universal.dmg \
  build/release-<version>-<build>/Buffer_<version>_Universal.zip \
  --title "Buffer <version> — terminal screenshot paste" \
  --notes-file RELEASE_NOTES.md
```

The current distribution has no Apple Developer ID certificate. `build_release.sh` signs locally with ad-hoc signing and does not submit to Apple's notarization service. Clearly disclose this in the release notes; do not describe the build as notarized or Developer ID signed.
