import SwiftUI

@main
struct GlassDNSApp: App {
    @State private var providerSetupViewModel = ProviderSetupViewModel()
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup {
            applyPreferences(ContentView(providerSetupViewModel: providerSetupViewModel))
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 560)
                #endif
        }
        .commands {
            RecordCommands()
        }

        #if os(macOS)
        Settings {
            applyPreferences(SettingsView(providerSetupViewModel: providerSetupViewModel))
                .frame(width: 460)
                .fixedSize(horizontal: false, vertical: true)
        }
        #endif
    }

    private func applyPreferences(_ content: some View) -> some View {
        content
            .preferredColorScheme(appearance.colorScheme)
            .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .id(appLanguage)
    }
}
