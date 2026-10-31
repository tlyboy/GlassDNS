import SwiftUI

struct SidebarView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    let zoneLists: [String: ZoneListViewModel]
    @Binding var selection: ZoneSelection?

    @State private var searchText = ""
    @State private var showingAddProvider = false
    @AppStorage("collapsedAccountIDs") private var collapsedAccountIDsStorage = ""

    private var collapsedAccountIDs: Set<String> {
        get { Set(collapsedAccountIDsStorage.split(separator: "\n").map(String.init)) }
        nonmutating set { collapsedAccountIDsStorage = newValue.sorted().joined(separator: "\n") }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(providerSetupViewModel.accounts) { account in
                let zoneList = zoneLists[account.id]
                let zones = matchingZones(zoneList?.zones ?? [])
                if searchText.isEmpty || !zones.isEmpty {
                    Section(isExpanded: isExpanded(account)) {
                        if let zoneList {
                            statusRow(zoneList)
                        }
                        ForEach(zones) { zone in
                            NavigationLink(value: ZoneSelection(accountID: account.id, zone: zone)) {
                                zoneRow(zone)
                            }
                        }
                    } header: {
                        sectionHeader(account, isLoading: zoneList.map { $0.isLoading && $0.zones.isEmpty } ?? false)
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
        .listStyle(.sidebar)
        .tint(Color(.systemGray4))
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
            ToolbarItem(placement: .primaryAction) {
                SettingsButton(providerSetupViewModel: providerSetupViewModel)
            }
        }
        .onChange(of: providerSetupViewModel.accounts.map(\.id)) { _, accountIDs in
            collapsedAccountIDs.formIntersection(accountIDs)
        }
        .sheet(isPresented: $showingAddProvider) {
            AddProviderView(viewModel: providerSetupViewModel, isPresented: $showingAddProvider)
        }
    }

    private func matchingZones(_ zones: [Zone]) -> [Zone] {
        if searchText.isEmpty { return zones }
        return zones.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private func statusRow(_ zoneList: ZoneListViewModel) -> some View {
        if zoneList.isLoading {
            EmptyView()
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

    private func isExpanded(_ account: ProviderAccount) -> Binding<Bool> {
        Binding(
            get: { !searchText.isEmpty || !collapsedAccountIDs.contains(account.id) },
            set: { isExpanded in
                if isExpanded {
                    collapsedAccountIDs.remove(account.id)
                } else {
                    collapsedAccountIDs.insert(account.id)
                }
            }
        )
    }

    private func sectionHeader(_ account: ProviderAccount, isLoading: Bool) -> some View {
        HStack {
            Label(account.displayName, systemImage: account.providerType.icon)
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func zoneRow(_ zone: Zone) -> some View {
        SubtitleLabel(
            title: Text(zone.name),
            subtitle: zone.isActive ? nil : statusText(zone),
            systemImage: "globe"
        )
    }

    private func statusText(_ zone: Zone) -> Text {
        switch zone.status {
        case "pending": Text("Pending")
        case "initializing": Text("Initializing")
        case "moved": Text("Moved")
        default: Text(zone.status.capitalized)
        }
    }
}
