import AppKit
import SwiftUI

@MainActor
final class ObservedHistoryWindow: NSObject, NSWindowDelegate {
    static let shared = ObservedHistoryWindow()
    private var window: NSWindow?
    func windowWillClose(_ notification: Notification) {
        window?.contentViewController = nil
        window = nil
    }
    func show() {
        if window == nil {
            let value = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 660, height: 580),
                                 styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            value.delegate = self
            value.title = "Usage Capacity · Codex history"
            value.isReleasedWhenClosed = false
            value.contentViewController = NSHostingController(rootView: ObservedHistoryView(onClose: { [weak value] in value?.close() }))
            value.center()
            window = value
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
