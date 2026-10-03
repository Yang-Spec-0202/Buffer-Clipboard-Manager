# Buffer 3.0.2

This community release focuses on pasting clipboard screenshots into local terminal AI tools.

### What's included

- Paste screenshot clips into Codex CLI and OpenCode as image attachments through local PNG paths.
- Paste multiple screenshots one by one so each image is recognized separately.
- Simplified Chinese interface alongside English.
- More reliable focus restoration and clearer permission guidance for simulated `⌘V`.

### Install

Download `Buffer_3.0.2_Universal.dmg`, open it, and drag `Buffer.app` to Applications. The universal app supports Apple Silicon and Intel Macs running macOS 13 or later.

Automatic terminal paste requires Accessibility permission. In System Settings, allow Buffer under Privacy & Security → Accessibility; some recent macOS versions group this permission under Device Control & Data Access. If permission is denied, Buffer still copies the content so you can paste manually with `⌘V`.

### Signing and Gatekeeper

This community build is ad-hoc signed and **not notarized by Apple** because the project does not have an Apple Developer ID certificate. macOS may show a Gatekeeper warning on first launch. Review the source and proceed only if you trust it.

Clipboard history and exported screenshots stay on your Mac. The app checks GitHub for release metadata; screenshot paths work with local terminal sessions, not remote SSH sessions.

Based on [Buffer by Samir Patil](https://github.com/samirpatil2000/Buffer), under the MIT License.
