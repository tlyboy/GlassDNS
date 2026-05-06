import SwiftUI

extension Color {
    static let appBackground = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let appPrimary = Color(red: 30/255, green: 41/255, blue: 59/255)
    static let appSecondary = Color(red: 51/255, green: 65/255, blue: 85/255)
    static let appAccent = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let appText = Color(red: 248/255, green: 250/255, blue: 252/255)
    static let appTextSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let appDanger = Color(red: 239/255, green: 68/255, blue: 68/255)
}

enum AppTheme {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
}
