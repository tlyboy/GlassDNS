import SwiftUI

nonisolated enum DNSRecordValidator {
    static func validate(
        name: String,
        type: DNSRecordType,
        content: String,
        ttl: Int,
        priority: Int
    ) -> [LocalizedStringResource] {
        var errors: [LocalizedStringResource] = []

        if name.isEmpty {
            errors.append("Name is required.")
        }

        if content.isEmpty {
            errors.append("Content is required.")
        }

        if ttl != 1 && (ttl < 60 || ttl > 86400) {
            errors.append("TTL must be 1 (Auto) or between 60-86400.")
        }

        switch type {
        case .a:
            if !isValidIPv4(content) {
                errors.append("Please enter a valid IPv4 address.")
            }
        case .aaaa:
            if !isValidIPv6(content) {
                errors.append("Please enter a valid IPv6 address.")
            }
        case .cname, .ns:
            if !isValidHostname(content) {
                errors.append("Please enter a valid hostname.")
            }
        case .mx:
            if !isValidHostname(content) {
                errors.append("Please enter a valid mail server hostname.")
            }
            if priority < 0 || priority > 65535 {
                errors.append("Priority must be between 0-65535.")
            }
        case .txt:
            if content.count > 2048 {
                errors.append("TXT record content cannot exceed 2048 characters.")
            }
        case .srv:
            if priority < 0 || priority > 65535 {
                errors.append("Priority must be between 0-65535.")
            }
        }

        return errors
    }

    private static func isValidIPv4(_ string: String) -> Bool {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part) else { return false }
            return num >= 0 && num <= 255
        }
    }

    private static func isValidIPv6(_ string: String) -> Bool {
        var sin6 = sockaddr_in6()
        return string.withCString { inet_pton(AF_INET6, $0, &sin6.sin6_addr) == 1 }
    }

    private static func isValidHostname(_ string: String) -> Bool {
        let pattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}\.?$"#
        return string.range(of: pattern, options: .regularExpression) != nil
    }
}
