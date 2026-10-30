import SwiftUI

struct RecordTypePicker: View {
    @Binding var selectedType: DNSRecordType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.smallSpacing) {
                FilterChip(title: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }

                ForEach(DNSRecordType.allCases) { type in
                    FilterChip(title: type.rawValue, isSelected: selectedType == type) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 1)
        }
        .scrollClipDisabled()
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary))
                .foregroundStyle(isSelected ? .white : Color.secondary)
                .clipShape(Capsule())
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
