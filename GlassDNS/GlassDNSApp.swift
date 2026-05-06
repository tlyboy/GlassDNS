import SwiftUI

@main
struct GlassDNSApp: App {
    @State private var providerSetupViewModel = ProviderSetupViewModel()
    @AppStorage("appLanguage") private var appLanguage: String = ""

    var body: some Scene {
        WindowGroup {
            ContentView(providerSetupViewModel: providerSetupViewModel)
                .tint(Color.appAccent)
                .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
                .id(appLanguage)
        }
    }
}
