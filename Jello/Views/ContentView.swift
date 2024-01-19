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
    @State private var compiler = JelloCompilerService()
    @Environment(ProjectNavigation.self) private var navigation
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationSplitView(
            sidebar: { ProjectSidebarView() },
            detail: { JelloDocumentNavigationStackView() })
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear() {
            compiler.initialize(modelContext: modelContext)
            guard let nodes = try? modelContext.fetch(FetchDescriptor<JelloNode>()) else {
                return
            }
            
            for node in nodes {
                let controller = JelloNodeControllerFactory.getController(node)
                controller.migrate(node: node)
            }
        }
        .environment(compiler)
    }
 
    
}

#Preview {
    ContentView()
        .modelContainer(for: [JelloMaterial.self, JelloFunction.self], inMemory: true)

}
