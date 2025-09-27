import SwiftUI
import SwiftData

struct ProviderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Provider.providerName)]) private var providers: [Provider]

    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(providers) { provider in
                    NavigationLink(value: provider) {
                        VStack(alignment: .leading) {
                            Text(provider.providerName).font(.headline)
                            Text(provider.degree).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteProvider)
            }
            .navigationTitle("Providers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("Add Provider", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                ProviderEditView() // New provider creation
            }
            .navigationDestination(for: Provider.self) { provider in
                ProviderDetailView(provider: provider)
            }
        }
    }

    private func deleteProvider(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(providers[index])
        }
    }
}

#Preview {
    ProviderListView()
        .modelContainer(for: Provider.self, inMemory: true)
}
