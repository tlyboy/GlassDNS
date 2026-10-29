import SwiftUI

struct AddProviderView: View {
    @Bindable var viewModel: ProviderSetupViewModel
    @Binding var isPresented: Bool

    @State private var displayName = ""
    @State private var selectedType: ProviderType = .cloudflare

    // Cloudflare
    @State private var apiToken = ""

    // Aliyun
    @State private var accessKeyId = ""
    @State private var accessKeySecret = ""

    private var isFormValid: Bool {
        switch selectedType {
        case .cloudflare:
            return !apiToken.isEmpty
        case .aliyun:
            return !accessKeyId.isEmpty && !accessKeySecret.isEmpty
        case .example:
            return true
        }
    }

    private var packedToken: String {
        switch selectedType {
        case .cloudflare:
            return apiToken
        case .aliyun:
            return ProviderSetupViewModel.packAliyunCredentials(
                accessKeyId: accessKeyId,
                accessKeySecret: accessKeySecret
            )
        case .example:
            return ""
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    providerTypeSection
                    credentialsSection

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Add Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.addAccount(
                                displayName: displayName.isEmpty ? selectedType.displayName : displayName,
                                providerType: selectedType,
                                token: packedToken
                            )
                            if success {
                                isPresented = false
                            }
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
        }
    }

    private var providerTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Provider")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(ProviderType.providerCases, id: \.rawValue) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedType = type
                        }
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)

                            Text(type.displayName)
                                .foregroundStyle(Color.primary)

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding()
                    }
                }
            }
            .glassCard(padding: 0)
            .padding(.horizontal)
        }
    }

    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Credentials")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display Name")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)

                    TextField("Optional", text: $displayName)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                switch selectedType {
                case .cloudflare:
                    cloudflareFields
                case .aliyun:
                    aliyunFields
                case .example:
                    Text("No credentials required. Example mode uses sample data for you to explore all features.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .tint(Color.accentColor)
                        Text("Verifying...")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .glassCard()
            .padding(.horizontal)
        }
    }

    private var cloudflareFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Token")
                .font(.caption)
                .foregroundStyle(Color.secondary)

            SecureField("Enter API Token", text: $apiToken)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.primary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(.fill.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var aliyunFields: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AccessKey ID")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                TextField("Enter AccessKey ID", text: $accessKeyId)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.primary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("AccessKey Secret")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                SecureField("Enter AccessKey Secret", text: $accessKeySecret)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.primary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
