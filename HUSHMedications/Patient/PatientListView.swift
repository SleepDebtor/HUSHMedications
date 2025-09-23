import SwiftUI
import SwiftData

// A SwiftData-powered list of patients with add, delete, and navigation to details/edit.
struct PatientListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor<Patient>(\.lastName), SortDescriptor<Patient>(\.firstName)]) private var patients: [Patient]

    @State private var showingNewPatientSheet = false
    @State private var draftPatient: Patient? = nil
    @State private var showingNewMedicationSheet = false
    @State private var draftMedication: Medication? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(patients) { patient in
                    NavigationLink(value: patient.id) {
                        PatientRowView(patient: patient)
                    }
                    .contextMenu {
                        Button("Edit") { edit(patient) }
                        Button(role: .destructive) { delete(patient) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Patients")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Patient", action: addPatient)
                        Button("New Medication", action: addMedication)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let patient = patients.first(where: { $0.id == id }) {
                    PatientDetailView(patient: patient)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                NavigationLink("Edit") {
                                    PatientEditView(patient: patient)
                                }
                            }
                        }
                } else {
                    Text("Patient not found")
                }
            }
        }
        .sheet(isPresented: $showingNewPatientSheet, onDismiss: { draftPatient = nil }) {
            NavigationStack {
                if let draftPatient {
                    PatientEditView(patient: draftPatient)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") { save(draftPatient) }
                                    .disabled(draftPatient.firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
                                              draftPatient.lastName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingNewPatientSheet = false
                                }
                            }
                        }
                } else {
                    Text("Preparing new patient…")
                }
            }
        }
        .sheet(isPresented: $showingNewMedicationSheet, onDismiss: { draftMedication = nil }) {
            NavigationStack {
                if let draftMedication {
                    MedicationEditView(medication: draftMedication, isNew: true)
                } else {
                    Text("Preparing new medication…")
                }
            }
        }
    }

    // MARK: - Actions

    private func addPatient() {
        draftPatient = Patient(
            firstName: "",
            lastName: "",
            medicalRecordNumber: "",
            birthDate: Date(),
            streetLine1: "",
            streetLine2: "",
            city: "",
            state: "",
            postalCode: "",
            country: ""
        )
        showingNewPatientSheet = true
    }
    
    private func addMedication() {
        draftMedication = Medication(
            medicationName: "",
            pharmacy: "",
            pharmacyWebsite: "",
            hushWebsite: "",
            hushQRCodePayload: "",
            notes: "",
            labels: []
        )
        showingNewMedicationSheet = true
    }

    private func save(_ patient: Patient) {
        context.insert(patient)
        do {
            try context.save()
            showingNewPatientSheet = false
        } catch {
            // In a real app, handle error properly
            assertionFailure("Failed to save patient: \(error)")
        }
    }

    private func edit(_ patient: Patient) {
        // Navigation to edit is provided via toolbar in detail; this is a placeholder for alternative flows.
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet { delete(patients[index]) }
    }

    private func delete(_ patient: Patient) {
        context.delete(patient)
        do { try context.save() } catch {
            assertionFailure("Failed to delete patient: \(error)")
        }
    }
}

#Preview("Patient List") {
    // Provide a transient model container for previews if needed in app context.
    PatientListView()
}
