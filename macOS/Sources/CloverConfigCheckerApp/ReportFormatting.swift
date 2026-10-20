import SwiftUI

enum CloverTheme {
    static let background = adaptive(light: 0xEDF5ED, dark: 0x102219)
    static let surface = adaptive(light: 0xF8FCF7, dark: 0x162F22)
    static let text = adaptive(light: 0x205C30, dark: 0xB1E7B0)
    static let secondary = adaptive(light: 0x46694B, dark: 0x92B69A)
    static let accent = adaptive(light: 0x237738, dark: 0x8DDD84)
    static let warning = adaptive(light: 0x855300, dark: 0xFFD66B)
    static let note = adaptive(light: 0x006A82, dark: 0x78D9EF)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255,
                alpha: 1
            )
        })
    }
}

enum ReportTone: Equatable {
    case normal, error, warning, note, success, secondary

    var color: Color {
        switch self {
        case .normal: return CloverTheme.text
        case .error: return .red
        case .warning: return CloverTheme.warning
        case .note: return CloverTheme.note
        case .success: return CloverTheme.accent
        case .secondary: return CloverTheme.secondary
        }
    }
}

enum ReportFormatting {
    static func tone(for line: String) -> ReportTone {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("ERROR:") || text.hasPrefix("Error:")
            || text.hasPrefix("Result: INVALID") {
            return .error
        }
        if text.hasPrefix("WARNING:") || text.hasPrefix("Result: VALID with warnings") {
            return .warning
        }
        if text.hasPrefix("NOTE:") { return .note }
        if text.hasPrefix("Result: VALID") { return .success }
        if text.hasPrefix("Summary:") {
            return text == "Summary: 0 errors, 0 warnings, 0 notes" ? .success : .normal
        }
        if line.hasPrefix("  "), text.contains(":") {
            if text.contains(" -- ") {
                let detail = text.components(separatedBy: " -- ").dropFirst().joined(separator: " -- ")
                if detail.contains("error") { return .error }
                if detail.contains("warning") { return .warning }
                if detail.contains("note") { return .note }
            }
            if text.hasSuffix(" verified") { return .success }
            return .secondary
        }
        if text.hasPrefix("Validating ") || text == "Verified sections:" {
            return .secondary
        }
        return .normal
    }

    static func attributed(_ output: String) -> AttributedString {
        var result = AttributedString()
        let lines = output.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            var fragment = AttributedString(line + (index < lines.count - 1 ? "\n" : ""))
            fragment.foregroundColor = tone(for: line).color
            if line.hasPrefix("ERROR:") || line.hasPrefix("Result:") {
                fragment.font = .system(.body, design: .monospaced).bold()
            }
            result.append(fragment)
        }
        return result
    }
}
