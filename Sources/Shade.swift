import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum Opacity {
        static let defaultValue: CGFloat = 0.35
        static let maximum = 0.80
        static let gamma = 1.8
    }

    private var windows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        rebuildOverlays()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        rebuildOverlays()
    }

    private func rebuildOverlays() {
        windows.forEach { $0.close() }
        windows.removeAll(keepingCapacity: true)

        let opacity = readOpacity()
        windows = NSScreen.screens.map { createOverlay(for: $0, opacity: opacity) }
    }

    private func readOpacity() -> CGFloat {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".shade-opacity", isDirectory: false)

        guard
            let text = try? String(contentsOf: fileURL, encoding: .utf8),
            let percentage = Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return Opacity.defaultValue
        }

        let normalized = min(max(percentage, 0), 100) / 100
        let opacity = pow(normalized, Opacity.gamma) * Opacity.maximum

        return CGFloat(opacity)
    }

    private func createOverlay(for screen: NSScreen, opacity: CGFloat) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.backgroundColor = NSColor.black.withAlphaComponent(opacity)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        window.orderFrontRegardless()

        return window
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
