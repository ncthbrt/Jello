//
//  JelloApp.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct JelloApp: App {
    @State private var navigation: ProjectNavigation = ProjectNavigation()
    @State private var currentDocContainer : ModelContainer? = nil
    @State private var currentScopedResource: URL? = nil
    var body: some Scene {
        WindowGroup {
            if let currentContainer = navigation.modelContainer {
                ContentView()
                    .modelContainer(currentContainer)
                    .transition(.slide)
            } else {
                ProjectPickerView()
                    .transition(.slide)
            }
        }
        .modelContainer(for: [JelloProjectReference.self], inMemory: false, isAutosaveEnabled: true)
        .environment(navigation)
    }
}

extension UTType {
    static var jelloProject: UTType {
        UTType(importedAs: "com.cuthbert.jello-project")
    }
}

struct JelloMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        JelloVersionedSchema.self
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct JelloVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        JelloMaterial.self,
        JelloFunction.self
    ]
}
