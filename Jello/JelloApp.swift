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
    var body: some Scene {
        DocumentGroup(editing: .jelloProject, migrationPlan: JelloMigrationPlan.self, editor: {
            ContentView()
                .environment(navigation)
        })
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
        JelloOutputPort.self,
        JelloNodeData.self
    ]
}
