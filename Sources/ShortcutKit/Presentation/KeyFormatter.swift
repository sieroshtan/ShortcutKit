import Carbon.HIToolbox

/// Formats keys with fixed English labels or labels from the current input source.
public struct KeyFormatter: Sendable {
    public enum Layout: Sendable {
        case english
        case current
    }

    private static let englishKeys: [Key: String] = [
        .a: "A",
        .b: "B",
        .c: "C",
        .d: "D",
        .e: "E",
        .f: "F",
        .g: "G",
        .h: "H",
        .i: "I",
        .j: "J",
        .k: "K",
        .l: "L",
        .m: "M",
        .n: "N",
        .o: "O",
        .p: "P",
        .q: "Q",
        .r: "R",
        .s: "S",
        .t: "T",
        .u: "U",
        .v: "V",
        .w: "W",
        .x: "X",
        .y: "Y",
        .z: "Z",

        .zero: "0",
        .one: "1",
        .two: "2",
        .three: "3",
        .four: "4",
        .five: "5",
        .six: "6",
        .seven: "7",
        .eight: "8",
        .nine: "9",

        .backslash: "\\",
        .backtick: "`",
        .comma: ",",
        .equal: "=",
        .minus: "-",
        .period: ".",
        .quote: "'",
        .semicolon: ";",
        .slash: "/",
        .leftBracket: "[",
        .rightBracket: "]",
    ]

    private static let specialKeys: [Key: String] = [
        .returnKey: "Return",
        .tab: "Tab",
        .space: "Space",
        .delete: "Delete",
        .deleteForward: "Forward Delete",
        .escape: "Escape",
        .help: "Help",

        .isoSection: "§",
        .jisYen: "¥",
        .jisUnderscore: "_",
        .jisKeypadComma: ",",
        .jisEisu: "英数",
        .jisKana: "かな",

        .home: "Home",
        .end: "End",
        .pageUp: "Page Up",
        .pageDown: "Page Down",
        .leftArrow: "←",
        .rightArrow: "→",
        .upArrow: "↑",
        .downArrow: "↓",

        .mute: "Mute",
        .volumeUp: "Volume Up",
        .volumeDown: "Volume Down",

        .f1: "F1",
        .f2: "F2",
        .f3: "F3",
        .f4: "F4",
        .f5: "F5",
        .f6: "F6",
        .f7: "F7",
        .f8: "F8",
        .f9: "F9",
        .f10: "F10",
        .f11: "F11",
        .f12: "F12",
        .f13: "F13",
        .f14: "F14",
        .f15: "F15",
        .f16: "F16",
        .f17: "F17",
        .f18: "F18",
        .f19: "F19",
        .f20: "F20",

        .keypad0: "0",
        .keypad1: "1",
        .keypad2: "2",
        .keypad3: "3",
        .keypad4: "4",
        .keypad5: "5",
        .keypad6: "6",
        .keypad7: "7",
        .keypad8: "8",
        .keypad9: "9",
        .keypadClear: "Clear",
        .keypadDecimal: ".",
        .keypadDivide: "/",
        .keypadEnter: "Enter",
        .keypadEquals: "=",
        .keypadMinus: "-",
        .keypadMultiply: "*",
        .keypadPlus: "+",
    ]

    private let layout: Layout

    public init(layout: Layout = .english) {
        self.layout = layout
    }

    @MainActor
    public func string(for key: Key) -> String {
        if let label = Self.specialKeys[key] {
            return label
        }

        switch layout {
        case .english:
            return Self.englishKeys[key] ?? "Key \(key.keyCode)"
        case .current:
            return translatedString(for: key) ?? Self.englishKeys[key] ?? "Key \(key.keyCode)"
        }
    }

    @MainActor
    private func translatedString(for key: Key) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
            return nil
        }
        return Self.translatedString(for: key, using: source)
    }

    @MainActor
    static func translatedString(for key: Key, using source: TISInputSource) -> String? {
        guard let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let data = unsafeBitCast(property, to: CFData.self)
        guard let bytes = CFDataGetBytePtr(data) else { return nil }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(
            layout,
            key.keyCode,
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            characters.count,
            &length,
            &characters
        )
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }
}
