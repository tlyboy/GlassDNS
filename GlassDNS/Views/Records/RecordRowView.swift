import SwiftUI

struct RecordRowView: View {
    let record: DNSRecord
    var isSelected = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let badgeColor = isSelected ? Color.white : Color("AccentColor")
        let primaryText = isSelected ? Color.white : Color.primary
        let secondaryText = isSelected ? Color.white.opacity(0.8) : Color.secondary
        let rowLayout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        let metadataLayout = isAccessibilitySize
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: 4))

        rowLayout {
            if !isAccessibilitySize {
                RecordTypeIcon(type: record.type)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(primaryText)
                    .lineLimit(isAccessibilitySize ? nil : 1)

                Text(record.content)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                    .lineLimit(isAccessibilitySize ? nil : 1)
            }

            if !isAccessibilitySize {
                Spacer()
            }

            metadataLayout {
                Text(record.type.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(badgeColor)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())

                HStack(spacing: 4) {
                    if record.proxied ?? false {
                        Image(systemName: "cloud.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Proxied")
                    }

                    Text(record.displayTTL)
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
            }
        }
    }
}
