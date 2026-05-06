import SwiftUI

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)?

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.appDanger)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.appText)
                    .lineLimit(2)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding()
            .background(Color.appDanger.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .stroke(Color.appDanger.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3)) {
            isVisible = false
        }
        onDismiss?()
    }
}
