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
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                headerSection
                contentSection
                settingsSection
                metadataSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
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
                        .foregroundStyle(Color.appAccent)
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
        HStack(spacing: 14) {
            RecordTypeIcon(type: record.type, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.type.rawValue)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appText)

                Text(record.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .glassCard()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Content")

            Text(record.content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.appText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Settings")

            detailRow("TTL", localizedValue: TTLFormatter.format(record.ttl))

            if record.type.supportsProxy {
                detailRow("Proxy", localizedValue: (record.proxied ?? false)
                          ? "Enabled" : "Disabled")
            }

            if let priority = record.priority {
                detailRow("Priority", value: "\(priority)")
            }
        }
        .glassCard()
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Metadata")

            detailRow("ID", value: record.id)

            if let created = record.createdOn {
                detailRow("Created", value: created.formatted(.dateTime))
            }

            if let modified = record.modifiedOn {
                detailRow("Modified", value: modified.formatted(.dateTime))
            }

            if record.locked ?? false {
                detailRow("Status", localizedValue: "Locked")
            }
        }
        .glassCard()
    }

    private func sectionTitle(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appAccent)
    }

    private func detailRow(_ label: LocalizedStringResource, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.appText)
                .lineLimit(1)
                .textSelection(.enabled)
        }
    }

    private func detailRow(_ label: LocalizedStringResource, localizedValue: LocalizedStringResource) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            Text(localizedValue)
                .font(.subheadline)
                .foregroundStyle(Color.appText)
                .lineLimit(1)
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
