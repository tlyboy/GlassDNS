import SwiftUI

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = AppTheme.spacing

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

extension View {
    func glassCard(padding: CGFloat = AppTheme.spacing) -> some View {
        modifier(GlassCardModifier(padding: padding))
    }
}
