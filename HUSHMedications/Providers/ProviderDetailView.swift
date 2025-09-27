import SwiftUI
import SwiftData

struct ProviderDetailView: View {
    @Bindable var provider: Provider
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section(header: Text("Provider Info")) {
                DetailRow(title: "Name", value: provider.providerName)
                DetailRow(title: "Degree", value: provider.degree)
                DetailRow(title: "NPI", value: provider.npi)
                DetailRow(title: "DEA", value: provider.dea)
                DetailRow(title: "License #", value: provider.licenseNumber)
            }
        }
        .navigationTitle(provider.providerName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditSheet = true }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ProviderEditView(provider: provider)
        }
    }
}

private struct DetailRow: View {
    var title: String
    var value: String
    var body: some View {
        HStack {
            Text(title).fontWeight(.medium)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let provider = Provider(providerName: "Dr. Jane Smith", degree: "MD", npi: "1234567890", dea: "AB1234567", licenseNumber: "CA12345")
    return NavigationStack {
        ProviderDetailView(provider: provider)
    }
    .modelContainer(for: Provider.self, inMemory: true)
}
