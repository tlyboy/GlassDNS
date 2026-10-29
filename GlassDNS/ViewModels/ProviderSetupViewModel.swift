import Foundation
import Observation

@Observable
final class ProviderSetupViewModel {
    var accounts: [ProviderAccount] = []
    var isLoading = false
    var errorMessage: String?

    init() {
        accounts = ProviderAccountStore.load()
    }

    func addAccount(displayName: String, providerType: ProviderType, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        if providerType == .example {
            let account = ProviderAccount.create(
                displayName: displayName.isEmpty ? "Example" : displayName,
                providerType: .example
            )
            accounts.append(account)
            ProviderAccountStore.save(accounts)
            isLoading = false
            return true
        }

        do {
            guard let provider = createProvider(type: providerType, token: token) else {
                errorMessage = String(localized: "Invalid credentials format.")
                isLoading = false
                return false
            }
            let isValid = try await provider.verifyToken()

            guard isValid else {
                errorMessage = String(localized: "Token verification failed. Please check permissions.")
                isLoading = false
                return false
            }

            let account = ProviderAccount.create(displayName: displayName, providerType: providerType)
            try KeychainService.save(token: token, forAccountID: account.id)
            accounts.append(account)
            ProviderAccountStore.save(accounts)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deleteAccount(_ account: ProviderAccount) {
        if account.providerType != .example {
            KeychainService.delete(forAccountID: account.id)
        }
        accounts.removeAll { $0.id == account.id }
        ProviderAccountStore.save(accounts)
    }

    func providerFor(account: ProviderAccount) -> (any DNSProvider)? {
        if account.providerType == .example {
            return ExampleProvider()
        }
        guard let token = KeychainService.retrieve(forAccountID: account.id) else { return nil }
        return createProvider(type: account.providerType, token: token)
    }

    private func createProvider(type: ProviderType, token: String) -> (any DNSProvider)? {
        switch type {
        case .cloudflare:
            return CloudflareProvider(token: token)
        case .aliyun:
            let parts = token.split(separator: "\n", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return AliyunProvider(
                accessKeyId: String(parts[0]),
                accessKeySecret: String(parts[1])
            )
        case .example:
            return ExampleProvider()
        }
    }

    /// Pack Aliyun credentials into a single string for Keychain storage
    static func packAliyunCredentials(accessKeyId: String, accessKeySecret: String) -> String {
        "\(accessKeyId)\n\(accessKeySecret)"
    }
}
