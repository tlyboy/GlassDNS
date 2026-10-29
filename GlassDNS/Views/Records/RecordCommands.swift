import SwiftUI

struct RecordListActions {
    let addRecord: () -> Void
    let refresh: () -> Void
    let deleteSelected: (() -> Void)?
}

extension FocusedValues {
    @Entry var recordListActions: RecordListActions?
}

struct RecordCommands: Commands {
    @FocusedValue(\.recordListActions) private var actions

    var body: some Commands {
        CommandMenu("Record") {
            Button("Add Record", systemImage: "plus") {
                actions?.addRecord()
            }
            .keyboardShortcut("n")
            .disabled(actions == nil)

            Button("Refresh", systemImage: "arrow.clockwise") {
                actions?.refresh()
            }
            .keyboardShortcut("r")
            .disabled(actions == nil)

            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                actions?.deleteSelected?()
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(actions?.deleteSelected == nil)
        }
    }
}
