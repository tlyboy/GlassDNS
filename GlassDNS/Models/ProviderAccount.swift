import Foundation

nonisolated enum ProviderType: String, Codable, CaseIterable, Sendable {
    case example
    case cloudflare
    case aliyun

    var displayName: String {
        switch self {
        case .cloudflare: return "Cloudflare"
        case .aliyun: return "Alibaba Cloud DNS"
        case .example: return "Example"
        }
    }

    var icon: String {
        switch self {
        case .cloudflare: return "cloud"
        case .aliyun: return "server.rack"
        case .example: return "play.circle"
        }
    }

    /// Real provider types shown in the Add Provider picker.
    static var providerCases: [ProviderType] {
        allCases.filter { $0 != .example }
    }
}

nonisolated struct ProviderAccount: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var displayName: String
    let providerType: ProviderType
    let createdAt: Date

    static func create(displayName: String, providerType: ProviderType) -> ProviderAccount {
        ProviderAccount(
            id: UUID().uuidString,
            displayName: displayName,
            providerType: providerType,
            createdAt: .now
        )
    }
}

enum ProviderAccountStore {
    private static let key = "provider_accounts"

    static func load() -> [ProviderAccount] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ProviderAccount].self, from: data)) ?? []
    }

    static func save(_ accounts: [ProviderAccount]) {
        let data = try? JSONEncoder().encode(accounts)
        UserDefaults.standard.set(data, forKey: key)
    }
}
