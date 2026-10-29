import SwiftUI

struct RecordDetailView: View {
    @State private var record: DNSRecord
    let zoneID: String
    let provider: any DNSProvider
    @State private var showingEdit = false
    @State private var errorMessage: String?
    var onUpdated: (() -> Void)?

    init(record: DNSRecord, zoneID: String, provider: any DNSProvider, onUpdated: (() -> Void)? = nil) {
        self._record = State(initialValue: record)
        self.zoneID = zoneID
        self.provider = provider
        self.onUpdated = onUpdated
    }

    var body: some View {
        Form {
            headerSection
            contentSection
            settingsSection
            metadataSection
        }
        .navigationTitle("Record Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshRecord(force: true)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Text("Edit")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                RecordEditView(
                    viewModel: RecordEditViewModel(record: record, zoneID: zoneID, provider: provider)
                ) { savedRecord in
                    record = savedRecord
                    showingEdit = false
                    onUpdated?()
                }
            }
        }
        .onAppear {
            Task { await refreshRecord() }
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                RecordTypeIcon(type: record.type, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.type.rawValue)
                        .font(.title2.weight(.bold))

                    Text(record.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var contentSection: some View {
        Section("Content") {
            Text(record.content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            LabeledContent("TTL") {
                Text(TTLFormatter.format(record.ttl))
            }

            if record.type.supportsProxy {
                LabeledContent("Proxy") {
                    Text((record.proxied ?? false) ? "Enabled" : "Disabled")
                }
            }

            if let priority = record.priority {
                LabeledContent("Priority", value: "\(priority)")
            }
        }
    }

    private var metadataSection: some View {
        Section("Metadata") {
            LabeledContent("ID", value: record.id)
                .textSelection(.enabled)

            if let created = record.createdOn {
                LabeledContent("Created", value: created.formatted(.dateTime))
            }

            if let modified = record.modifiedOn {
                LabeledContent("Modified", value: modified.formatted(.dateTime))
            }

            if record.locked ?? false {
                LabeledContent("Status") {
                    Text("Locked")
                }
            }
        }
    }

    private func refreshRecord(force: Bool = false) async {
        do {
            let records = try await provider.listRecords(zoneID: zoneID)
            if let latestRecord = records.first(where: { $0.id == record.id }) {
                record = latestRecord
            } else if force {
                errorMessage = DNSProviderError.notFound.localizedDescription
            }
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }
}
