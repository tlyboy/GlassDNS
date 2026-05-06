import Foundation

nonisolated struct CloudflareProvider: DNSProvider, Sendable {
    private let api: CloudflareAPI

    init(token: String) {
        self.api = CloudflareAPI(token: token)
    }

    func verifyToken() async throws -> Bool {
        let response: CloudflareResponse<TokenVerifyResult> = try await api.get(
            path: "/user/tokens/verify"
        )
        return response.success && response.result?.status == "active"
    }

    func listZones() async throws -> [Zone] {
        try await api.getAllPages(path: "/zones")
    }

    func listRecords(zoneID: String) async throws -> [DNSRecord] {
        try await api.getAllPages(path: "/zones/\(zoneID)/dns_records")
    }

    func createRecord(zoneID: String, record: DNSRecord) async throws -> DNSRecord {
        let body = RecordBody(record: record)
        let response: CloudflareResponse<DNSRecord> = try await api.post(
            path: "/zones/\(zoneID)/dns_records",
            body: body
        )
        guard let result = response.result else {
            let message = response.errors.first?.message ?? "Unknown error"
            throw DNSProviderError.serverError(message)
        }
        return result
    }

    func updateRecord(zoneID: String, recordID: String, record: DNSRecord) async throws -> DNSRecord {
        let body = RecordBody(record: record)
        let response: CloudflareResponse<DNSRecord> = try await api.put(
            path: "/zones/\(zoneID)/dns_records/\(recordID)",
            body: body
        )
        guard let result = response.result else {
            let message = response.errors.first?.message ?? "Unknown error"
            throw DNSProviderError.serverError(message)
        }
        return result
    }

    func deleteRecord(zoneID: String, recordID: String) async throws {
        try await api.delete(path: "/zones/\(zoneID)/dns_records/\(recordID)")
    }
}

private nonisolated struct RecordBody: Encodable, Sendable {
    let type: String
    let name: String
    let content: String
    let ttl: Int
    let proxied: Bool
    let priority: Int?

    init(record: DNSRecord) {
        self.type = record.type.rawValue
        self.name = record.name
        self.content = record.content
        self.ttl = record.ttl
        self.proxied = record.type.supportsProxy ? (record.proxied ?? false) : false
        self.priority = record.type.requiresPriority ? record.priority : nil
    }
}
