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
            Label {
                Text(record.name)
                    .lineLimit(isAccessibilitySize ? nil : 1)
                Text(record.content)
                    .lineLimit(isAccessibilitySize ? nil : 1)
            } icon: {
                Image(systemName: record.type.icon)
                    .foregroundStyle(Color("AccentColor"))
            }

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
