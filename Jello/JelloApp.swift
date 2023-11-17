//
//  JelloApp.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers


struct AppContents : View {
    @Environment(ProjectNavigation.self) private var navigation
    
    var body: some View {
        ZStack {
            if navigation.modelContainer == nil {
                ProjectPickerView()
                    .transition(.move(edge: .trailing))
            } else {
                ContentView()
                    .modelContainer(navigation.modelContainer!)
                    .transition(.move(edge: .leading))
            }
        }.frame(maxWidth: .infinity)
    }
}

@main
struct JelloApp: App {
    @State private var navigation: ProjectNavigation = ProjectNavigation()
    var body: some Scene {
        WindowGroup {
            AppContents()
                .environment(navigation)
        }
        .modelContainer(for: [JelloProjectReference.self], inMemory: false, isAutosaveEnabled: true)
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
        JelloFunction.self,
        JelloGraph.self,
        JelloEdge.self,
        JelloNode.self,
        JelloInputPort.self,
        JelloOutputPort.self
    ]
}
