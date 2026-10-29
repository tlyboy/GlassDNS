import SwiftUI

struct ContentView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel

    @State private var activeAccountID: String?
    @State private var activeProvider: (any DNSProvider)?
    @State private var zoneListViewModel: ZoneListViewModel?
    @State private var loadTask: Task<Void, Never>?
    @State private var showingProviderManager = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let zoneListViewModel {
                    ZoneListView(viewModel: zoneListViewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showingProviderManager = true
                                } label: {
                                    Label("DNS Providers", systemImage: "server.rack")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                } else {
                    ProviderSetupView(viewModel: providerSetupViewModel)
                }
            }
            .navigationDestination(for: Zone.self) { zone in
                if let provider = activeProvider {
                    RecordListScreen(zone: zone, provider: provider)
                }
            }
        }
        .sheet(isPresented: $showingProviderManager) {
            ProviderManagerSheet(
                providerSetupViewModel: providerSetupViewModel,
                onSelectAccount: { account in
                    activateAccount(account)
                    showingProviderManager = false
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .onChange(of: providerSetupViewModel.accounts) {
            if providerSetupViewModel.accounts.isEmpty {
                deactivate()
            } else if let id = activeAccountID,
                      !providerSetupViewModel.accounts.contains(where: { $0.id == id }) {
                // Active provider was deleted, switch to first available
                if let first = providerSetupViewModel.accounts.first {
                    activateAccount(first)
                } else {
                    deactivate()
                }
            } else if zoneListViewModel == nil {
                if let first = providerSetupViewModel.accounts.first {
                    activateAccount(first)
                }
            }
        }
        .onAppear {
            if let first = providerSetupViewModel.accounts.first, zoneListViewModel == nil {
                activateAccount(first)
            }
        }
    }

    private func activateAccount(_ account: ProviderAccount) {
        guard let provider = providerSetupViewModel.providerFor(account: account) else { return }
        loadTask?.cancel()
        activeAccountID = account.id
        activeProvider = provider
        let vm = ZoneListViewModel(provider: provider)
        zoneListViewModel = vm
        loadTask = Task { await vm.loadZones() }
    }

    private func deactivate() {
        loadTask?.cancel()
        activeAccountID = nil
        activeProvider = nil
        zoneListViewModel = nil
    }
}

// MARK: - Record List Screen (owns its own ViewModel)

struct RecordListScreen: View {
    let zone: Zone
    let provider: any DNSProvider

    @State private var viewModel: RecordListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                RecordListView(viewModel: viewModel, provider: provider)
            } else {
                ProgressView()
            }
        }
        .navigationDestination(for: DNSRecord.self) { record in
            if let viewModel {
                RecordDetailView(record: record, zoneID: zone.id, provider: provider) {
                    Task { await viewModel.loadRecords(force: true) }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RecordListViewModel(zone: zone, provider: provider)
            }
        }
    }
}

// MARK: - Provider Manager Sheet

struct ProviderManagerSheet: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    var onSelectAccount: (ProviderAccount) -> Void

    @State private var showingAddSheet = false
    @State private var accountToDelete: ProviderAccount?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(providerSetupViewModel.accounts) { account in
                Button {
                    onSelectAccount(account)
                } label: {
                    accountRow(account)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        accountToDelete = account
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .overlay {
                if providerSetupViewModel.accounts.isEmpty {
                    ContentUnavailableView("No Providers", systemImage: "cloud.fill")
                }
            }
            .navigationTitle("DNS Providers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Provider", systemImage: "plus")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddProviderView(viewModel: providerSetupViewModel, isPresented: $showingAddSheet)
            }
            .confirmationDialog(
                "Are you sure you want to delete this provider?",
                isPresented: .init(
                    get: { accountToDelete != nil },
                    set: { if !$0 { accountToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete {
                        providerSetupViewModel.deleteAccount(account)
                    }
                }
            }
        }
    }

    private func accountRow(_ account: ProviderAccount) -> some View {
        HStack(spacing: 14) {
            Image(systemName: account.providerType.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text(account.providerType.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

        }
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
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
            }
            .pickerStyle(.segmented)
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
