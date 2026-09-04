import AppKit

@MainActor
protocol KeyboardEventMonitoring: AnyObject, Sendable {
    func start(handler: @escaping @MainActor (NSEvent) -> Void)
    func stop()
}

@MainActor
final class KeyboardEventMonitor: KeyboardEventMonitoring {
    private var token: Any?

    func start(handler: @escaping @MainActor (NSEvent) -> Void) {
        guard token == nil else { return }
        token = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { event in
            handler(event)
            return nil
        }
    }

    func stop() {
        guard let token else { return }
        NSEvent.removeMonitor(token)
        self.token = nil
    }
}
