import SwiftUI

/// Defines a single keyboard shortcut entry
struct ShortcutEntry: Identifiable {
    let id = UUID()
    let keys: [String]
    let title: String
    let description: String?
    
    init(keys: [String], title: String, description: String? = nil) {
        self.keys = keys
        self.title = title
        self.description = description
    }
}

/// Category grouping for shortcuts
struct ShortcutCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let items: [ShortcutEntry]
}

/// Reusable Apple-style tactile key cap badge
struct KeyCapView: View {
    let key: String
    
    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.primary.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
    }
}

/// Comprehensive cheat sheet view for all Buffer shortcuts
struct ShortcutsCheatSheetView: View {
    var isEmbeddedInSettings: Bool = false
    var onOpenSettings: (() -> Void)? = nil
    
    private let categories: [ShortcutCategory] = [
        ShortcutCategory(
            name: L10n.tr("Navigation & Selection"),
            icon: "arrow.up.and.down",
            items: [
                ShortcutEntry(keys: ["↑", "↓"], title: L10n.tr("Navigate history")),
                ShortcutEntry(keys: ["⌘", "A"], title: L10n.tr("Select all items")),
                ShortcutEntry(keys: ["⇧", "↑ / ↓"], title: L10n.tr("Multi-select items")),
                ShortcutEntry(keys: ["↵"], title: L10n.tr("Paste to frontmost app")),
                ShortcutEntry(keys: ["Esc"], title: L10n.tr("Dismiss Buffer window"))
            ]
        ),
        ShortcutCategory(
            name: L10n.tr("Item Actions"),
            icon: "bolt.fill",
            items: [
                ShortcutEntry(keys: ["⌘", "C"], title: L10n.tr("Copy & dismiss")),
                ShortcutEntry(keys: ["⌘", "P"], title: L10n.tr("Pin to top")),
                ShortcutEntry(keys: ["⌘", "B"], title: L10n.tr("Bookmark item")),
                ShortcutEntry(keys: ["⌘", "E"], title: L10n.tr("Edit snippet")),
                ShortcutEntry(keys: ["⌘", "S"], title: L10n.tr("Save image to disk")),
                ShortcutEntry(keys: ["⌘", "⌫"], title: L10n.tr("Delete item (or selected)"))
            ]
        ),
        ShortcutCategory(
            name: L10n.tr("Zoom & Size"),
            icon: "plus.magnifyingglass",
            items: [
                ShortcutEntry(keys: ["⌘", "+"], title: L10n.tr("Zoom in (larger rows & preview text)")),
                ShortcutEntry(keys: ["⌘", "-"], title: L10n.tr("Zoom out")),
                ShortcutEntry(keys: ["⌘", "0"], title: L10n.tr("Reset zoom to 100%")),
                ShortcutEntry(keys: [L10n.tr("2× Click")], title: L10n.tr("Toggle image actual size / fit")),
                ShortcutEntry(keys: [L10n.tr("Pinch")], title: L10n.tr("Zoom image on trackpad"))
            ]
        ),
        ShortcutCategory(
            name: L10n.tr("Application"),
            icon: "gearshape.fill",
            items: [
                ShortcutEntry(keys: ["⌘", ","], title: L10n.tr("Open Settings")),
                ShortcutEntry(keys: ["⌘", "/"], title: L10n.tr("Toggle this cheat sheet"))
            ]
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.tr("Keyboard Shortcuts"))
                        .font(.system(size: 13, weight: .semibold))
                    Text(L10n.tr("Master Buffer with your keyboard"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let onOpen = onOpenSettings, !isEmbeddedInSettings {
                    Button(action: onOpen) {
                        HStack(spacing: 4) {
                            Text(L10n.tr("Settings"))
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "gearshape")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .help(L10n.tr("Open Buffer Settings (⌘,)"))
                }
            }
            
            Divider()
            
            // Categories
            VStack(spacing: 12) {
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: category.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(category.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            ForEach(category.items) { item in
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary.opacity(0.85))
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 3) {
                                        ForEach(item.keys, id: \.self) { key in
                                            KeyCapView(key: key)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: isEmbeddedInSettings ? nil : 320)
    }
}
