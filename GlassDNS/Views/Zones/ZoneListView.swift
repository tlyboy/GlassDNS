import SwiftUI

struct ZoneListView: View {
    @Bindable var viewModel: ZoneListViewModel

    var body: some View {
        List(viewModel.filteredZones) { zone in
            NavigationLink(value: zone) {
                zoneRow(zone)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.zones.isEmpty {
                ProgressView()
            } else if viewModel.filteredZones.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No Domains" : "No Matching Domains",
                    systemImage: "globe"
                )
            }
        }
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

                    Text(zone.isActive ? "Active" : zone.status.capitalized)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }

        }
    }
}
