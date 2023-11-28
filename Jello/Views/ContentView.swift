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
    @Environment(ProjectNavigation.self) private var navigation
    
    var body: some View {
        NavigationSplitView(
            sidebar: { ProjectSidebarView() },
            detail: { JelloDocumentNavigationStackView() })
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden, for: .navigationBar)
    }
 
    
}

#Preview {
    ContentView()
        .modelContainer(for: [JelloMaterial.self, JelloFunction.self], inMemory: true)

}
