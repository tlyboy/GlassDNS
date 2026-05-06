import Foundation

nonisolated enum DNSProviderError: LocalizedError, Sendable {
    case unauthorized
    case notFound
    case rateLimited
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return String(localized: "Authentication failed. Please check your API Token.")
        case .notFound:
            return String(localized: "The requested resource was not found.")
        case .rateLimited:
            return String(localized: "Too many requests. Please try again later.")
        case .serverError(let message):
            return String(localized: "Server error: \(message)")
        case .networkError:
            return String(localized: "Network connection failed. Please check your network settings.")
        case .decodingError:
            return String(localized: "The server returned data that could not be parsed.")
        case .validationError(let message):
            return String(localized: "Validation error: \(message)")
        }
    }
}

extension Error {
    nonisolated var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        if let providerError = self as? DNSProviderError,
           case .networkError(let inner) = providerError {
            return inner.isCancellation
        }
        return false
    }
}

nonisolated protocol DNSProvider: Sendable {
    func verifyToken() async throws -> Bool
    func listZones() async throws -> [Zone]
    func listRecords(zoneID: String) async throws -> [DNSRecord]
    func createRecord(zoneID: String, record: DNSRecord) async throws -> DNSRecord
    func updateRecord(zoneID: String, recordID: String, record: DNSRecord) async throws -> DNSRecord
    func deleteRecord(zoneID: String, recordID: String) async throws
}
