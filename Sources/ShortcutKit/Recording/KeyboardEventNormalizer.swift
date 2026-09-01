import AppKit

enum KeyboardEventNormalizer {
    static func key(from event: NSEvent) -> Key {
        Key(keyCode: event.keyCode)
    }

    static func modifiers(from flags: NSEvent.ModifierFlags) -> Modifiers {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var result: Modifiers = []
        if flags.contains(.command) {
            result.insert(.command)
        }
        if flags.contains(.option) {
            result.insert(.option)
        }
        if flags.contains(.control) {
            result.insert(.control)
        }
        if flags.contains(.shift) {
            result.insert(.shift)
        }
        return result
    }

    static func transitions(from old: Modifiers, to new: Modifiers) -> [RecordingEvent] {
        Modifier.allCases.compactMap { modifier in
            let value = Modifiers(modifier)
            switch (old.contains(value), new.contains(value)) {
            case (false, true): return RecordingEvent.modifierDown(modifier)
            case (true, false): return RecordingEvent.modifierUp(modifier)
            default: return nil
            }
        }
    }
}
