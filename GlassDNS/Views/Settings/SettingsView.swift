import SwiftUI

struct SettingsView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    @State private var accountToDelete: ProviderAccount?
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system

    var body: some View {
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
                        SubtitleLabel(
                            title: Text(account.displayName),
                            subtitle: Text(LocalizedStringKey(account.providerType.displayName)),
                            systemImage: account.providerType.icon
                        )
                        .contextMenu {
                            // A context menu takes over the long press that starts a drag on touch screens.
                            if ProcessInfo.processInfo.isiOSAppOnMac {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    accountToDelete = account
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .onMove(perform: providerSetupViewModel.moveAccounts)
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
    }
}

struct SettingsButton: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    @State private var isPresented = false
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            isPresented = true
        } label: {
            label
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                SettingsView(providerSetupViewModel: providerSetupViewModel)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isPresented = false }
                        }
                    }
            }
            .preferredColorScheme(appearance.colorScheme ?? colorScheme)
            .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
            .id(appLanguage)
        }
    }

    private var label: some View {
        Label("Settings", systemImage: "gearshape")
    }
}
