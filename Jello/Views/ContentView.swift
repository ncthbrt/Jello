//
//  ContentView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @State private var navigation: ProjectNavigation = ProjectNavigation()
    
    var body: some View {
        NavigationSplitView(
            sidebar: { ProjectSidebarView() },
            detail: { JelloDocumentNavigationStackView() })
        .environment(navigation)
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear() {
            guard let nodes = try? modelContext.fetch(FetchDescriptor<JelloNode>()) else {
                return
            }
            
            for node in nodes {
                let controller = JelloNodeControllerFactory.getController(node)
                controller.migrate(node: node)
            }
        }
    }
 
    
}

