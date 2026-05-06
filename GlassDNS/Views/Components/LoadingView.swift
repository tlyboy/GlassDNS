import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 60)
                    .overlay(
                        GeometryReader { geometry in
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.white.opacity(0.08),
                                    .clear,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geometry.size.width * 0.6)
                            .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.6)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal)
        .onAppear { isAnimating = true }
    }
}
