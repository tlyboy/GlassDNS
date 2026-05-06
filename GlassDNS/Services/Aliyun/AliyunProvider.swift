import Foundation

nonisolated struct AliyunProvider: DNSProvider, Sendable {
    private let api: AliyunAPI

    init(accessKeyId: String, accessKeySecret: String) {
        self.api = AliyunAPI(accessKeyId: accessKeyId, accessKeySecret: accessKeySecret)
    }

    func verifyToken() async throws -> Bool {
        let _: AliyunDomainsResponse = try await api.request(
            action: "DescribeDomains",
            params: ["PageSize": "1"]
        )
        return true
    }

    func listZones() async throws -> [Zone] {
        var allDomains: [AliyunDomain] = []
        var page = 1

        while true {
            let response: AliyunDomainsResponse = try await api.request(
                action: "DescribeDomains",
                params: [
                    "PageNumber": "\(page)",
                    "PageSize": "100",
                ]
            )

            allDomains.append(contentsOf: response.domains?.domain ?? [])

            let totalPages = max(1, (response.totalCount + response.pageSize - 1) / response.pageSize)
            if page >= totalPages { break }
            page += 1
        }

        return allDomains.map { domain in
            Zone(
                id: domain.domainName,
                name: domain.domainName,
                status: "active",
                paused: false,
                nameServers: domain.dnsServers?.dnsServer ?? [],
                originalNameServers: nil
            )
        }
    }

    func listRecords(zoneID: String) async throws -> [DNSRecord] {
        var allRecords: [AliyunRecord] = []
        var page = 1

        while true {
            let response: AliyunRecordsResponse = try await api.request(
                action: "DescribeDomainRecords",
                params: [
                    "DomainName": zoneID,
                    "PageNumber": "\(page)",
                    "PageSize": "500",
                ]
            )

            allRecords.append(contentsOf: response.domainRecords?.record ?? [])

            let totalPages = max(1, (response.totalCount + response.pageSize - 1) / response.pageSize)
            if page >= totalPages { break }
            page += 1
        }

        return allRecords.compactMap { record in
            guard let type = DNSRecordType(rawValue: record.type) else { return nil }

            let fullName = record.rr == "@"
                ? zoneID
                : "\(record.rr).\(zoneID)"

            return DNSRecord(
                id: record.recordId,
                zoneID: zoneID,
                zoneName: zoneID,
                name: fullName,
                type: type,
                content: record.value,
                ttl: record.ttl,
                proxied: nil,
                proxiable: nil,
                priority: record.priority,
                locked: record.locked,
                createdOn: nil,
                modifiedOn: nil
            )
        }
    }

    func createRecord(zoneID: String, record: DNSRecord) async throws -> DNSRecord {
        let rr = extractRR(name: record.name, domain: zoneID)

        var params: [String: String] = [
            "DomainName": zoneID,
            "RR": rr,
            "Type": record.type.rawValue,
            "Value": record.content,
            "TTL": "\(record.ttl)",
        ]

        if record.type.requiresPriority, let priority = record.priority {
            params["Priority"] = "\(priority)"
        }

        let response: AliyunRecordIdResponse = try await api.request(
            action: "AddDomainRecord",
            params: params
        )

        return DNSRecord(
            id: response.recordId,
            zoneID: zoneID,
            zoneName: zoneID,
            name: record.name,
            type: record.type,
            content: record.content,
            ttl: record.ttl,
            proxied: nil,
            proxiable: nil,
            priority: record.priority,
            locked: false,
            createdOn: nil,
            modifiedOn: nil
        )
    }

    func updateRecord(zoneID: String, recordID: String, record: DNSRecord) async throws -> DNSRecord {
        let rr = extractRR(name: record.name, domain: zoneID)

        var params: [String: String] = [
            "RecordId": recordID,
            "RR": rr,
            "Type": record.type.rawValue,
            "Value": record.content,
            "TTL": "\(record.ttl)",
        ]

        if record.type.requiresPriority, let priority = record.priority {
            params["Priority"] = "\(priority)"
        }

        let _: AliyunRecordIdResponse = try await api.request(
            action: "UpdateDomainRecord",
            params: params
        )

        return DNSRecord(
            id: recordID,
            zoneID: zoneID,
            zoneName: zoneID,
            name: record.name,
            type: record.type,
            content: record.content,
            ttl: record.ttl,
            proxied: nil,
            proxiable: nil,
            priority: record.priority,
            locked: false,
            createdOn: nil,
            modifiedOn: nil
        )
    }

    func deleteRecord(zoneID: String, recordID: String) async throws {
        let _: AliyunResponse<String> = try await api.request(
            action: "DeleteDomainRecord",
            params: ["RecordId": recordID]
        )
    }

    // MARK: - Helpers

    private func extractRR(name: String, domain: String) -> String {
        if name == domain || name == "@" { return "@" }
        let suffix = ".\(domain)"
        if name.hasSuffix(suffix) {
            return String(name.dropLast(suffix.count))
        }
        return name
    }
}
