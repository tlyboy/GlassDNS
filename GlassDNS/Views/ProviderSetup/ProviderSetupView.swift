import SwiftUI

struct ProviderSetupView: View {
    @Bindable var viewModel: ProviderSetupViewModel
    @State private var showingAddSheet = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            Spacer()

            Image(systemName: "cloud.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor.opacity(0.6))

            Text("Add DNS Provider")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("Connect your DNS provider to start managing domain records.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Provider", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
            .padding(.top, AppTheme.spacing)

            Button {
                Task {
                    let _ = await viewModel.addAccount(
                        displayName: "Example",
                        providerType: .example,
                        token: ""
                    )
                }
            } label: {
                Label("Try Example", systemImage: "play.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.glass)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("GlassDNS")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddProviderView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }
}
