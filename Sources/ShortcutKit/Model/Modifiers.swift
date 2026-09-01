/// A set of supported keyboard modifiers.
public struct Modifiers: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let command = Modifiers(rawValue: 1 << 0)
    public static let option = Modifiers(rawValue: 1 << 1)
    public static let control = Modifiers(rawValue: 1 << 2)
    public static let shift = Modifiers(rawValue: 1 << 3)
    public static let all: Modifiers = [.command, .option, .control, .shift]

    public var isEmpty: Bool {
        rawValue == 0
    }
}

extension Modifiers {
    init(_ modifier: Modifier) {
        switch modifier {
        case .command: self = .command
        case .option: self = .option
        case .control: self = .control
        case .shift: self = .shift
        }
    }
}
