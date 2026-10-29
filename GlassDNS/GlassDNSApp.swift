import SwiftUI

@main
struct GlassDNSApp: App {
    @State private var providerSetupViewModel = ProviderSetupViewModel()
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup {
            ContentView(providerSetupViewModel: providerSetupViewModel)
                .preferredColorScheme(appearance.colorScheme)
                .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
                .id(appLanguage)
        }
        .commands {
            RecordCommands()
        }
    }
}
