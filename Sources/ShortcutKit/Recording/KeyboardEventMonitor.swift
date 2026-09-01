import AppKit

@MainActor
protocol KeyboardEventMonitoring: AnyObject, Sendable {
    func start(handler: @escaping (NSEvent) -> Void)
    func stop()
}

@MainActor
final class KeyboardEventMonitor: KeyboardEventMonitoring {
    private nonisolated(unsafe) var token: Any?

    func start(handler: @escaping (NSEvent) -> Void) {
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

    deinit {
        if let token {
            NSEvent.removeMonitor(token)
        }
    }
}
