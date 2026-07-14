import Foundation

// MARK: - Speech Engine Types

/// Speech engine types
public enum SpeechEngineType: String, CaseIterable, Sendable {
    case appleSpeech = "apple"
    case whisperKit = "whisper"
    case auto = "auto"

    public var displayName: String {
        switch self {
        case .appleSpeech: return "System Speech"
        case .whisperKit: return "WhisperKit"
        case .auto: return "Auto"
        }
    }
}

// MARK: - Speech Engine Preference

/// Speech engine preference (user setting)
public enum SpeechEnginePreference: String, CaseIterable, Sendable {
    case auto = "auto"
    case appleSpeech = "apple"
    case whisperKit = "whisper"

    public var displayName: String {
        switch self {
        case .auto: return "Auto (Recommended)"
        case .appleSpeech: return "System Speech"
        case .whisperKit: return "WhisperKit"
        }
    }
}

// MARK: - Whisper Model Sizes

/// Whisper model sizes
public enum WhisperModelSize: String, CaseIterable, Sendable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"

    public var displayName: String {
        rawValue.capitalized
    }

    public var sizeDescription: String {
        switch self {
        case .tiny: return "~39 MB"
        case .base: return "~74 MB"
        case .small: return "~244 MB"
        case .medium: return "~769 MB"
        }
    }
}
