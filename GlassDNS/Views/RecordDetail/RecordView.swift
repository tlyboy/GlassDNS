import SwiftUI

struct RecordView: View {
    @State private var record: DNSRecord
    @State private var viewModel: RecordEditViewModel
    let zoneID: String
    let provider: any DNSProvider
    @Binding var hasChanges: Bool
    var onSaved: ((DNSRecord) -> Void)?

    @State private var showingDiscardConfirmation = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(
        record: DNSRecord,
        zoneID: String,
        provider: any DNSProvider,
        hasChanges: Binding<Bool> = .constant(false),
        onSaved: ((DNSRecord) -> Void)? = nil
    ) {
        self._record = State(initialValue: record)
        self._viewModel = State(initialValue: RecordEditViewModel(record: record, zoneID: zoneID, provider: provider))
        self.zoneID = zoneID
        self.provider = provider
        self._hasChanges = hasChanges
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            RecordFormSections(viewModel: viewModel)
                .disabled(record.locked ?? false)

            if !viewModel.isNewRecord {
                metadataSection
            }
        }
        .navigationTitle(viewModel.isNewRecord ? "Add Record" : "Record Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.hasChanges)
        .interactiveDismissDisabled(viewModel.hasChanges)
        .refreshable {
            await refreshRecord(force: true)
        }
        .toolbar {
            if viewModel.isNewRecord || viewModel.hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button(role: .confirm) {
                            Task { await save() }
                        } label: {
                            Text("Save")
                                .foregroundStyle(viewModel.canAttemptSave ? Color.white : Color.secondary)
                        }
                        .disabled(!viewModel.canAttemptSave)
                    }
                }
            }
        }
        .confirmationDialog("Discard Changes?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: viewModel.hasChanges, initial: true) {
            hasChanges = viewModel.hasChanges
        }
        .onDisappear {
            hasChanges = false
        }
        .onAppear {
            Task { await refreshRecord() }
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

    private func cancel() {
        if !viewModel.isNewRecord {
            reset(to: record)
        } else if viewModel.hasChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        guard let saved = await viewModel.save() else { return }
        if !viewModel.isNewRecord {
            record = saved
            reset(to: saved)
        }
        onSaved?(saved)
    }

    private func reset(to record: DNSRecord) {
        withAnimation {
            viewModel = RecordEditViewModel(record: record, zoneID: zoneID, provider: provider)
        }
    }

    private func refreshRecord(force: Bool = false) async {
        guard !viewModel.isNewRecord else { return }
        do {
            let records = try await provider.listRecords(zoneID: zoneID)
            if let latestRecord = records.first(where: { $0.id == record.id }) {
                record = latestRecord
                if !viewModel.hasChanges {
                    viewModel = RecordEditViewModel(record: latestRecord, zoneID: zoneID, provider: provider)
                }
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
