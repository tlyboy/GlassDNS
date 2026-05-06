import SwiftUI
import Observation

@Observable
final class RecordEditViewModel {
    var name: String
    var type: DNSRecordType {
        didSet {
            syncOptionsForSelectedType()
        }
    }
    var content: String
    var ttl: Int
    var proxied: Bool
    var priority: Int

    var isSaving = false
    var errorMessage: String?
    var hasAttemptedSave = false
    private var hasEditedContentSinceTypeChange = false

    let isNewRecord: Bool
    private let record: DNSRecord
    private let zoneID: String
    private let provider: any DNSProvider

    init(record: DNSRecord, zoneID: String, provider: any DNSProvider) {
        self.record = record
        self.zoneID = zoneID
        self.provider = provider
        self.isNewRecord = record.isNew

        self.name = record.isNew ? "" : record.name
        self.type = record.type
        self.content = record.content
        self.ttl = record.ttl
        self.proxied = record.proxied ?? false
        self.priority = record.priority ?? 10
    }

    var isValid: Bool {
        !name.isEmpty && !content.isEmpty && validationErrors.isEmpty
    }

    var canAttemptSave: Bool {
        !name.isEmpty && !content.isEmpty && !isSaving
    }

    var validationErrors: [LocalizedStringResource] {
        DNSRecordValidator.validate(
            name: name,
            type: type,
            content: content,
            ttl: ttl,
            priority: priority
        )
    }

    var visibleValidationErrors: [LocalizedStringResource] {
        guard hasAttemptedSave || hasEditedContentSinceTypeChange else {
            return []
        }

        return validationErrors
    }

    func updateContent(_ newValue: String) {
        content = newValue
        hasEditedContentSinceTypeChange = true
    }

    func save() async -> DNSRecord? {
        hasAttemptedSave = true

        guard isValid else {
            return nil
        }

        isSaving = true
        errorMessage = nil

        var updated = record
        updated.name = name
        updated.type = type
        updated.content = content
        updated.ttl = ttl
        updated.proxied = type.supportsProxy ? proxied : false
        updated.priority = type.requiresPriority ? priority : nil

        do {
            let result: DNSRecord
            if isNewRecord {
                result = try await provider.createRecord(zoneID: zoneID, record: updated)
            } else {
                result = try await provider.updateRecord(zoneID: zoneID, recordID: record.id, record: updated)
            }
            isSaving = false
            return result
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return nil
        }
    }

    private func syncOptionsForSelectedType() {
        hasAttemptedSave = false
        hasEditedContentSinceTypeChange = false

        if !type.supportsProxy {
            proxied = false
        }

        if type.requiresPriority && priority < 0 {
            priority = 10
        }
    }
}
