import Foundation
import SwiftData

/// A person receiving care/medication.
@Model
final class Patient {
    /// Stable unique identifier for the patient
    var id: UUID

    /// Legal first name
    var firstName: String

    /// Middle name or initial (optional)
    var middleName: String?

    /// Legal last name
    var lastName: String

    /// Medical record number (MRN)
    var medicalRecordNumber: String

    /// Date of birth
    var birthDate: Date

    /// Full name composed from first/middle/last with proper spacing
    var fullName: String {
        if let mid = middleName, !mid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(firstName) \(mid) \(lastName)"
        } else {
            return "\(firstName) \(lastName)"
        }
    }
    
    var streetLine1: String
    
    var streetLine2: String?
    
    var city: String
    
    var state: String
    
    var postalCode: String
    
    var country: String
    
    /// Age in whole years, computed from birthDate
    var age: Int {
        let now = Date()
        let calendar = Calendar.current
        let years = calendar.dateComponents([.year], from: birthDate, to: now).year ?? 0
        return max(0, years)
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        middleName: String? = nil,
        lastName: String,
        medicalRecordNumber: String,
        birthDate: Date,
        streetLine1: String,
        streetLine2: String? = nil,
        city: String,
        state: String,
        postalCode: String,
        country: String
    ) {
        self.id = id
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.medicalRecordNumber = medicalRecordNumber
        self.birthDate = birthDate
        self.streetLine1 = streetLine1
        self.streetLine2 = streetLine2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
}
