import SwiftUI
import SwiftData

// An editable form for creating or updating a Patient.
struct PatientEditView: View {
    @Environment(\.dismiss) private var dismiss

    // Bind directly to an existing Patient for editing, or initialize with a new value
    @Bindable var patient: Patient

    var body: some View {
        Form {
            Section("Name") {
                TextField("First name", text: $patient.firstName)
                TextField("Middle", text: Binding(optional: $patient.middleName, replacingNilWith: ""))
                TextField("Last name", text: $patient.lastName)
            }

            Section("Identifiers") {
                TextField("Medical Record Number", text: $patient.medicalRecordNumber)
            }

            Section("Birth") {
                DatePicker("Date of Birth", selection: $patient.birthDate, displayedComponents: .date)
            }

            Section("Address") {
                TextField("Line 1", text: $patient.streetLine1)
                TextField("Line 2", text: Binding(optional: $patient.streetLine2, replacingNilWith: ""))
                TextField("City", text: $patient.city)
                TextField("State/Province", text: $patient.state)
                TextField("Postal Code", text: $patient.postalCode)
                TextField("Country", text: $patient.country)
            }
        }
        .navigationTitle("Edit Patient")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Utilities

private extension Binding where Value == String {
    // Helper to bind an optional String source to a non-optional TextField while preserving nil when empty
    init(optional source: Binding<String?>, replacingNilWith placeholder: String) {
        self.init(
            get: { source.wrappedValue ?? placeholder },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                source.wrappedValue = trimmed.isEmpty ? nil : newValue
            }
        )
    }
}

#Preview("Edit Existing Patient") {
    NavigationStack {
        PatientEditView(patient: Patient(
            firstName: "Alex",
            middleName: "J.",
            lastName: "Rivera",
            medicalRecordNumber: "MRN-0012345",
            birthDate: Calendar.current.date(from: DateComponents(year: 1988, month: 6, day: 15)) ?? .now,
            streetLine1: "123 Main St",
            streetLine2: "Apt 4B",
            city: "Cupertino",
            state: "CA",
            postalCode: "95014",
            country: "USA"
        ))
    }
}
