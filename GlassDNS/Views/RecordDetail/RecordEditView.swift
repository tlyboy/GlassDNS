import SwiftUI

struct RecordEditView: View {
    @Bindable var viewModel: RecordEditViewModel
    var onSaved: ((DNSRecord) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                typeSection
                nameSection
                contentSection

                if viewModel.type.requiresPriority {
                    prioritySection
                }

                ttlSection

                if viewModel.type.supportsProxy {
                    proxySection
                }

                validationSection

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(viewModel.isNewRecord ? "Add Record" : "Edit Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appTextSecondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if let saved = await viewModel.save() {
                            onSaved?(saved)
                        }
                    }
                }
                .foregroundStyle(Color.appAccent)
                .disabled(!viewModel.canAttemptSave)
            }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Type")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DNSRecordType.allCases) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.type = type
                            }
                        } label: {
                            HStack(spacing: 6) {
                                RecordTypeIcon(type: type, size: 24)
                                Text(type.rawValue)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.type == type ? Color.appAccent.opacity(0.2) : Color.white.opacity(0.05))
                            .foregroundStyle(viewModel.type == type ? Color.appAccent : Color.appTextSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.type == type ? Color.appAccent.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Name")

            TextField("e.g. www", text: $viewModel.name)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.appText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Use @ for the root domain")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .glassCard()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Content")

            TextField(contentPlaceholder, text: contentBinding)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.appText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .glassCard()
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Priority")

            TextField("10", value: $viewModel.priority, format: .number)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.appText)
                .keyboardType(.numberPad)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .glassCard()
    }

    private var ttlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("TTL")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TTLFormatter.presets, id: \.value) { preset in
                        Button {
                            viewModel.ttl = preset.value
                        } label: {
                            Text(preset.label)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.ttl == preset.value ? Color.appAccent.opacity(0.2) : Color.white.opacity(0.05))
                                .foregroundStyle(viewModel.ttl == preset.value ? Color.appAccent : Color.appTextSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private var proxySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Proxy")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appText)

                Text("Route traffic through Cloudflare network")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Toggle("", isOn: $viewModel.proxied)
                .tint(Color.appAccent)
        }
        .glassCard()
    }

    @ViewBuilder
    private var validationSection: some View {
        let errors = viewModel.visibleValidationErrors
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(errors.enumerated()), id: \.offset) { _, error in
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.appDanger)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.appDanger.opacity(0.9))
                    }
                }
            }
            .glassCard()
        }
    }

    private var contentBinding: Binding<String> {
        Binding(
            get: { viewModel.content },
            set: { viewModel.updateContent($0) }
        )
    }

    private func fieldLabel(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appTextSecondary)
    }

    private var contentPlaceholder: String {
        switch viewModel.type {
        case .a: return "192.0.2.1"
        case .aaaa: return "2001:db8::1"
        case .cname: return "example.com"
        case .mx: return "mail.example.com"
        case .txt: return "v=spf1 include:example.com ~all"
        case .ns: return "ns1.example.com"
        case .srv: return "0 5 5060 sipserver.example.com"
        }
    }
}
