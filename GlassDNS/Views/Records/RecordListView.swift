import SwiftUI

struct RecordListView: View {
    @Bindable var viewModel: RecordListViewModel
    let provider: any DNSProvider
    @State private var showingAddRecord = false
    @State private var recordToDelete: DNSRecord?

    var body: some View {
        List(viewModel.filteredRecords) { record in
            NavigationLink(value: record) {
                RecordRowView(record: record)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    recordToDelete = record
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    recordToDelete = record
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.records.isEmpty {
                ProgressView()
            } else if viewModel.filteredRecords.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty && viewModel.filterType == nil ? "No DNS Records" : "No Matching Records",
                    systemImage: "doc.text"
                )
            }
        }
        .safeAreaBar(edge: .top) {
            RecordTypePicker(selectedType: $viewModel.filterType)
                .padding(.vertical, AppTheme.smallSpacing)
        }
        .navigationTitle(viewModel.zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search records")
        .refreshable {
            await viewModel.loadRecords(force: true)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            NavigationStack {
                RecordEditView(
                    viewModel: RecordEditViewModel(
                        record: .new(zoneID: viewModel.zone.id, zoneName: viewModel.zone.name),
                        zoneID: viewModel.zone.id,
                        provider: provider
                    )
                ) { _ in
                    showingAddRecord = false
                    Task { await viewModel.loadRecords(force: true) }
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this record?",
            isPresented: .init(
                get: { recordToDelete != nil },
                set: { if !$0 { recordToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    Task { await viewModel.deleteRecord(record) }
                }
            }
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
            Task { await viewModel.loadRecords() }
        }
    }
}
