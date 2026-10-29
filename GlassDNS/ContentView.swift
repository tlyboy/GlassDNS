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

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    @State private var accountToDelete: ProviderAccount?
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system
    @Environment(\.dismiss) private var dismiss

    private var activeLocale: Locale {
        appLanguage.isEmpty ? .current : Locale(identifier: appLanguage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: $appLanguage) {
                        Text("System").tag("")
                        Text("English").tag("en")
                        Text("中文").tag("zh-Hans")
                    }
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }

                if !providerSetupViewModel.accounts.isEmpty {
                    Section("Providers") {
                        ForEach(providerSetupViewModel.accounts) { account in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.displayName)
                                    Text(account.providerType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            } icon: {
                                Image(systemName: account.providerType.icon)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .onDelete { offsets in
                            accountToDelete = offsets.first.map { providerSetupViewModel.accounts[$0] }
                        }
                    }
                }
            }
            .pickerStyle(.segmented)
            .confirmationDialog(
                "Are you sure you want to delete this provider?",
                isPresented: .init(
                    get: { accountToDelete != nil },
                    set: { if !$0 { accountToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let accountToDelete {
                        providerSetupViewModel.deleteAccount(accountToDelete)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .environment(\.locale, activeLocale)
        .id(appLanguage)
    }
}
