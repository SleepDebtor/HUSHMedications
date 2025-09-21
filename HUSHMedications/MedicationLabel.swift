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

    /// Linked patient for this label (optional)
    var patient: Patient?

    /// Medication display name for the label (e.g., "Amoxicillin")
    var medicationName: String

    /// Dose strength (e.g., "500 mg")
    var dose: String

    /// Quantity dispensed
    var dispenseAmount: Int

    /// SIG: Directions for use (e.g., "Take 1 tablet by mouth every 8 hours")
    var sig: String

    /// Stored QR image data (PNG/JPEG) generated from `qrURL`
    var qrImageData: Data?

    /// Computed QR URL: https://hushmedicalspa.com/medications/{medicationIdentifier}
    var qrURL: URL? {
        URL(string: "https://hushmedicalspa.com/medications/\(medicationIdentifier)")
    }

    init(
        createdAt: Date = .now,
        pharmacyIdentifier: String,
        rxNumber: String,
        medicationIdentifier: String,
        lotNumber: String? = nil,
        bestByDate: Date? = nil,
        patient: Patient? = nil,
        medicationName: String,
        dose: String,
        dispenseAmount: Int,
        sig: String,
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
    }
}
