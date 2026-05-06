import Foundation

nonisolated final class ExampleProvider: DNSProvider, @unchecked Sendable {
    private let storage = ExampleStorage()

    func verifyToken() async throws -> Bool {
        true
    }

    func listZones() async throws -> [Zone] {
        await storage.listZones()
    }

    func listRecords(zoneID: String) async throws -> [DNSRecord] {
        await storage.listRecords(zoneID: zoneID)
    }

    func createRecord(zoneID: String, record: DNSRecord) async throws -> DNSRecord {
        await storage.createRecord(zoneID: zoneID, record: record)
    }

    func updateRecord(zoneID: String, recordID: String, record: DNSRecord) async throws -> DNSRecord {
        try await storage.updateRecord(zoneID: zoneID, recordID: recordID, record: record)
    }

    func deleteRecord(zoneID: String, recordID: String) async throws {
        try await storage.deleteRecord(zoneID: zoneID, recordID: recordID)
    }
}

private actor ExampleStorage {
    private var zones: [Zone]
    private var records: [String: [DNSRecord]]

    init() {
        let zone1 = Zone(
            id: "example-zone-1",
            name: "example.com",
            status: "active",
            paused: false,
            nameServers: ["ns1.example.com", "ns2.example.com"],
            originalNameServers: nil
        )
        let zone2 = Zone(
            id: "example-zone-2",
            name: "example.org",
            status: "active",
            paused: false,
            nameServers: ["ns1.example.org", "ns2.example.org"],
            originalNameServers: nil
        )
        self.zones = [zone1, zone2]

        let now = Date()
        self.records = [
            "example-zone-1": [
                DNSRecord(
                    id: "ex-r-1", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "example.com", type: .a, content: "93.184.216.34", ttl: 300,
                    proxied: false, proxiable: true, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-2", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "example.com", type: .aaaa, content: "2606:2800:220:1:248:1893:25c8:1946", ttl: 300,
                    proxied: false, proxiable: true, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-3", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "www.example.com", type: .cname, content: "example.com", ttl: 300,
                    proxied: false, proxiable: true, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-4", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "example.com", type: .mx, content: "mail.example.com", ttl: 3600,
                    proxied: nil, proxiable: nil, priority: 10, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-5", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "example.com", type: .txt, content: "v=spf1 include:_spf.example.com ~all", ttl: 3600,
                    proxied: nil, proxiable: nil, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-6", zoneID: "example-zone-1", zoneName: "example.com",
                    name: "example.com", type: .ns, content: "ns1.example.com", ttl: 86400,
                    proxied: nil, proxiable: nil, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
            ],
            "example-zone-2": [
                DNSRecord(
                    id: "ex-r-7", zoneID: "example-zone-2", zoneName: "example.org",
                    name: "example.org", type: .a, content: "198.51.100.1", ttl: 1,
                    proxied: true, proxiable: true, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-8", zoneID: "example-zone-2", zoneName: "example.org",
                    name: "api.example.org", type: .a, content: "198.51.100.2", ttl: 60,
                    proxied: false, proxiable: true, priority: nil, locked: false,
                    createdOn: now, modifiedOn: now
                ),
                DNSRecord(
                    id: "ex-r-9", zoneID: "example-zone-2", zoneName: "example.org",
                    name: "_sip._tcp.example.org", type: .srv, content: "sip.example.org", ttl: 3600,
                    proxied: nil, proxiable: nil, priority: 5, locked: false,
                    createdOn: now, modifiedOn: now
                ),
            ],
        ]
    }

    func listZones() -> [Zone] {
        zones
    }

    func listRecords(zoneID: String) -> [DNSRecord] {
        records[zoneID] ?? []
    }

    func createRecord(zoneID: String, record: DNSRecord) -> DNSRecord {
        let newRecord = DNSRecord(
            id: UUID().uuidString,
            zoneID: record.zoneID, zoneName: record.zoneName,
            name: record.name, type: record.type, content: record.content,
            ttl: record.ttl, proxied: record.proxied, proxiable: record.proxiable,
            priority: record.priority, locked: false,
            createdOn: Date(), modifiedOn: Date()
        )
        records[zoneID, default: []].append(newRecord)
        return newRecord
    }

    func updateRecord(zoneID: String, recordID: String, record: DNSRecord) throws -> DNSRecord {
        guard var zoneRecords = records[zoneID],
              let index = zoneRecords.firstIndex(where: { $0.id == recordID }) else {
            throw DNSProviderError.notFound
        }
        let updated = DNSRecord(
            id: recordID,
            zoneID: record.zoneID, zoneName: record.zoneName,
            name: record.name, type: record.type, content: record.content,
            ttl: record.ttl, proxied: record.proxied, proxiable: record.proxiable,
            priority: record.priority, locked: record.locked,
            createdOn: zoneRecords[index].createdOn, modifiedOn: Date()
        )
        zoneRecords[index] = updated
        records[zoneID] = zoneRecords
        return updated
    }

    func deleteRecord(zoneID: String, recordID: String) throws {
        guard var zoneRecords = records[zoneID],
              zoneRecords.contains(where: { $0.id == recordID }) else {
            throw DNSProviderError.notFound
        }
        zoneRecords.removeAll { $0.id == recordID }
        records[zoneID] = zoneRecords
    }
}
