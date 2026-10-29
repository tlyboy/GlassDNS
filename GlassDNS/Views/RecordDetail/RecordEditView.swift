import SwiftUI

struct RecordEditView: View {
    @Bindable var viewModel: RecordEditViewModel
    var onSaved: ((DNSRecord) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            RecordFormSections(viewModel: viewModel)
        }
        .navigationTitle(viewModel.isNewRecord ? "Add Record" : "Edit Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.secondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if let saved = await viewModel.save() {
                            onSaved?(saved)
                        }
                    }
                }
                .foregroundStyle(Color.accentColor)
                .disabled(!viewModel.canAttemptSave)
            }
        }
    }
}
