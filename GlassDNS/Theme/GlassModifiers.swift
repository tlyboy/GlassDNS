import SwiftUI

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = AppTheme.spacing

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isProminent ? Color.appAccent : Color.white.opacity(0.1))
            .foregroundStyle(isProminent ? .white : Color.appText)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func glassCard(padding: CGFloat = AppTheme.spacing) -> some View {
        modifier(GlassCardModifier(padding: padding))
    }
}
