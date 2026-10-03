import Cocoa
import UniformTypeIdentifiers

/// Immutable exports prevent subsequent screenshots from replacing a pending TUI attachment.
struct PreparedPaste {
    let text: String?
    let images: [PreparedImage]

    struct PreparedImage {
        let url: URL
        let png: Data
        let tiff: Data
    }

    func pasteboardItems(forTerminal: Bool) -> [NSPasteboardItem] {
        var result: [NSPasteboardItem] = []
        if let text {
            let item = NSPasteboardItem()
            item.setString(text, forType: .string)
            result.append(item)
        }
        for image in images {
            let item = NSPasteboardItem()
            item.setData(image.png, forType: .png)
            item.setData(image.tiff, forType: .tiff)
            // Terminals need an absolute path as text. Keep raster data for native apps
            // and TUI clipboard-image shortcuts; file URLs alone are insufficient.
            item.setString(PasteController.quotedPath(image.url.path), forType: .string)
            if !forTerminal { item.setString(image.url.absoluteString, forType: .fileURL) }
            result.append(item)
        }
        return result
    }
}

class PasteController {
    private static var activeOperation = UUID()

    static func isTerminal(bundleIdentifier: String?) -> Bool {
        guard let id = bundleIdentifier?.lowercased() else { return false }
        return [
            "com.apple.terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty",
            "dev.warp.warp-stable", "dev.warp.warp", "org.alacritty", "io.alacritty",
            "com.github.wez.wezterm", "net.kovidgoyal.kitty", "co.zeit.hyper",
            "com.termius-dmg.mac", "com.termius.mac", "com.microsoft.vscode",
            "com.microsoft.vscodeinsiders", "com.todesktop.230313mzl4w4u92", "dev.zed.zed"
        ].contains(id)
    }

    static func quotedPath(_ path: String) -> String {
        let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/._-"))
        if path.unicodeScalars.allSatisfy({ safe.contains($0) }) { return path }
        return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    enum PreparationError: Error { case unreadableContent, cannotExportImage }

    /// Prepare all content before changing the clipboard. Tests use an isolated store/directory.
    static func prepare(_ items: [ClipboardItem], store: ClipboardStore,
                        exportDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
                            .appendingPathComponent("BufferPaste", isDirectory: true)) throws -> PreparedPaste {
        var texts: [String] = []
        var images: [PreparedPaste.PreparedImage] = []
        for item in items {
            switch item.type {
            case .text:
                guard let text = store.fullText(for: item) else { throw PreparationError.unreadableContent }
                texts.append(text)
            case .image:
                guard let image = store.image(for: item), let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    throw PreparationError.unreadableContent
                }
                do {
                    try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
                    let url = exportDirectory.appendingPathComponent(UUID().uuidString + ".png")
                    try png.write(to: url, options: .atomic)
                    images.append(.init(url: url, png: png, tiff: tiff))
                } catch { throw PreparationError.cannotExportImage }
            }
        }
        return PreparedPaste(text: texts.isEmpty ? nil : texts.joined(separator: "\n"), images: images)
    }

    /// TUIs detect an image path only when it arrives as its own paste event.
    static func terminalSteps(_ prepared: PreparedPaste) -> [PreparedPaste] {
        var steps: [PreparedPaste] = []
        if let text = prepared.text { steps.append(.init(text: text, images: [])) }
        steps += prepared.images.map { PreparedPaste(text: nil, images: [$0]) }
        return steps
    }

    static func pasteSteps(_ prepared: PreparedPaste, forTerminal: Bool) -> [PreparedPaste] {
        if forTerminal { return terminalSteps(prepared) }
        // Preserve the original mixed-selection behavior in native apps: one text paste,
        // then one paste containing all images. Many apps read only the first item otherwise.
        if let text = prepared.text, !prepared.images.isEmpty {
            return [.init(text: text, images: []), .init(text: nil, images: prepared.images)]
        }
        return [prepared]
    }

    @discardableResult
    static func write(_ prepared: PreparedPaste, to pasteboard: NSPasteboard = .general,
                      forTerminal: Bool = false) -> Bool {
        let items = prepared.pasteboardItems(forTerminal: forTerminal)
        guard !items.isEmpty else { return false }
        if pasteboard === NSPasteboard.general {
            NotificationCenter.default.post(name: .bufferIgnoreNextChange, object: nil)
        }
        pasteboard.clearContents()
        return pasteboard.writeObjects(items)
    }

    static func copyToClipboard(_ item: ClipboardItem, store: ClipboardStore) {
        copyMultipleToClipboard([item], store: store)
    }

    static func copyMultipleToClipboard(_ items: [ClipboardItem], store: ClipboardStore) {
        guard !items.isEmpty else { return }
        do { write(try prepare(items, store: store)) }
        catch { showFailure(L10n.tr("Unable to read or export the selected content.")) }
    }

    static func paste(_ item: ClipboardItem, store: ClipboardStore, previousApp: NSRunningApplication? = nil) {
        pasteMultiple([item], store: store, previousApp: previousApp)
    }

    static func pasteMultiple(_ items: [ClipboardItem], store: ClipboardStore, previousApp: NSRunningApplication? = nil) {
        guard !items.isEmpty else { return }
        let prepared: PreparedPaste
        do { prepared = try prepare(items, store: store) }
        catch {
            showFailure(L10n.tr("Unable to read or export the selected content."))
            return
        }
        let terminal = isTerminal(bundleIdentifier: previousApp?.bundleIdentifier)
        let steps = pasteSteps(prepared, forTerminal: terminal)
        activeOperation = UUID()
        let operation = activeOperation
        write(steps[0], forTerminal: terminal)
        guard AXIsProcessTrusted() else {
            showFailure(L10n.tr("Open System Settings → Privacy & Security → Device Control & Data Access and turn on Buffer. If it is already on, remove the old Buffer entry, add /Applications/Buffer.app again, then quit and reopen Buffer. The content is copied; you can paste manually with ⌘V."))
            return
        }
        guard let target = previousApp, !target.isTerminated,
              target.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            showFailure(L10n.tr("The destination app is unavailable. Focus the destination and reopen Buffer, or paste manually with ⌘V."))
            return
        }
        target.activate(options: .activateIgnoringOtherApps)
        pasteStep(steps, index: 0, target: target, terminal: terminal, operation: operation,
                  earliest: Date().addingTimeInterval(0.15), deadline: Date().addingTimeInterval(2))
    }

    private static func pasteStep(_ steps: [PreparedPaste], index: Int, target: NSRunningApplication,
                                  terminal: Bool, operation: UUID, earliest: Date, deadline: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            guard operation == activeOperation else { return }
            let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
            let modifiers = CGEventSource.flagsState(.combinedSessionState)
                .intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
            // Wait for focus and release of shortcut keys. Held Shift otherwise turns Cmd+V
            // into Cmd+Shift+V. Abort when activation fails instead of typing into another app.
            if frontmost != target.processIdentifier || !modifiers.isEmpty || Date() < earliest {
                guard Date() < deadline, !target.isTerminated else {
                    showFailure(L10n.tr("Could not focus the destination app. The content is copied; paste manually with ⌘V."))
                    return
                }
                pasteStep(steps, index: index, target: target, terminal: terminal,
                          operation: operation, earliest: earliest, deadline: deadline)
                return
            }
            guard write(steps[index], forTerminal: terminal) else { return }
            let source = CGEventSource(stateID: .privateState)
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cgSessionEventTap)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                up.post(tap: .cgSessionEventTap)
                guard operation == activeOperation, index + 1 < steps.count else { return }
                pasteStep(steps, index: index + 1, target: target, terminal: terminal,
                          operation: operation, earliest: Date().addingTimeInterval(0.3),
                          deadline: Date().addingTimeInterval(2))
            }
        }
    }

    private static func showFailure(_ message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.tr("Paste needs attention")
        alert.informativeText = message
        alert.addButton(withTitle: L10n.tr("OK"))
        alert.runModal()
    }

    static func saveImageToDisk(_ image: NSImage) {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            panel.nameFieldStringValue = "Image-\(formatter.string(from: Date()))"
            panel.canCreateDirectories = true
            if panel.runModal() == .OK, let url = panel.url,
               let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                do { try png.write(to: url, options: .atomic) }
                catch { showFailure(L10n.tr("Unable to save the image.")) }
            }
        }
    }
}
