//
//  ContentView.swift
//  HUSHMedications
//
//  Created by Michael Lazar on 9/20/25.
//

import SwiftUI
import SwiftData

struct LabelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medicationLabel: [MedicationLabel]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(medicationLabel) { item in
                    NavigationLink {
                        Text("Item at ")
                    } label: {
                        Text("Medication")
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = MedicationLabel()
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(medicationLabel[index])
            }
        }
    }
}

#Preview {
   LabelView()
        .modelContainer(for: MedicationLabel.self, inMemory: true)
}
