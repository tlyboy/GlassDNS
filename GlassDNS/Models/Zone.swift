import Foundation

nonisolated struct Zone: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let status: String
    let paused: Bool
    let nameServers: [String]
    let originalNameServers: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, status, paused
        case nameServers = "name_servers"
        case originalNameServers = "original_name_servers"
    }

    var isActive: Bool { status == "active" }
}
