import SwiftUI

struct RecordRowView: View {
    let record: DNSRecord

    var body: some View {
        HStack(spacing: 12) {
            RecordTypeIcon(type: record.type)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appText)
                    .lineLimit(1)

                Text(record.content)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.type.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.appAccent.opacity(0.12))
                    .clipShape(Capsule())

                HStack(spacing: 4) {
                    if record.proxied ?? false {
                        Image(systemName: "cloud.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    Text(record.displayTTL)
                        .font(.caption2)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .glassCard()
    }
}
