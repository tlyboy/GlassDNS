import SwiftUI

struct RecordRowView: View {
    let record: DNSRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let rowLayout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        let metadataLayout = isAccessibilitySize
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: 2))

        rowLayout {
            SubtitleLabel(
                title: Text(record.name),
                subtitle: Text(record.content),
                systemImage: record.type.icon,
                lineLimit: isAccessibilitySize ? nil : 1
            )

            if !isAccessibilitySize {
                Spacer()
            }

            metadataLayout {
                Text(record.type.rawValue)
                HStack(spacing: 4) {
                    if record.isProxied {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Proxied")
                    }
                    Text(record.displayTTL)
                }
                .font(.caption)
            }
            .foregroundStyle(Color.secondary)
            .fixedSize()
        }
    }
}
