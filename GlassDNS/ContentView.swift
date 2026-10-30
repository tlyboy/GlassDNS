import SwiftUI

struct ZoneSelection: Hashable {
    let accountID: String
    let zone: Zone
}

struct ContentView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel

    @State private var selectedZone: ZoneSelection?
    @State private var selectedRecordID: DNSRecord.ID?
    @State private var zoneLists: [String: ZoneListViewModel] = [:]
    @State private var recordList: RecordListViewModel?
    @State private var hasRecordChanges = false

    var body: some View {
        Group {
            if providerSetupViewModel.accounts.isEmpty {
                NavigationStack {
                    ProviderSetupView(viewModel: providerSetupViewModel)
                }
            } else {
                NavigationSplitView {
                    SidebarView(
                        providerSetupViewModel: providerSetupViewModel,
                        zoneLists: zoneLists,
                        selection: $selectedZone
                    )
                    .disabled(hasRecordChanges)
                } content: {
                    if let recordList {
                        RecordListView(viewModel: recordList, selection: $selectedRecordID)
                            .id(ObjectIdentifier(recordList))
                            .disabled(hasRecordChanges)
                    } else {
                        ContentUnavailableView("Select a domain", systemImage: "globe")
                    }
                } detail: {
                    if let recordList, let record = recordList.records.first(where: { $0.id == selectedRecordID }) {
                        RecordView(
                            record: record,
                            zoneID: recordList.zone.id,
                            provider: recordList.provider,
                            hasChanges: $hasRecordChanges
                        ) { _ in
                            Task { await recordList.loadRecords(force: true) }
                        }
                        .id(record.id)
                    } else {
                        ContentUnavailableView("Select a record", systemImage: "doc.text")
                    }
                }
            }
        }
        .onChange(of: providerSetupViewModel.accounts, initial: true) {
            syncZoneLists()
        }
        .onChange(of: selectedZone) {
            selectedRecordID = nil
            recordList = makeRecordList()
        }
    }

    private func syncZoneLists() {
        let accounts = providerSetupViewModel.accounts
        let accountIDs = Set(accounts.map(\.id))
        zoneLists = zoneLists.filter { accountIDs.contains($0.key) }
        for account in accounts where zoneLists[account.id] == nil {
            guard let provider = providerSetupViewModel.providerFor(account: account) else { continue }
            let zoneList = ZoneListViewModel(provider: provider)
            zoneLists[account.id] = zoneList
            Task { await zoneList.loadZones() }
        }
        if let selectedZone, !accountIDs.contains(selectedZone.accountID) {
            self.selectedZone = nil
        }
    }

    private func makeRecordList() -> RecordListViewModel? {
        guard let selectedZone, let zoneList = zoneLists[selectedZone.accountID] else { return nil }
        return RecordListViewModel(zone: selectedZone.zone, provider: zoneList.provider)
    }
}
