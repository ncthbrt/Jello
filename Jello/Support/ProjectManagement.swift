//
//  FileManagement.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/03.
//

import Foundation
import SwiftUI
import SwiftData

struct ProjectManagement {
    
    static func createNewJelloProjectFile(modelContext: ModelContext, url: URL) -> ModelContainer? {
        let _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        try! FileManager.default.removeItem(at: url)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        
        guard let projectReference = JelloProjectReference(path: url) else {
            return nil
        }
        modelContext.insert(projectReference)
        try! modelContext.save()
        let modelUrl = url.appendingPathComponent("StoreContent")
        let config = ModelConfiguration(url: modelUrl)
        return try? ModelContainer(for: Schema(versionedSchema: JelloVersionedSchema.self), migrationPlan: JelloMigrationPlan.self, configurations: [config])
    }
    
    static func loadExistingJelloProjectFile(projects: [JelloProjectReference], modelContext: ModelContext, url: URL)  -> ModelContainer? {
        let _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        var maybeExistingProjectReference = projects.first(where: { $0.fullPath == url })
        let toInsert = maybeExistingProjectReference == nil
        
        maybeExistingProjectReference = maybeExistingProjectReference ?? JelloProjectReference(path: url)
        guard let projectReference = maybeExistingProjectReference else {
            // TODO, show appropriate error message
            return nil
        }
        
        if toInsert {
            modelContext.insert(projectReference)
        }
        try! modelContext.save()
        
        
        let modelUrl = url.appendingPathComponent("StoreContent")
        let config = ModelConfiguration(url: modelUrl)
        guard let container = try? ModelContainer(for: Schema(versionedSchema: JelloVersionedSchema.self), migrationPlan: JelloMigrationPlan.self, configurations: [config]) else {
            return nil
        }
        return container
    }
    
    static func loadExistingJelloProjectFile(project: JelloProjectReference) -> ModelContainer? {
        guard let basePath = project.hydratedBasePath else {
            // TODO Handle Errors here
            return nil
        }
        if basePath.startAccessingSecurityScopedResource() {
            var url = basePath
            if let subPath = project.subPath {
                url = basePath.appendingPathComponent(subPath)
            }
            let config = ModelConfiguration(url: url.appendingPathComponent("StoreContent"))
            return try? ModelContainer(for: Schema(versionedSchema: JelloVersionedSchema.self), migrationPlan: JelloMigrationPlan.self, configurations: [config])
        } else {
            // TODO, show nicer error message
            return nil
        }
    }
    
}


struct OpenJelloProjectUrlViewModifier : ViewModifier {
    @Environment(ProjectNavigation.self) private var navigation
    @Environment(\.modelContext) private var modelContext
    @Query var projects: [JelloProjectReference]

    func body(content: Content) -> some View {
        content.onOpenURL(perform: { url in
            if url.pathExtension == "jello" {
                guard let modelContainer = ProjectManagement.loadExistingJelloProjectFile(projects: projects, modelContext: modelContext, url: url) else {
                    // TODO handle errors
                    return
                }
                navigation.modelContainer = modelContainer
            }
        })
    }
}



extension View {
    func onOpenJelloProjectUrl() -> some View {
        return self.modifier(OpenJelloProjectUrlViewModifier())
    }

}
