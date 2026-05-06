import Foundation

// MARK: - Common Response

nonisolated struct AliyunResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
    }
}

nonisolated struct AliyunErrorResponse: Decodable, Sendable {
    let requestId: String?
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case code = "Code"
        case message = "Message"
    }
}

// MARK: - Domains

nonisolated struct AliyunDomainsResponse: Decodable, Sendable {
    let requestId: String
    let totalCount: Int
    let pageNumber: Int
    let pageSize: Int
    let domains: AliyunDomainList?

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case totalCount = "TotalCount"
        case pageNumber = "PageNumber"
        case pageSize = "PageSize"
        case domains = "Domains"
    }
}

nonisolated struct AliyunDomainList: Decodable, Sendable {
    let domain: [AliyunDomain]

    enum CodingKeys: String, CodingKey {
        case domain = "Domain"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = (try? container.decode([AliyunDomain].self, forKey: .domain)) ?? []
    }
}

nonisolated struct AliyunDomain: Decodable, Sendable {
    let domainId: String?
    let domainName: String
    let dnsServers: AliyunDnsServers?

    enum CodingKeys: String, CodingKey {
        case domainId = "DomainId"
        case domainName = "DomainName"
        case dnsServers = "DnsServers"
    }
}

nonisolated struct AliyunDnsServers: Decodable, Sendable {
    let dnsServer: [String]

    enum CodingKeys: String, CodingKey {
        case dnsServer = "DnsServer"
    }
}

// MARK: - Records

nonisolated struct AliyunRecordsResponse: Decodable, Sendable {
    let requestId: String
    let totalCount: Int
    let pageNumber: Int
    let pageSize: Int
    let domainRecords: AliyunRecordList?

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case totalCount = "TotalCount"
        case pageNumber = "PageNumber"
        case pageSize = "PageSize"
        case domainRecords = "DomainRecords"
    }
}

nonisolated struct AliyunRecordList: Decodable, Sendable {
    let record: [AliyunRecord]

    enum CodingKeys: String, CodingKey {
        case record = "Record"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.record = (try? container.decode([AliyunRecord].self, forKey: .record)) ?? []
    }
}

nonisolated struct AliyunRecord: Decodable, Sendable {
    let recordId: String
    let type: String
    let rr: String
    let value: String
    let ttl: Int
    let priority: Int?
    let line: String?
    let status: String?
    let locked: Bool?
    let domainName: String?

    enum CodingKeys: String, CodingKey {
        case recordId = "RecordId"
        case type = "Type"
        case rr = "RR"
        case value = "Value"
        case ttl = "TTL"
        case priority = "Priority"
        case line = "Line"
        case status = "Status"
        case locked = "Locked"
        case domainName = "DomainName"
    }
}

// MARK: - Add/Update Response

nonisolated struct AliyunRecordIdResponse: Decodable, Sendable {
    let requestId: String
    let recordId: String

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case recordId = "RecordId"
    }
}
