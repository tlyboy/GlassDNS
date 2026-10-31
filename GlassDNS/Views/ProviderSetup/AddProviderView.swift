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

    private var canAdd: Bool {
        isFormValid && !viewModel.isLoading
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
                        Label(LocalizedStringKey(type.displayName), systemImage: type.icon).tag(type)
                    }
                } label: {
                    Text("Provider")
                } currentValueLabel: {
                    Label {
                        Text(" ") + Text(LocalizedStringKey(selectedType.displayName))
                    } icon: {
                        Image(systemName: selectedType.icon)
                    }
                }
                .pickerStyle(.menu)

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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
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
                    } label: {
                        Text("Add")
                            .foregroundStyle(canAdd ? Color.white : Color.secondary)
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }

    private var credentialsSection: some View {
        Section {
            credentialField("Display Name", prompt: "Optional", text: $displayName)

            switch selectedType {
            case .cloudflare:
                credentialField("API Token", prompt: "Enter API Token", text: $apiToken, isSecure: true)
            case .aliyun:
                credentialField("AccessKey ID", prompt: "Enter AccessKey ID", text: $accessKeyId)
                credentialField("AccessKey Secret", prompt: "Enter AccessKey Secret", text: $accessKeySecret, isSecure: true)
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

    @ViewBuilder
    private func credentialField(
        _ title: LocalizedStringKey,
        prompt: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool = false
    ) -> some View {
        LabeledContent(title) {
            Group {
                if isSecure {
                    SecureField(prompt, text: text)
                } else {
                    TextField(prompt, text: text)
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }
}
