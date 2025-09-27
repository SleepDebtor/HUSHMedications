import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct MedicationLabelDetailView: View {
  @Bindable var label: MedicationLabel
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query private var providers: [Provider]

  var body: some View {
    Form {
      Section("Overview") {
          Text(label.patient?.fullName ?? "Undefined")
          .foregroundColor(.secondary)
          // Picker for prescriber/provider
          Picker("Provider", selection: $label.prescriber) {
            Text("None").tag(nil as Provider?)
            ForEach(providers, id: \.licenseNumber) { provider in
              Text("\(provider.providerName), \(provider.degree)").tag(provider as Provider?)
            }
          }
          .pickerStyle(.menu)
          Text("Created on: \(label.createdAt.formatted(date: .numeric, time: .shortened))")
          .foregroundColor(.secondary)
      }

      Section("Medication") {
        TextField("Medication Name", text: $label.medicationName)
        TextField("Dose", text: $label.dose)
        Stepper(value: $label.dispenseAmount, in: 0...9999) {
          HStack {
            Text("Dispense Amount")
            Spacer()
            Text("\(label.dispenseAmount)")
              .foregroundColor(.secondary)
          }
        }
        TextEditor(text: $label.sig)
          .frame(minHeight: 120)
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
      }

      Section("Identifiers") {
        TextField("RX Number", text: $label.rxNumber)
        TextField("Medication Identifier", text: $label.medicationIdentifier)
        TextField("Pharmacy Identifier", text: $label.pharmacyIdentifier)
        TextField("Lot Number", text: bindingForOptionalString($label.lotNumber))
        DatePicker(
          "Best By Date",
          selection: bindingForOptionalDate($label.bestByDate),
          displayedComponents: [.date]
        )
      }

      Section("QR Code") {
        if let imageData = label.qrImageData,
           let image = decodeImage(data: imageData)
        {
          image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 200, maxHeight: 200)
            .padding(.vertical, 8)
        } else {
          Text("No QR Code Image")
            .foregroundColor(.secondary)
        }
        if let url = label.qrURL {
          Text(url.absoluteString)
            .font(.footnote)
            .foregroundColor(.blue)
            .textSelection(.enabled)
            .padding(.vertical, 4)
        }
        Button("Regenerate QR Code") {
          label.regenerateQR()
          try? modelContext.save()
        }
      }
    }
    .navigationTitle("Medication Label")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          printLabel()
        } label: {
          Label("Print", systemImage: "printer")
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          try? modelContext.save()
          dismiss()
        }
      }
    }
  }

  private func decodeImage(data: Data) -> Image? {
    #if os(iOS)
    if let uiImage = UIImage(data: data) {
      return Image(uiImage: uiImage)
    }
    #elseif os(macOS)
    if let nsImage = NSImage(data: data) {
      return Image(nsImage: nsImage)
    }
    #endif
    return nil
  }

  private func printLabel() {
    #if os(iOS)
    guard let pdfData = label.generatePDFLabel(dpi: 300) else { return }
    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.jobName = "Medication Label"
    printInfo.outputType = .general
    printController.printInfo = printInfo
    printController.showsNumberOfCopies = false
    printController.printingItem = pdfData
    printController.present(animated: true, completionHandler: nil)
    #elseif os(macOS)
    guard let pdfData = label.generatePDFLabel(dpi: 300) else { return }
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MedicationLabel.pdf")
    try? pdfData.write(to: tempURL)
    NSWorkspace.shared.open(tempURL)
    #endif
  }

  private func bindingForOptionalString(_ optional: Binding<String?>) -> Binding<String> {
    Binding(
      get: { optional.wrappedValue ?? "" },
      set: { optional.wrappedValue = $0.isEmpty ? nil : $0 }
    )
  }

  private func bindingForOptionalDate(_ optional: Binding<Date?>) -> Binding<Date> {
    Binding(
      get: { optional.wrappedValue ?? Date() },
      set: { optional.wrappedValue = $0 }
    )
  }
}

#Preview {
  let label = MedicationLabel(
    createdAt: Date(),
    pharmacyIdentifier: "PHARM001",
    rxNumber: "RX123456",
    medicationIdentifier: "MEDID789",
    lotNumber: "LOT5678",
    bestByDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
    medicationName: "Amoxicillin",
    dose: "500mg",
    dispenseAmount: 30,
    sig: "Take one capsule by mouth twice daily"
  )
  NavigationStack {
    MedicationLabelDetailView(label: label)
  }
}
