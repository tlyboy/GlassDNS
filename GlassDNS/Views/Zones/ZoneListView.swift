import SwiftUI

struct ZoneListView: View {
    @Bindable var viewModel: ZoneListViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacing) {
                if viewModel.isLoading && viewModel.zones.isEmpty {
                    LoadingView()
                } else if viewModel.filteredZones.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.filteredZones) { zone in
                        NavigationLink(value: zone) {
                            zoneRow(zone)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, AppTheme.spacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Domains")
        .searchable(text: $viewModel.searchText, prompt: "Search domains")
        .refreshable {
            await viewModel.loadZones(force: true)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            Task { await viewModel.loadZones() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundStyle(Color.appTextSecondary.opacity(0.5))

            Text(viewModel.searchText.isEmpty ? "No Domains" : "No Matching Domains")
                .font(.headline)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.top, 60)
    }

    private func zoneRow(_ zone: Zone) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
                .frame(width: 40, height: 40)
                .background(Color.appAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundStyle(Color.appText)

                HStack(spacing: 6) {
                    Circle()
                        .fill(zone.isActive ? Color.appAccent : Color.appTextSecondary)
                        .frame(width: 6, height: 6)

                    Text(zone.isActive ? "Active" : zone.status.capitalized)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
        }
        .glassCard()
    }
}
