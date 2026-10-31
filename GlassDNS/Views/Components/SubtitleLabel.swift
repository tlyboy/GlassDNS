import SwiftUI

/// A two-line Label that keeps the same layout on iPhone, iPad, and iPad apps on Mac,
/// where a Label with two Texts lays them out side by side.
struct SubtitleLabel: View {
    let title: Text
    var subtitle: Text?
    let systemImage: String
    var lineLimit: Int?

    @ScaledMetric private var iconWidth: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .imageScale(.large)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .foregroundStyle(Color.primary)
                if let subtitle {
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }
            .lineLimit(lineLimit)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }
}
