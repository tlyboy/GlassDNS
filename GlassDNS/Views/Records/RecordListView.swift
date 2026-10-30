import SwiftUI

struct RecordListView: View {
    @Bindable var viewModel: RecordListViewModel
    @Binding var selection: DNSRecord.ID?
    @State private var showingAddRecord = false
    @State private var recordToDelete: DNSRecord?
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(viewModel.filteredRecords) { record in
                    NavigationLink(value: record.id) {
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

                if viewModel.filteredRecords.isEmpty && !(viewModel.isLoading && viewModel.records.isEmpty) {
                    ContentUnavailableView(
                        viewModel.searchText.isEmpty && viewModel.filterType == nil ? "No DNS Records" : "No Matching Records",
                        systemImage: "doc.text"
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } header: {
                RecordTypePicker(selectedType: $viewModel.filterType)
                    .padding(.vertical, AppTheme.smallSpacing)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.plain)
        .tint(Color(.systemGray4))
        #endif
        .overlay {
            if viewModel.isLoading && viewModel.records.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle(viewModel.zone.name)
        .inlineNavigationTitle()
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Search records")
        .refreshable {
            await viewModel.loadRecords(force: true)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRecord = true
                } label: {
                    Label("Add Record", systemImage: "plus")
                        .foregroundStyle(Color.accentColor)
                }
            }
            #if os(iOS)
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            #endif
        }
        .sheet(isPresented: $showingAddRecord) {
            NavigationStack {
                RecordView(
                    record: .new(zoneID: viewModel.zone.id, zoneName: viewModel.zone.name),
                    zoneID: viewModel.zone.id,
                    provider: viewModel.provider
                ) { _ in
                    showingAddRecord = false
                    Task { await viewModel.loadRecords(force: true) }
                }
            }
            .sheetStyle()
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
                    delete(record)
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
        .focusedSceneValue(\.recordListActions, isEnabled ? RecordListActions(
            addRecord: { showingAddRecord = true },
            refresh: { Task { await viewModel.loadRecords(force: true) } },
            deleteSelected: selectedRecord.map { record in { recordToDelete = record } }
        ) : nil)
        .onAppear {
            Task { await viewModel.loadRecords() }
        }
    }

    private var selectedRecord: DNSRecord? {
        viewModel.filteredRecords.first { $0.id == selection }
    }

    private func delete(_ record: DNSRecord) {
        if selection == record.id {
            selection = nil
        }
        Task { await viewModel.deleteRecord(record) }
    }
}
