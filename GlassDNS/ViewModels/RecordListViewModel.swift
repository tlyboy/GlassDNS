import Foundation
import Observation

@Observable
final class RecordListViewModel {
    var records: [DNSRecord] = []
    var searchText = ""
    var filterType: DNSRecordType?
    var isLoading = false
    var errorMessage: String?

    let zone: Zone
    private let provider: any DNSProvider
    @ObservationIgnored
    private var loadTask: Task<[DNSRecord], Error>?

    init(zone: Zone, provider: any DNSProvider) {
        self.zone = zone
        self.provider = provider
    }

    var filteredRecords: [DNSRecord] {
        var result = records

        if let filterType {
            result = result.filter { $0.type == filterType }
        }

        if !searchText.isEmpty {
            let query = searchText
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                || $0.content.localizedCaseInsensitiveContains(query)
            }
        }

        return result
    }

    func loadRecords(force: Bool = false) async {
        if force {
            loadTask?.cancel()
            loadTask = nil
        } else if let loadTask {
            do {
                records = try await loadTask.value
            } catch {
                if !error.isCancellation {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        isLoading = true
        errorMessage = nil
        let task = Task { try await provider.listRecords(zoneID: zone.id) }
        loadTask = task
        defer {
            loadTask = nil
            isLoading = false
            if Task.isCancelled {
                task.cancel()
            }
        }

        do {
            records = try await task.value
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteRecord(_ record: DNSRecord) async {
        do {
            try await provider.deleteRecord(zoneID: zone.id, recordID: record.id)
            records.removeAll { $0.id == record.id }
            await loadRecords(force: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
