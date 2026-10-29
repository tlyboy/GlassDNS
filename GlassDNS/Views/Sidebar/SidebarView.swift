import SwiftUI

struct SidebarView: View {
    @Bindable var providerSetupViewModel: ProviderSetupViewModel
    let zoneLists: [String: ZoneListViewModel]
    @Binding var selection: ZoneSelection?

    @State private var searchText = ""
    @State private var showingAddProvider = false
    @State private var showingSettings = false
    @State private var accountToDelete: ProviderAccount?
    @AppStorage("collapsedAccountIDs") private var collapsedAccountIDsStorage = ""

    private var collapsedAccountIDs: Set<String> {
        get { Set(collapsedAccountIDsStorage.split(separator: "\n").map(String.init)) }
        nonmutating set { collapsedAccountIDsStorage = newValue.sorted().joined(separator: "\n") }
    }

    private enum SidebarRow: Identifiable {
        case account(ProviderAccount)
        case status(ZoneListViewModel, accountID: String)
        case zone(ZoneSelection)

        var id: String {
            switch self {
            case .account(let account): "account-\(account.id)"
            case .status(_, let accountID): "status-\(accountID)"
            case .zone(let zoneSelection): "zone-\(zoneSelection.accountID)-\(zoneSelection.zone.id)"
            }
        }
    }

    private var rows: [SidebarRow] {
        providerSetupViewModel.accounts.flatMap { account -> [SidebarRow] in
            let zoneList = zoneLists[account.id]
            let zones = matchingZones(zoneList?.zones ?? [])
            guard searchText.isEmpty || !zones.isEmpty else { return [] }
            guard !collapsedAccountIDs.contains(account.id) else { return [.account(account)] }
            let status: [SidebarRow] = zoneList.map { $0.zones.isEmpty || $0.errorMessage != nil ? [.status($0, accountID: account.id)] : [] } ?? []
            return [.account(account)] + status + zones.map { .zone(ZoneSelection(accountID: account.id, zone: $0)) }
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(rows) { row in
                    switch row {
                    case .account(let account):
                        accountRow(account)
                    case .status(let zoneList, _):
                        statusRow(zoneList)
                            .moveDisabled(true)
                    case .zone(let zoneSelection):
                        NavigationLink(value: zoneSelection) {
                            zoneRow(zoneSelection.zone)
                        }
                        .moveDisabled(true)
                    }
                }
                .onMove(perform: moveAccount)
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
        .onChange(of: providerSetupViewModel.accounts.map(\.id)) { _, accountIDs in
            collapsedAccountIDs.formIntersection(accountIDs)
        }
        .sheet(isPresented: $showingAddProvider) {
            AddProviderView(viewModel: providerSetupViewModel, isPresented: $showingAddProvider)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
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

    @ViewBuilder
    private func accountRow(_ account: ProviderAccount) -> some View {
        let isCollapsed = collapsedAccountIDs.contains(account.id)
        Button {
            withAnimation {
                if isCollapsed {
                    collapsedAccountIDs.remove(account.id)
                } else {
                    collapsedAccountIDs.insert(account.id)
                }
            }
        } label: {
            HStack {
                Label(account.displayName, systemImage: account.providerType.icon)
                    .font(.headline)
                    .foregroundStyle(Color.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .moveDisabled(!searchText.isEmpty)
        .contextMenu {
            Button("Delete Provider", systemImage: "trash", role: .destructive) {
                accountToDelete = account
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

    private func moveAccount(fromOffsets source: IndexSet, toOffset destination: Int) {
        let rows = rows
        guard let index = source.first, case .account(let account) = rows[index],
              let accountIndex = providerSetupViewModel.accounts.firstIndex(of: account)
        else { return }
        let accountsBefore = rows[..<destination].count { if case .account = $0 { true } else { false } }
        providerSetupViewModel.moveAccounts(fromOffsets: [accountIndex], toOffset: accountsBefore)
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
