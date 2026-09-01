import Foundation

public enum ShortcutPhase: Equatable, Sendable {
    case keyDown
    case keyUp
}

/// Registers saved shortcuts by name or shortcuts kept only in memory.
public enum Shortcuts {
    public enum RegistrationError: Error, Equatable, Sendable {
        case unavailable
        case invalidShortcut
        case system(status: Int32)
    }

    /// A name used to save and register a shortcut.
    public struct Name: Hashable, Sendable {
        /// The unique key used to save the shortcut.
        public let rawValue: String
        /// The shortcut used when there is no saved value.
        public let defaultShortcut: Shortcut?

        public init(_ rawValue: String, default defaultShortcut: Shortcut? = nil) {
            precondition(!rawValue.isEmpty, "A shortcut name cannot be empty")
            self.rawValue = rawValue
            self.defaultShortcut = defaultShortcut
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
    }

    private final class ActionBox {
        var action: (ShortcutPhase) -> Void

        init(action: @escaping (ShortcutPhase) -> Void) {
            self.action = action
        }
    }

    private struct Registration {
        let action: ActionBox
        var shortcut: Shortcut?
        var id: UInt32?
    }

    @MainActor private static var namedRegistrations: [String: Registration] = [:]
    @MainActor private static var inMemoryRegistrations: [Shortcut: Registration] = [:]

    /// Registers the saved or default shortcut and keeps its callback.
    @MainActor
    public static func register(_ name: Name, action: @escaping () -> Void) throws {
        try register(name, onEvent: { phase in
            if phase == .keyDown {
                action()
            }
        })
    }

    @MainActor
    public static func register(
        _ name: Name,
        onEvent: @escaping (ShortcutPhase) -> Void
    ) throws {
        if let registration = namedRegistrations[name.rawValue] {
            if let id = registration.id {
                try GlobalShortcutManager.shared.retry(id: id)
            }
            registration.action.action = onEvent
            return
        }

        let actionBox = ActionBox(action: onEvent)
        let shortcut = shortcut(for: name)
        namedRegistrations[name.rawValue] = try Registration(
            action: actionBox,
            shortcut: shortcut,
            id: shortcut.map { try makeID(for: $0, action: actionBox) }
        )
    }

    /// Registers a shortcut without saving it.
    @MainActor
    public static func register(_ shortcut: Shortcut, action: @escaping () -> Void) throws {
        try register(shortcut, onEvent: { phase in
            if phase == .keyDown {
                action()
            }
        })
    }

    @MainActor
    public static func register(
        _ shortcut: Shortcut,
        onEvent: @escaping (ShortcutPhase) -> Void
    ) throws {
        if let registration = inMemoryRegistrations[shortcut] {
            if let id = registration.id {
                try GlobalShortcutManager.shared.retry(id: id)
            }
            registration.action.action = onEvent
            return
        }

        let actionBox = ActionBox(action: onEvent)
        inMemoryRegistrations[shortcut] = try Registration(
            action: actionBox,
            shortcut: shortcut,
            id: makeID(for: shortcut, action: actionBox)
        )
    }

    /// Stops a named shortcut but keeps its saved value.
    @MainActor
    public static func unregister(_ name: Name) {
        if let id = namedRegistrations.removeValue(forKey: name.rawValue)?.id {
            GlobalShortcutManager.shared.unregister(id: id)
        }
    }

    /// Stops a shortcut that was registered in memory.
    @MainActor
    public static func unregister(_ shortcut: Shortcut) {
        if let id = inMemoryRegistrations.removeValue(forKey: shortcut)?.id {
            GlobalShortcutManager.shared.unregister(id: id)
        }
    }

    /// Returns the saved shortcut, or the default if there is no saved value.
    public static func shortcut(for name: Name) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: storageKey(for: name)) else {
            return name.defaultShortcut
        }
        do {
            return try JSONDecoder().decode(Shortcut?.self, from: data)
        } catch {
            return name.defaultShortcut
        }
    }

    /// Saves a shortcut and updates its active registration.
    @MainActor
    public static func set(_ shortcut: Shortcut?, for name: Name) throws {
        if var registration = namedRegistrations[name.rawValue] {
            guard registration.shortcut != shortcut else {
                if let id = registration.id {
                    try GlobalShortcutManager.shared.retry(id: id)
                }
                persist(shortcut, for: name)
                return
            }

            let newID = try shortcut.map {
                try makeID(for: $0, action: registration.action)
            }
            if let id = registration.id {
                GlobalShortcutManager.shared.unregister(id: id)
            }
            registration.shortcut = shortcut
            registration.id = newID
            namedRegistrations[name.rawValue] = registration
        }
        persist(shortcut, for: name)
    }

    /// Restores the default shortcut and updates its registration.
    @MainActor
    public static func reset(_ name: Name) throws {
        try set(name.defaultShortcut, for: name)
        UserDefaults.standard.removeObject(forKey: storageKey(for: name))
    }

    @MainActor
    private static func makeID(for shortcut: Shortcut, action: ActionBox) throws -> UInt32 {
        try GlobalShortcutManager.shared.register(shortcut) { phase in
            action.action(phase)
        }
    }

    private static func storageKey(for name: Name) -> String {
        "ShortcutKit.\(name.rawValue)"
    }

    private static func persist(_ shortcut: Shortcut?, for name: Name) {
        UserDefaults.standard.set(
            try? JSONEncoder().encode(shortcut),
            forKey: storageKey(for: name)
        )
    }
}
