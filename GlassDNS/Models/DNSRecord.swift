import Foundation

nonisolated struct DNSRecord: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let zoneID: String?
    let zoneName: String?
    var name: String
    var type: DNSRecordType
    var content: String
    var ttl: Int
    var proxied: Bool?
    let proxiable: Bool?
    var priority: Int?
    let locked: Bool?
    let createdOn: Date?
    let modifiedOn: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case zoneID = "zone_id"
        case zoneName = "zone_name"
        case name, type, content, ttl, proxied, proxiable, priority, locked
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }

    static func new(zoneID: String, zoneName: String) -> DNSRecord {
        DNSRecord(
            id: "",
            zoneID: zoneID,
            zoneName: zoneName,
            name: "",
            type: .a,
            content: "",
            ttl: 1,
            proxied: false,
            proxiable: true,
            priority: nil,
            locked: false,
            createdOn: nil,
            modifiedOn: nil
        )
    }

    var isNew: Bool { id.isEmpty }

    var isProxied: Bool { proxied ?? false }

    var isLocked: Bool { locked ?? false }

    var displayTTL: String {
        if ttl == 1 { return "Auto" }
        if ttl < 60 { return "\(ttl)s" }
        if ttl < 3600 { return "\(ttl / 60)m" }
        return "\(ttl / 3600)h"
    }
}
