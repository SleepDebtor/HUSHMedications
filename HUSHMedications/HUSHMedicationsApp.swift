//
//  HUSHMedicationsApp.swift
//  HUSHMedications
//
//  Created by Michael Lazar on 9/20/25.
//

import SwiftUI
import SwiftData

@main
struct HUSHMedicationsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicationLabel.self,
            Medication.self,
            Patient.self,
            Provider.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            PatientListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
