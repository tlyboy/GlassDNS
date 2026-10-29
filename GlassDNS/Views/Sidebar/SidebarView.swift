import SwiftUI

struct SidebarView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    let zoneLists: [String: ZoneListViewModel]
    @Binding var selection: ZoneSelection?

    @State private var searchText = ""
    @State private var showingAddProvider = false
    @State private var showingSettings = false
    @State private var accountToDelete: ProviderAccount?

    var body: some View {
        List(selection: $selection) {
            ForEach(providerSetupViewModel.accounts) { account in
                let zoneList = zoneLists[account.id]
                let zones = matchingZones(zoneList?.zones ?? [])
                if searchText.isEmpty || !zones.isEmpty {
                    Section {
                        if let zoneList {
                            statusRow(zoneList)
                        }
                        ForEach(zones) { zone in
                            NavigationLink(value: ZoneSelection(accountID: account.id, zone: zone)) {
                                zoneRow(zone)
                            }
                        }
                    } header: {
                        sectionHeader(account)
                    }
                }
            }

            Section {
                Button {
                    showingAddProvider = true
                } label: {
                    Label("Add Provider", systemImage: "plus.circle")
                }
            }
        }
        .overlay {
            if !searchText.isEmpty && zoneLists.values.allSatisfy({ matchingZones($0.zones).isEmpty }) {
                ContentUnavailableView("No Matching Domains", systemImage: "globe")
            }
        }
        .navigationTitle("Domains")
        .searchable(text: $searchText, prompt: "Search domains")
        .refreshable {
            await withDiscardingTaskGroup { group in
                for zoneList in zoneLists.values {
                    group.addTask { await zoneList.loadZones(force: true) }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddProvider) {
            AddProviderView(viewModel: providerSetupViewModel, isPresented: $showingAddProvider)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(providerSetupViewModel: providerSetupViewModel)
        }
    }

    private func matchingZones(_ zones: [Zone]) -> [Zone] {
        if searchText.isEmpty { return zones }
        return zones.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private func statusRow(_ zoneList: ZoneListViewModel) -> some View {
        if zoneList.isLoading && zoneList.zones.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let error = zoneList.errorMessage {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        } else if zoneList.zones.isEmpty {
            Text("No Domains")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
    }

    private func sectionHeader(_ account: ProviderAccount) -> some View {
        HStack {
            Label(account.displayName, systemImage: account.providerType.icon)

            Spacer()

            Menu {
                Button("Delete Provider", systemImage: "trash", role: .destructive) {
                    accountToDelete = account
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this provider?",
            isPresented: .init(
                get: { accountToDelete?.id == account.id },
                set: { if !$0 { accountToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                providerSetupViewModel.deleteAccount(account)
            }
        }
    }

    private func zoneRow(_ zone: Zone) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(zone.isActive ? Color.accentColor : Color.secondary)
                        .frame(width: 6, height: 6)

                    statusText(zone)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }

    private func statusText(_ zone: Zone) -> Text {
        switch zone.status {
        case "active": Text("Active")
        case "pending": Text("Pending")
        case "initializing": Text("Initializing")
        case "moved": Text("Moved")
        default: Text(zone.status.capitalized)
        }
    }
}
