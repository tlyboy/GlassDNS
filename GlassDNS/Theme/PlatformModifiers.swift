import SwiftUI

extension View {
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    func plainTextEntry() -> some View {
        #if os(iOS)
        autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
        autocorrectionDisabled()
        #endif
    }

    func sheetStyle() -> some View {
        #if os(macOS)
        formStyle(.grouped)
            .frame(width: 460)
            .fixedSize(horizontal: false, vertical: true)
        #else
        self
        #endif
    }
}
