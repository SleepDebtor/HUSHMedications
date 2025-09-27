import SwiftUI
import SwiftData

struct ProviderEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var provider: Provider
    var isNew: Bool

    init(provider: Provider? = nil) {
        if let provider {
            _provider = .init(wrappedValue: provider)
            isNew = false
        } else {
            _provider = .init(wrappedValue: Provider())
            isNew = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Provider Info")) {
                    TextField("Full Name", text: $provider.providerName)
                    TextField("Degree (MD, DO, NP, etc.)", text: $provider.degree)
                    TextField("NPI", text: $provider.npi)
                        .keyboardType(.numberPad)
                    TextField("DEA Number", text: $provider.dea)
                    TextField("License Number", text: $provider.licenseNumber)
                }
            }
            .navigationTitle(isNew ? "New Provider" : "Edit Provider")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(provider.providerName.isEmpty)
                }
            }
        }
    }

    private func save() {
        if isNew {
            modelContext.insert(provider)
        }
        dismiss()
    }
}

#Preview {
    ProviderEditView()
        .modelContainer(for: Provider.self, inMemory: true)
}
