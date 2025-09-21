import Foundation
import SwiftData

/// A model representing a medication with associated pharmacy and Hush website information.
@Model
final class Medication {
    /// A stable unique identifier for the medication.
    var id: UUID
    
    /// The name of the medication.
    var medicationName: String
    
    /// The name of the pharmacy.
    var pharmacy: String
    
    /// The URL string of the pharmacy's website.
    var pharmacyWebsite: String
    
    /// The URL string for the Hush website.
    var hushWebsite: String
    
    /// The string to encode as a QR code, typically the Hush website URL.
    var hushQRCodePayload: String
    
    /// Notes for possible doses.
    var notes: String
    
    /// Relationship to medication labels.
    @Relationship(deleteRule: .cascade) var labels: [MedicationLabel] = []
    
    /// Memberwise initializer.
    init(
        id: UUID = UUID(),
        medicationName: String = "",
        pharmacy: String = "",
        pharmacyWebsite: String = "",
        hushWebsite: String = "",
        hushQRCodePayload: String = "",
        notes: String = "",
        labels: [MedicationLabel] = []
    ) {
        self.id = id
        self.medicationName = medicationName
        self.pharmacy = pharmacy
        self.pharmacyWebsite = pharmacyWebsite
        self.hushWebsite = hushWebsite
        self.hushQRCodePayload = hushQRCodePayload
        self.notes = notes
        self.labels = labels
    }
    
    /// Returns true if `medicationName` is not empty after trimming whitespace and newlines.
    var hasValidNames: Bool {
        !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
