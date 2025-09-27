//
//  Item.swift
//  HUSHMedications
//
//  Created by Michael Lazar on 9/20/25.
//

import Foundation
import SwiftData

/// A persisted label record for a dispensed medication.
/// Links to a pharmacy and (optionally) a patient, stores an Rx number, lot/best-by,
/// and provides a QR URL that points to hushmedicalspa.com for this medication identifier.
/// Also stores rendered QR image data and label fields (name, dose, dispense amount, and SIG).
@Model
final class MedicationLabel {
    /// When the label record was created/saved
    var createdAt: Date

    /// Identifier for the pharmacy (e.g., NCPDP, internal code, or slug)
    var pharmacyIdentifier: String

    /// The prescription number associated with this label
    var rxNumber: String

    /// The medication identifier that is used to construct the QR URL path
    var medicationIdentifier: String

    /// Manufacturing lot number (optional)
    var lotNumber: String?

    /// Best used by / expiration date (optional)
    var bestByDate: Date?

    /// Linked patient for this label (nullified on patient delete)
    @Relationship(deleteRule: .nullify)
    var patient: Patient?

    /// Linked medication for this label (nullified on patient delete)
    @Relationship(deleteRule: .nullify)
    var medication: Medication?
    
    /// Medication display name for the label (e.g., "Amoxicillin")
    var medicationName: String

    /// Dose strength (e.g., "500 mg")
    var dose: String

    /// Quantity dispensed
    var dispenseAmount: Double
    
    /// Dose number for calculations
    var doseNum: Double

    /// SIG: Directions for use (e.g., "Take 1 tablet by mouth every 8 hours")
    var sig: String

    /// Stored QR image data (PNG/JPEG) generated from `qrURL`
    var qrImageData: Data?

    /// Computed QR URL: https://hushmedicalspa.com/medications/{medicationIdentifier}
    var qrURL: URL? {
        URL(string: "https://hushmedicalspa.com/medications/\(medicationIdentifier)")
    }
    
    ///The provider who wrote the prescription
    var prescriber: Provider?

    init(
        createdAt: Date = .now,
        pharmacyIdentifier: String = "",
        rxNumber: String = "",
        medicationIdentifier: String = "",
        lotNumber: String? = nil,
        bestByDate: Date? = nil,
        patient: Patient? = nil,
        medicationName: String = "",
        dose: String = "",
        doseNum: Double = 0.0,
        dispenseAmount: Double = 0.0,
        sig: String = "",
        qrImageData: Data? = nil
    ) {
        self.createdAt = createdAt
        self.pharmacyIdentifier = pharmacyIdentifier
        self.rxNumber = rxNumber
        self.medicationIdentifier = medicationIdentifier
        self.lotNumber = lotNumber
        self.bestByDate = bestByDate
        self.patient = patient
        self.medicationName = medicationName
        self.dose = dose
        self.dispenseAmount = dispenseAmount
        self.sig = sig
        self.qrImageData = qrImageData
        self.doseNum = doseNum
    }
    
    /// The amount to fill the syringe
    var fillAmount: Double {
        if let concentration = medication?.concentrationPrimaryMedicationPerMl {
            let doseInMl = doseNum / concentration
            return Double(doseInMl)
        }
        return 0.0
    }
    
    ///The amount of th e second drug given based on the amount of the first drug
    var secondDrugAmount: Double {
        if let concentration = medication?.concentrationPrimaryMedicationPerMl,
           let secondDrugConcentration = medication?.concentrationSecondaryMedicationPerMl {
            let doseInMl = doseNum / concentration
            let secondDrugDoseInMl = doseInMl * secondDrugConcentration
            return secondDrugDoseInMl
        }
        return 0
    }
}
