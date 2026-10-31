import Foundation

nonisolated enum DNSRecordType: String, Codable, CaseIterable, Identifiable, Sendable {
    case a = "A"
    case aaaa = "AAAA"
    case cname = "CNAME"
    case mx = "MX"
    case txt = "TXT"
    case ns = "NS"
    case srv = "SRV"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .a, .aaaa: return "network"
        case .cname: return "arrow.triangle.branch"
        case .mx: return "envelope"
        case .txt: return "doc.text"
        case .ns: return "server.rack"
        case .srv: return "gearshape.2"
        }
    }

    var supportsProxy: Bool {
        switch self {
        case .a, .aaaa, .cname: return true
        default: return false
        }
    }

    var requiresPriority: Bool {
        switch self {
        case .mx, .srv: return true
        default: return false
        }
    }
}
