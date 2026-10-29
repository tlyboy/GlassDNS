import SwiftUI

struct ProviderManagementView: View {
    @Bindable var viewModel: ProviderSetupViewModel

    @State private var accountToDelete: ProviderAccount?

    var body: some View {
        List {
            ForEach(viewModel.accounts) { account in
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
            .onMove(perform: viewModel.moveAccounts)
            .onDelete { offsets in
                accountToDelete = offsets.first.map { viewModel.accounts[$0] }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Manage Providers")
        .navigationBarTitleDisplayMode(.inline)
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
                    viewModel.deleteAccount(accountToDelete)
                }
            }
        }
    }
}
