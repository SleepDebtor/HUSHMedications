import SwiftUI

// A compact row suitable for use in lists of patients.
struct PatientRowView: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.tint.opacity(0.15))
                Image(systemName: "person.fill")
                    .foregroundStyle(.tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(patient.fullName)
                    .font(.body)
                    .lineLimit(1)
                Text("MRN: \(patient.medicalRecordNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(patient.age)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Age \(patient.age)")
        }
        .contentShape(Rectangle())
    }
}

#Preview("Row Preview") {
    List {
        PatientRowView(patient: Patient(
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
