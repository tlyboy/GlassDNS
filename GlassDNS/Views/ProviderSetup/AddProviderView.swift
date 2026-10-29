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
            Form {
                Picker(selection: $selectedType) {
                    ForEach(ProviderType.providerCases, id: \.rawValue) { type in
                        Label(type.displayName, systemImage: type.icon).tag(type)
                    }
                } label: {
                    Text("Provider")
                }
                .pickerStyle(.inline)

                credentialsSection

                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.red)
                    }
                }
            }
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

    private var credentialsSection: some View {
        Section {
            LabeledContent("Display Name") {
                TextField("Optional", text: $displayName)
                    .multilineTextAlignment(.trailing)
            }

            switch selectedType {
            case .cloudflare:
                LabeledContent("API Token") {
                    SecureField("Enter API Token", text: $apiToken)
                        .multilineTextAlignment(.trailing)
                }
            case .aliyun:
                LabeledContent("AccessKey ID") {
                    TextField("Enter AccessKey ID", text: $accessKeyId)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("AccessKey Secret") {
                    SecureField("Enter AccessKey Secret", text: $accessKeySecret)
                        .multilineTextAlignment(.trailing)
                }
            case .example:
                EmptyView()
            }

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Verifying...")
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("Credentials")
        } footer: {
            if selectedType == .example {
                Text("No credentials required. Example mode uses sample data for you to explore all features.")
            }
        }
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}
