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
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(Color.appAccent)
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .foregroundStyle(Color.appAccent)
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
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
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
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground.ignoresSafeArea())
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
            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    ForEach(providerSetupViewModel.accounts) { account in
                        Button {
                            onSelectAccount(account)
                        } label: {
                            accountRow(account)
                        }
                    }

                    if providerSetupViewModel.accounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                            Text("No Providers")
                                .font(.headline)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("DNS Providers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.appAccent)
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
                .foregroundStyle(Color.appAccent)
                .frame(width: 44, height: 44)
                .background(Color.appAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.appText)

                Text(account.providerType.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Button {
                accountToDelete = account
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(Color.appDanger)
                    .frame(width: 36, height: 36)
            }
        }
        .glassCard()
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @Environment(\.dismiss) private var dismiss

    private var activeLocale: Locale {
        appLanguage.isEmpty ? .current : Locale(identifier: appLanguage)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Language")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)

                        HStack(spacing: 8) {
                            LanguageButton(label: "System", isSelected: appLanguage.isEmpty) {
                                appLanguage = ""
                            }
                            LanguageButton(label: "English", isSelected: appLanguage == "en") {
                                appLanguage = "en"
                            }
                            LanguageButton(label: "中文", isSelected: appLanguage == "zh-Hans") {
                                appLanguage = "zh-Hans"
                            }
                        }
                    }
                    .glassCard()
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .environment(\.locale, activeLocale)
        .id(appLanguage)
    }
}

private struct LanguageButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.appAccent.opacity(0.2) : Color.white.opacity(0.05))
                .foregroundStyle(isSelected ? Color.appAccent : Color.appTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.appAccent.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
