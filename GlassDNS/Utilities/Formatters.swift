import SwiftUI

nonisolated enum TTLFormatter {
    static let presets: [(label: LocalizedStringResource, value: Int)] = [
        ("Auto", 1),
        ("1 min", 60),
        ("5 min", 300),
        ("10 min", 600),
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("12 hours", 43200),
        ("1 day", 86400),
    ]

    static func format(_ ttl: Int, locale: Locale = .current) -> LocalizedStringResource {
        if ttl == 1 { return "Auto" }
        if let preset = presets.first(where: { $0.value == ttl }) {
            return preset.label
        }
        if ttl < 60 { return "\(ttl) sec" }
        if ttl < 3600 { return "\(ttl / 60) min" }
        return "\(ttl / 3600) hours"
    }
}
