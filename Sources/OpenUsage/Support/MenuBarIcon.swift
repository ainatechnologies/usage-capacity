import AppKit
@MainActor enum MenuBarIcon {
    static let image: NSImage? = {
        let image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: ProductIdentity.name)
        image?.isTemplate = true
        return image
    }()
}
