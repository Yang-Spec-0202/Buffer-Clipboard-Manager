import XCTest
import AppKit
@testable import Buffer

final class PasteControllerTests: XCTestCase {
    private var root: URL!
    private var store: ClipboardStore!
    private var board: NSPasteboard!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = ClipboardStore(storageDirectory: root.appendingPathComponent("history"))
        board = NSPasteboard.withUniqueName()
    }

    override func tearDownWithError() throws {
        board.releaseGlobally()
        store = nil
        try FileManager.default.removeItem(at: root)
    }

    private func imageItem(red: CGFloat) throws -> ClipboardItem {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for x in 0..<2 { for y in 0..<2 {
            bitmap.setColor(NSColor(deviceRed: red, green: 0, blue: 0, alpha: 1), atX: x, y: y)
        } }
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        return .image(filename: try XCTUnwrap(store.saveImage(png)))
    }

    func testScreenshotHasReadableAbsolutePathAndNativeImageFormats() throws {
        let prepared = try PasteController.prepare([imageItem(red: 1)], store: store,
                                                   exportDirectory: root.appendingPathComponent("exports"))
        XCTAssertTrue(PasteController.write(prepared, to: board, forTerminal: true))
        let path = try XCTUnwrap(board.string(forType: .string))
        XCTAssertTrue(path.hasPrefix("/"))
        XCTAssertNotNil(NSImage(contentsOfFile: path))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), board.data(forType: .png))
        XCTAssertNotNil(board.data(forType: .tiff))
        XCTAssertNil(board.string(forType: .fileURL))
    }

    func testSubsequentScreenshotDoesNotOverwritePreviousAttachment() throws {
        let directory = root.appendingPathComponent("exports")
        let first = try PasteController.prepare([imageItem(red: 1)], store: store, exportDirectory: directory)
        let bytes = try Data(contentsOf: first.images[0].url)
        let second = try PasteController.prepare([imageItem(red: 0)], store: store, exportDirectory: directory)
        XCTAssertNotEqual(first.images[0].url, second.images[0].url)
        XCTAssertEqual(try Data(contentsOf: first.images[0].url), bytes)
        XCTAssertNotEqual(try Data(contentsOf: second.images[0].url), bytes)
    }

    func testMixedSelectionCreatesSeparateTerminalAttachmentEvents() throws {
        let prepared = try PasteController.prepare([.text("说明\nsecond line"), imageItem(red: 1), imageItem(red: 0)],
                                                   store: store, exportDirectory: root.appendingPathComponent("exports"))
        let steps = PasteController.terminalSteps(prepared)
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].text, "说明\nsecond line")
        XCTAssertTrue(steps[0].images.isEmpty)
        for step in steps.dropFirst() {
            XCTAssertNil(step.text)
            XCTAssertEqual(step.images.count, 1)
            XCTAssertEqual(step.pasteboardItems(forTerminal: true).count, 1)
        }
        let nativeSteps = PasteController.pasteSteps(prepared, forTerminal: false)
        XCTAssertEqual(nativeSteps.count, 2)
        XCTAssertEqual(nativeSteps[0].text, prepared.text)
        XCTAssertTrue(nativeSteps[0].images.isEmpty)
        XCTAssertEqual(nativeSteps[1].images.count, 2)
        XCTAssertNil(nativeSteps[1].text)
    }

    func testNativeApplicationsRetainImageAndFileRepresentations() throws {
        let prepared = try PasteController.prepare([imageItem(red: 1)], store: store,
                                                   exportDirectory: root.appendingPathComponent("exports"))
        XCTAssertTrue(PasteController.write(prepared, to: board))
        XCTAssertEqual(board.string(forType: .fileURL), prepared.images[0].url.absoluteString)
        XCTAssertNotNil(NSImage(pasteboard: board))
    }

    func testMultilineAndFileBackedTextAreNotChanged() throws {
        let text = "中文第一行\nsecond line\n\tlast line  "
        let filename = try XCTUnwrap(store.saveText(text))
        let item = ClipboardItem.largeText(preview: "preview", filename: filename)
        let prepared = try PasteController.prepare([item, .text("next")], store: store)
        XCTAssertTrue(PasteController.write(prepared, to: board, forTerminal: true))
        XCTAssertEqual(board.string(forType: .string), text + "\nnext")
    }

    func testExportFailureLeavesExistingClipboardUntouched() throws {
        board.setString("keep me", forType: .string)
        let blocker = root.appendingPathComponent("not-a-directory")
        try Data([1]).write(to: blocker)
        XCTAssertThrowsError(try PasteController.prepare([imageItem(red: 1)], store: store, exportDirectory: blocker))
        XCTAssertEqual(board.string(forType: .string), "keep me")
        XCTAssertThrowsError(try PasteController.prepare([.image(filename: "missing.png")], store: store))
    }

    func testTerminalDetectionAndPathQuoting() {
        for id in ["com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty", "com.microsoft.VSCode"] {
            XCTAssertTrue(PasteController.isTerminal(bundleIdentifier: id))
        }
        XCTAssertFalse(PasteController.isTerminal(bundleIdentifier: "com.apple.Notes"))
        XCTAssertFalse(PasteController.isTerminal(bundleIdentifier: nil))
        XCTAssertEqual(PasteController.quotedPath("/tmp/image.png"), "/tmp/image.png")
        XCTAssertEqual(PasteController.quotedPath("/tmp/屏幕 截图.png"), "'/tmp/屏幕 截图.png'")
        XCTAssertEqual(PasteController.quotedPath("/tmp/a'b.png"), "'/tmp/a'\\''b.png'")
    }
}
