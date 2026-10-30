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
                        .contextMenu {
                            Button(role: .destructive) {
                                accountToDelete = account
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
    }
}

#if os(iOS)
struct SettingsButton: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    @State private var isPresented = false
    @AppStorage("appLanguage") private var appLanguage: String = ""

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Settings", systemImage: "gearshape")
                .foregroundStyle(Color.accentColor)
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                SettingsView(providerSetupViewModel: providerSetupViewModel)
                    .navigationTitle("Settings")
                    .inlineNavigationTitle()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isPresented = false }
                                .foregroundStyle(Color.secondary)
                        }
                    }
            }
            .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
            .id(appLanguage)
        }
    }
}
#endif
