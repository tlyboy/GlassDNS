import SwiftUI

struct RecordFormSections: View {
    @Bindable var viewModel: RecordEditViewModel

    var body: some View {
        Section {
            Picker("Type", selection: $viewModel.type) {
                ForEach(DNSRecordType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.menu)
        }

        Section {
            TextField("e.g. www", text: $viewModel.name)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("Name")
        } footer: {
            Text("Use @ for the root domain")
        }

        Section("Content") {
            TextField(contentPlaceholder, text: contentBinding)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }

        if viewModel.type.requiresPriority {
            Section("Priority") {
                TextField("10", value: $viewModel.priority, format: .number)
                    .keyboardType(.numberPad)
            }
        }

        Section {
            Picker("TTL", selection: $viewModel.ttl) {
                ForEach(TTLFormatter.presets, id: \.value) { preset in
                    Text(preset.label).tag(preset.value)
                }
                if !TTLFormatter.presets.contains(where: { $0.value == viewModel.ttl }) {
                    Text(TTLFormatter.format(viewModel.ttl)).tag(viewModel.ttl)
                }
            }
            .pickerStyle(.menu)

            if viewModel.showsProxy {
                Toggle(isOn: $viewModel.proxied) {
                    Text("Proxy")
                    Text("Route traffic through Cloudflare network")
                }
                .tint(Color.accentColor)
            }
        }

        errorSection
    }

    @ViewBuilder
    private var errorSection: some View {
        let errors = viewModel.visibleValidationErrors
        if !errors.isEmpty || viewModel.errorMessage != nil {
            Section {
                ForEach(Array(errors.enumerated()), id: \.offset) { _, error in
                    Label {
                        Text(error)
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                    }
                }

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color.red)
        }
    }

    private var contentBinding: Binding<String> {
        Binding(
            get: { viewModel.content },
            set: { viewModel.updateContent($0) }
        )
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
