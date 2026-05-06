import SwiftUI

struct RecordTypeIcon: View {
    let type: DNSRecordType
    var size: CGFloat = 32

    private var iconColor: Color {
        switch type {
        case .a: return .green
        case .aaaa: return .blue
        case .cname: return .orange
        case .mx: return .purple
        case .txt: return .yellow
        case .ns: return .red
        case .srv: return .pink
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: type.icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }
}
