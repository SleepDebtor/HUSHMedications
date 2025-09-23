import Foundation
import SwiftData

/// A model representing a medication with associated pharmacy and Hush website information.
@Model
final class Medication {
    /// A stable unique identifier for the medication.
    var id: UUID
    
    /// The name of the medication.
    var medicationName: String
    
    /// The medication concentration per mg
    var concentrationPrimaryMedicationPerMl: Double = 0
    
    /// The name of the medication.
    var medicationNameSecondary: String? = nil
    
    /// The medication concentration per mg
    var concentrationSecondaryMedicationPerMl: Double? = nil
    
    /// The name of the pharmacy.
    var pharmacy: String
    
    /// The URL string of the pharmacy's website.
    var pharmacyWebsite: String
    
    /// The URL string for the Hush website.
    var hushWebsite: String
    
    ///The medication page identifier from the website that points to the medication for the QR code
    var medIdentifier: String
    
    /// The string to encode as a QR code, typically the Hush website URL.
    var hushQRCodePayload: String
    
    /// Notes for possible doses.
    var notes: String
    
    /// Relationship to medication labels.
    @Relationship(deleteRule: .nullify) var labels: [MedicationLabel] = []
    
    /// Memberwise initializer.
    init(
        id: UUID = UUID(),
        medicationNameSecondary: String = "",
        medicationName: String = "",
        pharmacy: String = "",
        pharmacyWebsite: String = "",
        hushWebsite: String = "",
        hushQRCodePayload: String = "",
        notes: String = "",
        labels: [MedicationLabel] = [],
        medIdentifier: String = ""
    ) {
        self.id = id
        self.medicationName = medicationName
        self.medicationNameSecondary = medicationNameSecondary.isEmpty ? nil : medicationNameSecondary
        self.pharmacy = pharmacy
        self.pharmacyWebsite = pharmacyWebsite
        self.hushWebsite = hushWebsite
        self.hushQRCodePayload = hushQRCodePayload
        self.notes = notes
        self.labels = labels
        self.medIdentifier = medIdentifier
    }
    
    /// Returns true if `medicationName` is not empty after trimming whitespace and newlines.
    var hasValidNames: Bool {
        !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    ///Pharmacy and med name combined for selection
    var selectionName: String {
        [pharmacy, medicationName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
