/// A supported keyboard modifier.
public enum Modifier: String, Hashable, Codable, Sendable, CaseIterable {
    case command
    case option
    case control
    case shift
}
