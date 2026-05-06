import Foundation

nonisolated struct CloudflareAPI: Sendable {
    private let baseURL = "https://api.cloudflare.com/client/v4"
    private let token: String

    init(token: String) {
        self.token = token
    }

    func get<T: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> CloudflareResponse<T> {
        try await request(method: "GET", path: path, queryItems: queryItems)
    }

    func post<T: Decodable & Sendable, B: Encodable & Sendable>(
        path: String,
        body: B
    ) async throws -> CloudflareResponse<T> {
        try await request(method: "POST", path: path, body: body)
    }

    func put<T: Decodable & Sendable, B: Encodable & Sendable>(
        path: String,
        body: B
    ) async throws -> CloudflareResponse<T> {
        try await request(method: "PUT", path: path, body: body)
    }

    func delete(path: String) async throws {
        let _: CloudflareResponse<EmptyResult> = try await request(method: "DELETE", path: path)
    }

    func getAllPages<T: Decodable & Sendable>(
        path: String,
        perPage: Int = 50
    ) async throws -> [T] {
        var allResults: [T] = []
        var page = 1

        while true {
            let queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
            ]

            let response: CloudflareResponse<[T]> = try await get(path: path, queryItems: queryItems)

            if let results = response.result {
                allResults.append(contentsOf: results)
            }

            guard let info = response.resultInfo, page < info.totalPages else { break }
            page += 1
        }

        return allResults
    }

    private func request<T: Decodable & Sendable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable & Sendable)? = nil
    ) async throws -> CloudflareResponse<T> {
        guard var components = URLComponents(string: baseURL + path) else {
            throw DNSProviderError.serverError("Invalid URL")
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw DNSProviderError.serverError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw DNSProviderError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DNSProviderError.serverError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw DNSProviderError.unauthorized
        case 404:
            throw DNSProviderError.notFound
        case 429:
            throw DNSProviderError.rateLimited
        default:
            if let cfResponse = try? JSONDecoder().decode(CloudflareResponse<EmptyResult>.self, from: data),
               let firstError = cfResponse.errors.first {
                throw DNSProviderError.serverError(firstError.message)
            }
            throw DNSProviderError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                if let date = ISO8601DateFormatter.cloudflare.date(from: str) {
                    return date
                }
                if let date = ISO8601DateFormatter.standard.date(from: str) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }
            return try decoder.decode(CloudflareResponse<T>.self, from: data)
        } catch {
            throw DNSProviderError.decodingError(error)
        }
    }
}

private nonisolated struct EmptyResult: Decodable, Sendable {}

extension ISO8601DateFormatter {
    /// Cloudflare returns timestamps with fractional seconds: 2024-01-01T00:00:00.000000Z
    nonisolated(unsafe) static let cloudflare: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Standard ISO8601 without fractional seconds: 2024-01-01T00:00:00Z
    nonisolated(unsafe) static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
