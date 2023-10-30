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
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: JelloMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct JelloMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        JelloVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct JelloVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}
