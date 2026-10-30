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

struct SelectionBackground: View {
    var horizontalInset: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color("AccentColor"))
            .padding(.horizontal, horizontalInset)
    }
}

extension View {
    /// Plain lists draw row backgrounds edge to edge, so they need an inset to match sidebar selection.
    func selectionBackground(_ isSelected: Bool, horizontalInset: CGFloat) -> some View {
        listRowBackground(isSelected ? SelectionBackground(horizontalInset: horizontalInset) : nil)
    }
}
