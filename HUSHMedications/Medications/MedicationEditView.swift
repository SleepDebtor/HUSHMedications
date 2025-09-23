import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct MedicationEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var medication: Medication
    var isNew: Bool = true
    
    @State private var newLabelName: String = ""
    @State private var newLabelDetails: String = ""
    
    var body: some View {
        Form {
            Section("Basics") {
                TextField("Medication Name", text: $medication.medicationName)
            }
            
            Section("Pharmacy") {
                TextField("Pharmacy", text: $medication.pharmacy)
                TextField("Pharmacy Website", text: $medication.pharmacyWebsite)
#if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
#endif
            }
            
            Section("Hush") {
                TextField("Hush Website", text: $medication.hushWebsite)
#if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
#endif
                
                HStack {
                    TextField("Hush QR Code Payload", text: $medication.hushQRCodePayload)
                        .disabled(true)
#if os(iOS)
                    Button("Copy") {
                        UIPasteboard.general.string = medication.hushQRCodePayload
                    }
                    .disabled(medication.hushQRCodePayload.isEmpty)
#endif
                }
                
                Button("Use Hush URL as QR") {
                    medication.hushQRCodePayload = medication.hushWebsite
                }
                .disabled(medication.hushWebsite.isEmpty)
            }
            
            Section("Notes") {
                TextEditor(text: $medication.notes)
                    .frame(minHeight: 100)
            }
            
            Section("Labels") {
                if medication.labels.isEmpty {
                    Text("No labels added")
                        .foregroundColor(.secondary)
                }
                
                ForEach($medication.labels) { $label in
                    VStack(alignment: .leading) {
                        TextField("Label Name", text: $label.medicationName)
                        TextField("Dose", text: $label.dose)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    medication.labels.remove(atOffsets: indices)
                }
                
                VStack {
                    TextField("New Label Name", text: $newLabelName)
                    TextField("New Label Details (optional)", text: $newLabelDetails)
                    Button("Add Label") {
                        let trimmedName = newLabelName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            medication.labels.append(
                                MedicationLabel(medicationName: trimmedName)
                            )
                            newLabelName = ""
                            newLabelDetails = ""
                        }
                    }
                    .disabled(newLabelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(isNew ? "New Medication" : "Edit Medication")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if isNew {
                        context.insert(medication)
                    }
                    try? context.save()
                    dismiss()
                }
                .disabled(medication.medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    // Create an in-memory container for previews
    let container = try! ModelContainer(for: Medication.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    // Seed sample data
    let med = Medication(medicationName: "Sample Med")
    context.insert(med)

    return NavigationStack {
        MedicationEditView(medication: med, isNew: true)
            .modelContext(context)
    }
}

