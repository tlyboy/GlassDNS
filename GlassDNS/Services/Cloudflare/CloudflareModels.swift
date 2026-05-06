import Foundation

nonisolated struct CloudflareResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool
    let errors: [CloudflareError]
    let messages: [CloudflareMessage]
    let result: T?
    let resultInfo: ResultInfo?

    enum CodingKeys: String, CodingKey {
        case success, errors, messages, result
        case resultInfo = "result_info"
    }
}

nonisolated struct CloudflareError: Decodable, Sendable {
    let code: Int
    let message: String
}

nonisolated struct CloudflareMessage: Decodable, Sendable {
    let code: Int?
    let message: String
}

nonisolated struct ResultInfo: Decodable, Sendable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let count: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case count
        case totalCount = "total_count"
    }
}

nonisolated struct TokenVerifyResult: Decodable, Sendable {
    let id: String
    let status: String
}
