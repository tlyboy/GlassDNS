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
                .background(isSelected ? Color.appAccent : Color.white.opacity(0.08))
                .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
