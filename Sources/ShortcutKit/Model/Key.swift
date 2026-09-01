import Carbon.HIToolbox

/// A macOS keyboard key that does not depend on the keyboard layout.
///
/// `keyCode` is the macOS virtual key code. Use ``KeyFormatter`` to get text
/// for the key.
public struct Key: Hashable, Codable, Sendable {
    public let keyCode: UInt16

    public init(keyCode: UInt16) {
        self.keyCode = keyCode
    }
}

public extension Key {
    // Letter names use ANSI key positions. KeyFormatter can show text from
    // the user's current keyboard layout.

    static let a = Self(keyCode: UInt16(kVK_ANSI_A))
    static let b = Self(keyCode: UInt16(kVK_ANSI_B))
    static let c = Self(keyCode: UInt16(kVK_ANSI_C))
    static let d = Self(keyCode: UInt16(kVK_ANSI_D))
    static let e = Self(keyCode: UInt16(kVK_ANSI_E))
    static let f = Self(keyCode: UInt16(kVK_ANSI_F))
    static let g = Self(keyCode: UInt16(kVK_ANSI_G))
    static let h = Self(keyCode: UInt16(kVK_ANSI_H))
    static let i = Self(keyCode: UInt16(kVK_ANSI_I))
    static let j = Self(keyCode: UInt16(kVK_ANSI_J))
    static let k = Self(keyCode: UInt16(kVK_ANSI_K))
    static let l = Self(keyCode: UInt16(kVK_ANSI_L))
    static let m = Self(keyCode: UInt16(kVK_ANSI_M))
    static let n = Self(keyCode: UInt16(kVK_ANSI_N))
    static let o = Self(keyCode: UInt16(kVK_ANSI_O))
    static let p = Self(keyCode: UInt16(kVK_ANSI_P))
    static let q = Self(keyCode: UInt16(kVK_ANSI_Q))
    static let r = Self(keyCode: UInt16(kVK_ANSI_R))
    static let s = Self(keyCode: UInt16(kVK_ANSI_S))
    static let t = Self(keyCode: UInt16(kVK_ANSI_T))
    static let u = Self(keyCode: UInt16(kVK_ANSI_U))
    static let v = Self(keyCode: UInt16(kVK_ANSI_V))
    static let w = Self(keyCode: UInt16(kVK_ANSI_W))
    static let x = Self(keyCode: UInt16(kVK_ANSI_X))
    static let y = Self(keyCode: UInt16(kVK_ANSI_Y))
    static let z = Self(keyCode: UInt16(kVK_ANSI_Z))

    static let zero = Self(keyCode: UInt16(kVK_ANSI_0))
    static let one = Self(keyCode: UInt16(kVK_ANSI_1))
    static let two = Self(keyCode: UInt16(kVK_ANSI_2))
    static let three = Self(keyCode: UInt16(kVK_ANSI_3))
    static let four = Self(keyCode: UInt16(kVK_ANSI_4))
    static let five = Self(keyCode: UInt16(kVK_ANSI_5))
    static let six = Self(keyCode: UInt16(kVK_ANSI_6))
    static let seven = Self(keyCode: UInt16(kVK_ANSI_7))
    static let eight = Self(keyCode: UInt16(kVK_ANSI_8))
    static let nine = Self(keyCode: UInt16(kVK_ANSI_9))

    static let `return` = Self(keyCode: UInt16(kVK_Return))
    static let returnKey = Self.return
    static let backslash = Self(keyCode: UInt16(kVK_ANSI_Backslash))
    static let backtick = Self(keyCode: UInt16(kVK_ANSI_Grave))
    static let comma = Self(keyCode: UInt16(kVK_ANSI_Comma))
    static let equal = Self(keyCode: UInt16(kVK_ANSI_Equal))
    static let minus = Self(keyCode: UInt16(kVK_ANSI_Minus))
    static let period = Self(keyCode: UInt16(kVK_ANSI_Period))
    static let quote = Self(keyCode: UInt16(kVK_ANSI_Quote))
    static let semicolon = Self(keyCode: UInt16(kVK_ANSI_Semicolon))
    static let slash = Self(keyCode: UInt16(kVK_ANSI_Slash))
    static let space = Self(keyCode: UInt16(kVK_Space))
    static let tab = Self(keyCode: UInt16(kVK_Tab))
    static let leftBracket = Self(keyCode: UInt16(kVK_ANSI_LeftBracket))
    static let rightBracket = Self(keyCode: UInt16(kVK_ANSI_RightBracket))

    static let isoSection = Self(keyCode: UInt16(kVK_ISO_Section))
    static let jisYen = Self(keyCode: UInt16(kVK_JIS_Yen))
    static let jisUnderscore = Self(keyCode: UInt16(kVK_JIS_Underscore))
    static let jisKeypadComma = Self(keyCode: UInt16(kVK_JIS_KeypadComma))
    static let jisEisu = Self(keyCode: UInt16(kVK_JIS_Eisu))
    static let jisKana = Self(keyCode: UInt16(kVK_JIS_Kana))

    static let pageUp = Self(keyCode: UInt16(kVK_PageUp))
    static let pageDown = Self(keyCode: UInt16(kVK_PageDown))
    static let home = Self(keyCode: UInt16(kVK_Home))
    static let end = Self(keyCode: UInt16(kVK_End))
    static let upArrow = Self(keyCode: UInt16(kVK_UpArrow))
    static let rightArrow = Self(keyCode: UInt16(kVK_RightArrow))
    static let downArrow = Self(keyCode: UInt16(kVK_DownArrow))
    static let leftArrow = Self(keyCode: UInt16(kVK_LeftArrow))
    static let escape = Self(keyCode: UInt16(kVK_Escape))
    static let delete = Self(keyCode: UInt16(kVK_Delete))
    static let deleteForward = Self(keyCode: UInt16(kVK_ForwardDelete))
    static let help = Self(keyCode: UInt16(kVK_Help))

    /// The system mute key. macOS may handle it before ShortcutKit receives it.
    static let mute = Self(keyCode: UInt16(kVK_Mute))
    /// The system volume-up key. macOS may handle it before ShortcutKit receives it.
    static let volumeUp = Self(keyCode: UInt16(kVK_VolumeUp))
    /// The system volume-down key. macOS may handle it before ShortcutKit receives it.
    static let volumeDown = Self(keyCode: UInt16(kVK_VolumeDown))

    static let f1 = Self(keyCode: UInt16(kVK_F1))
    static let f2 = Self(keyCode: UInt16(kVK_F2))
    static let f3 = Self(keyCode: UInt16(kVK_F3))
    static let f4 = Self(keyCode: UInt16(kVK_F4))
    static let f5 = Self(keyCode: UInt16(kVK_F5))
    static let f6 = Self(keyCode: UInt16(kVK_F6))
    static let f7 = Self(keyCode: UInt16(kVK_F7))
    static let f8 = Self(keyCode: UInt16(kVK_F8))
    static let f9 = Self(keyCode: UInt16(kVK_F9))
    static let f10 = Self(keyCode: UInt16(kVK_F10))
    static let f11 = Self(keyCode: UInt16(kVK_F11))
    static let f12 = Self(keyCode: UInt16(kVK_F12))
    static let f13 = Self(keyCode: UInt16(kVK_F13))
    static let f14 = Self(keyCode: UInt16(kVK_F14))
    static let f15 = Self(keyCode: UInt16(kVK_F15))
    static let f16 = Self(keyCode: UInt16(kVK_F16))
    static let f17 = Self(keyCode: UInt16(kVK_F17))
    static let f18 = Self(keyCode: UInt16(kVK_F18))
    static let f19 = Self(keyCode: UInt16(kVK_F19))
    static let f20 = Self(keyCode: UInt16(kVK_F20))

    static let keypad0 = Self(keyCode: UInt16(kVK_ANSI_Keypad0))
    static let keypad1 = Self(keyCode: UInt16(kVK_ANSI_Keypad1))
    static let keypad2 = Self(keyCode: UInt16(kVK_ANSI_Keypad2))
    static let keypad3 = Self(keyCode: UInt16(kVK_ANSI_Keypad3))
    static let keypad4 = Self(keyCode: UInt16(kVK_ANSI_Keypad4))
    static let keypad5 = Self(keyCode: UInt16(kVK_ANSI_Keypad5))
    static let keypad6 = Self(keyCode: UInt16(kVK_ANSI_Keypad6))
    static let keypad7 = Self(keyCode: UInt16(kVK_ANSI_Keypad7))
    static let keypad8 = Self(keyCode: UInt16(kVK_ANSI_Keypad8))
    static let keypad9 = Self(keyCode: UInt16(kVK_ANSI_Keypad9))
    static let keypadClear = Self(keyCode: UInt16(kVK_ANSI_KeypadClear))
    static let keypadDecimal = Self(keyCode: UInt16(kVK_ANSI_KeypadDecimal))
    static let keypadDivide = Self(keyCode: UInt16(kVK_ANSI_KeypadDivide))
    static let keypadEnter = Self(keyCode: UInt16(kVK_ANSI_KeypadEnter))
    static let keypadEquals = Self(keyCode: UInt16(kVK_ANSI_KeypadEquals))
    static let keypadMinus = Self(keyCode: UInt16(kVK_ANSI_KeypadMinus))
    static let keypadMultiply = Self(keyCode: UInt16(kVK_ANSI_KeypadMultiply))
    static let keypadPlus = Self(keyCode: UInt16(kVK_ANSI_KeypadPlus))
}
