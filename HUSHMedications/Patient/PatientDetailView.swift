import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

// A cross-platform SwiftUI view for displaying details of a Patient model.
struct PatientDetailView: View {
    @State var patient: Patient
    @Environment(\.modelContext) private var modelContext
    @Query private var labels: [MedicationLabel]

    init(patient: Patient) {
        self._patient = State(initialValue: patient)
        // Capture the patient's UUID to use in the predicate (predicates support capturing simple values)
        let targetID = patient.id
        self._labels = Query(
            filter: #Predicate<MedicationLabel> { label in
                // Compare UUIDs directly and avoid string conversion/nil-coalescing
                if let p = label.patient {
                    return p.id == targetID
                } else {
                    return false
                }
            },
            sort: [SortDescriptor(\MedicationLabel.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        #if os(iOS)
        content
            .navigationTitle("Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { newLabelToolbar }
        #elseif os(macOS)
        content
            .navigationTitle("Patient Details")
            .toolbar { newLabelToolbar }
        #else
        content
        #endif
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Divider()
                details
                Divider()
                addressSection
                Divider()
                medicationsSection
            }
            .padding()
            .frame(maxWidth: 600, alignment: .leading)
        }
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(.background)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding([.horizontal, .bottom])
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "person.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.title2).bold()
                Text("MRN: \(patient.medicalRecordNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledRow(label: "Age", value: "\(patient.age)")
            labeledRow(label: "Date of Birth", value: formatDate(patient.birthDate))
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address").font(.headline)
        }
    }

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Medication Labels").font(.headline)
                Spacer()
                Button(action: createNewLabel) {
                    Label("New Label", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if labels.isEmpty {
                Text("No labels yet.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(labels) { label in
                    NavigationLink {
                        MedicationLabelDetailView(label: label)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.thinMaterial)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "pills.fill")
                                    .foregroundStyle(.tint)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(label.medicationName.isEmpty ? "(Unnamed Label)" : label.medicationName)
                                        .font(.headline)
                                }
                                Text(label.dose.isEmpty ? "No dose set" : label.dose)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.tertiary)
                                    Text(label.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            printLabel(label)
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteLabel(label)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func labeledRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.body)
            Spacer()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    private func printLabel(_ label: MedicationLabel) {
        guard let pdfData = label.generatePDFLabel(dpi: 300) else { return }
#if os(iOS)
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = label.medicationName.isEmpty ? "Medication Label" : label.medicationName
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = pdfData
        controller.present(animated: true, completionHandler: nil)
#elseif os(macOS)
        if let tempURL = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()), create: true).appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf") {
            do {
                try pdfData.write(to: tempURL)
                NSWorkspace.shared.open(tempURL) // Opens Preview; user can print from there
            } catch {
                print("Failed to write temp PDF: \(error)")
            }
        }
#endif
    }

    private func deleteLabel(_ label: MedicationLabel) {
        withAnimation {
            modelContext.delete(label)
            do { try modelContext.save() } catch { print("Failed to delete label: \(error)") }
        }
    }

    @ToolbarContentBuilder
    private var newLabelToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: createNewLabel) {
                Label("New Label", systemImage: "plus")
            }
        }
    }

    private func createNewLabel() {
        // Construct a MedicationLabel using property assignment to avoid mismatched initializer signatures
        let label = MedicationLabel()
        label.patient = patient
        modelContext.insert(label)
        do {
            try modelContext.save()
        } catch {
            // For now, just log; in production, present a user-facing error
            print("Failed to save new label: \(error)")
        }
    }
}

// MARK: - Previews
#Preview("Patient Detail – iOS/macOS") {
    let demoPatient = Patient(
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
    )

    NavigationStack {
        PatientDetailView(patient: demoPatient)
    }
}
