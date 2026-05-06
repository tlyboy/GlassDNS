import Foundation
import CommonCrypto

nonisolated struct AliyunAPI: Sendable {
    private let baseURL = "https://alidns.aliyuncs.com"
    private let accessKeyId: String
    private let accessKeySecret: String
    private let apiVersion = "2015-01-09"

    init(accessKeyId: String, accessKeySecret: String) {
        self.accessKeyId = accessKeyId
        self.accessKeySecret = accessKeySecret
    }

    func request<T: Decodable & Sendable>(
        action: String,
        params: [String: String] = [:]
    ) async throws -> T {
        var allParams = commonParams(action: action)
        for (key, value) in params {
            allParams[key] = value
        }

        let signature = sign(params: allParams)
        allParams["Signature"] = signature

        let queryString = allParams
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")

        guard let url = URL(string: "\(baseURL)/?\(queryString)") else {
            throw DNSProviderError.serverError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

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

        // Aliyun can return errors with HTTP 200
        if let errorResp = try? JSONDecoder().decode(AliyunErrorResponse.self, from: data),
           let code = errorResp.code {
            let msg = errorResp.message ?? code
            if code == "InvalidAccessKeyId.NotFound" ||
               code == "SignatureDoesNotMatch" ||
               code == "IncompleteSignature" {
                throw DNSProviderError.unauthorized
            }
            throw DNSProviderError.serverError(msg)
        }

        if httpResponse.statusCode != 200 {
            throw DNSProviderError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DNSProviderError.decodingError(error)
        }
    }

    // MARK: - Signature

    private func commonParams(action: String) -> [String: String] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")

        return [
            "Action": action,
            "Version": apiVersion,
            "Format": "JSON",
            "AccessKeyId": accessKeyId,
            "SignatureMethod": "HMAC-SHA1",
            "SignatureVersion": "1.0",
            "SignatureNonce": UUID().uuidString,
            "Timestamp": formatter.string(from: Date()),
        ]
    }

    private func sign(params: [String: String]) -> String {
        let sortedQuery = params
            .sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")

        let stringToSign = "GET&\(percentEncode("/"))&\(percentEncode(sortedQuery))"
        let signingKey = "\(accessKeySecret)&"

        return hmacSHA1(key: signingKey, data: stringToSign)
    }

    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }

    private func hmacSHA1(key: String, data: String) -> String {
        let keyData = Array(key.utf8)
        let dataBytes = Array(data.utf8)
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))

        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyData, keyData.count, dataBytes, dataBytes.count, &result)

        return Data(result).base64EncodedString()
    }
}
