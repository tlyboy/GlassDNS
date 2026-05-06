import Foundation
import Observation

@Observable
final class ZoneListViewModel {
    var zones: [Zone] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let provider: any DNSProvider
    @ObservationIgnored
    private var loadTask: Task<[Zone], Error>?

    init(provider: any DNSProvider) {
        self.provider = provider
    }

    var filteredZones: [Zone] {
        if searchText.isEmpty { return zones }
        return zones.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadZones(force: Bool = false) async {
        if force {
            loadTask?.cancel()
            loadTask = nil
        } else if let loadTask {
            do {
                zones = try await loadTask.value
            } catch {
                if !error.isCancellation {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        isLoading = true
        errorMessage = nil
        let task = Task { try await provider.listZones() }
        loadTask = task
        defer {
            loadTask = nil
            isLoading = false
            if Task.isCancelled {
                task.cancel()
            }
        }

        do {
            zones = try await task.value
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }
}
