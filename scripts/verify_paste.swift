import Foundation
import AppKit
@testable import Buffer

@main
struct PasteRegression {
    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL: " + message) }
        print("PASS: " + message)
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ClipboardStore(storageDirectory: root.appendingPathComponent("history"))
        let board = NSPasteboard.withUniqueName()
        defer {
            board.releaseGlobally()
            try? FileManager.default.removeItem(at: root)
        }
        func image(_ red: CGFloat) throws -> ClipboardItem {
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            for x in 0..<2 { for y in 0..<2 {
                bitmap.setColor(NSColor(deviceRed: red, green: 0, blue: 0, alpha: 1), atX: x, y: y)
            } }
            return .image(filename: store.saveImage(bitmap.representation(using: .png, properties: [:])!)!)
        }
        let exports = root.appendingPathComponent("exports")
        let first = try PasteController.prepare([image(1)], store: store, exportDirectory: exports)
        check(PasteController.write(first, to: board, forTerminal: true), "write screenshot to pasteboard")
        let path = board.string(forType: .string)!
        check(path.hasPrefix("/") && NSImage(contentsOfFile: path) != nil, "terminal path is absolute and readable")
        let firstBytes = try Data(contentsOf: first.images[0].url)
        check(firstBytes == board.data(forType: .png) && board.data(forType: .tiff) != nil,
              "PNG and TIFF clipboard representations preserve the image")
        check(board.string(forType: .fileURL) == nil, "terminal paste does not expose basename-only file URL")
        let second = try PasteController.prepare([image(0)], store: store, exportDirectory: exports)
        check(first.images[0].url != second.images[0].url, "two pastes have different filenames")
        let unchanged = try Data(contentsOf: first.images[0].url)
        let secondBytes = try Data(contentsOf: second.images[0].url)
        check(unchanged == firstBytes && secondBytes != firstBytes, "later screenshot cannot overwrite pending attachment")
        check(PasteController.write(first, to: board), "write native application payload")
        check(board.string(forType: .fileURL) == first.images[0].url.absoluteString && NSImage(pasteboard: board) != nil,
              "native apps can read both image and file representations")
        let text = "中文第一行\nsecond line\n\tlast line  "
        let filename = store.saveText(text)!
        let largeText = ClipboardItem.largeText(preview: "preview", filename: filename)
        let combined = try PasteController.prepare([largeText, .text("next"), image(1), image(0)],
                                                  store: store, exportDirectory: exports)
        let steps = PasteController.terminalSteps(combined)
        check(steps.count == 3 && steps[0].text == text + "\nnext" && steps[0].images.isEmpty,
              "multiline and file-backed text survive mixed selection")
        check(steps.dropFirst().allSatisfy { $0.text == nil && $0.images.count == 1 },
              "each image becomes a separate TUI attachment paste event")
        let nativeSteps = PasteController.pasteSteps(combined, forTerminal: false)
        check(nativeSteps.count == 2 && nativeSteps[0].text == text + "\nnext" && nativeSteps[0].images.isEmpty,
              "native mixed selection starts with a text-only paste")
        check(nativeSteps[1].text == nil && nativeSteps[1].images.count == 2,
              "native mixed selection then pastes all images together")
        board.clearContents()
        board.setString("keep me", forType: .string)
        let blocker = root.appendingPathComponent("not-a-directory")
        try Data([1]).write(to: blocker)
        do {
            _ = try PasteController.prepare([image(1)], store: store, exportDirectory: blocker)
            fatalError("Expected export failure")
        } catch { check(board.string(forType: .string) == "keep me", "export failure leaves clipboard unchanged") }
        do {
            _ = try PasteController.prepare([.image(filename: "missing.png")], store: store)
            fatalError("Expected missing image failure")
        } catch { print("PASS: missing image is reported") }
        check(PasteController.isTerminal(bundleIdentifier: "com.apple.Terminal") &&
              PasteController.isTerminal(bundleIdentifier: "com.googlecode.iterm2") &&
              !PasteController.isTerminal(bundleIdentifier: "com.apple.Notes"), "detect terminal destinations")
        check(PasteController.quotedPath("/tmp/屏幕 截图.png") == "'/tmp/屏幕 截图.png'" &&
              PasteController.quotedPath("/tmp/a'b.png") == "'/tmp/a'\\''b.png'", "quote spaces, Chinese and apostrophes")
        let chinese = ProcessInfo.processInfo.environment["BUFFER_EXPECT_LANGUAGE"] == "zh"
        check(L10n.tr("Paste") == (chinese ? "粘贴" : "Paste"), "localized static interface label")
        check(L10n.format("%d items", 3) == (chinese ? "3 条记录" : "3 items"), "localized dynamic item count")
        check(UpdateService.isLocalBuild && UpdateService.shared.availableUpdate == nil,
              "development build cannot restore an upstream update")
        print("All paste regression checks passed.")
    }
}
