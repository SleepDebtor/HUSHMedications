//
//  Provider.swift
//  HUSHMedications
//
//  Created by Assistant on 9/27/25.
//

import Foundation
import SwiftData

/// A provider record representing a healthcare provider who can dispense or prescribe medications.
@Model
final class Provider {
    /// The provider's full name
    var providerName: String

    /// The provider's professional degree (e.g., MD, DO, NP)
    var degree: String

    /// National Provider Identifier (NPI)
    var npi: String

    /// Drug Enforcement Administration (DEA) number
    var dea: String

    /// Professional license number
    var licenseNumber: String

    init(
        providerName: String = "",
        degree: String = "",
        npi: String = "",
        dea: String = "",
        licenseNumber: String = ""
    ) {
        self.providerName = providerName
        self.degree = degree
        self.npi = npi
        self.dea = dea
        self.licenseNumber = licenseNumber
    }
}
