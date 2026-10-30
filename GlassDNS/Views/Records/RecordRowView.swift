import SwiftUI

struct RecordRowView: View {
    let record: DNSRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.backgroundProminence) private var backgroundProminence

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let badgeColor = backgroundProminence == .increased ? Color.white : Color("AccentColor")
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
                    .foregroundStyle(Color.primary)
                    .lineLimit(isAccessibilitySize ? nil : 1)

                Text(record.content)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
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
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
