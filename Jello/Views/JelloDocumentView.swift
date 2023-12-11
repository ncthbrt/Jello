//
//  JelloDocumentView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/01.
//

import Foundation
import SwiftUI
import SwiftData

fileprivate struct JelloFunctionView: View {
    let uuid : UUID
    
    @Query var functions: [JelloFunction]
    @State var newEdge: JelloEdge?
    @Environment(\.modelContext) var modelContext
    @State var viewBounds: CGRect = CGRect(origin: .zero, size: .zero)
    
    init(uuid: UUID) {
        self.uuid = uuid
        _functions = Query(filter: #Predicate<JelloFunction> { function in function.uuid == uuid })
    }
    
    var body: some View {
        if let function = functions.first {
            GraphView(graphId: function.graph.uuid, onOpenAddNodeMenu: { position in AddNewNodeMenuView(graph: function.graph, position: position, includeMaterials: false) }, bounds: $viewBounds)
                .toolbarTitleDisplayMode(.inline)
                .navigationTitle(.init(get: { function.name }, set: {  function.name = $0 }))
                .navigationViewStyle(.stack)
        } else {
            NoSelectedItemView()
        }
    }
}



fileprivate struct JelloMaterialView: View {
    let uuid : UUID
    
    @Query var materials: [JelloMaterial]
    @State var viewBounds: CGRect = CGRect(origin: .zero, size: .zero)
    @Environment(\.modelContext) var modelContext

    init(uuid: UUID) {
        self.uuid = uuid
        _materials = Query(filter: #Predicate<JelloMaterial> { material in material.uuid == uuid })
    }
    
    var body: some View {
        if let material = materials.first {
            GraphView(graphId: material.graph.uuid, onOpenAddNodeMenu: { position in AddNewNodeMenuView(graph: material.graph, position: position, includeMaterials: false) }, bounds: $viewBounds)
                .toolbarTitleDisplayMode(.inline)
                .navigationTitle(.init(get: { material.name }, set: { material.name = $0 }))
                .navigationViewStyle(.stack)
        } else {
            NoSelectedItemView()
        }
    }
}


fileprivate struct JelloDocumentView : View {
    let reference: JelloDocumentReference
    
    var body: some View {
        switch(reference){
        case .function(let uuid):
            JelloFunctionView(uuid: uuid)
        case .material(let uuid):
            JelloMaterialView(uuid: uuid)
        }
    }
}


struct JelloDocumentNavigationStackView: View {
    @Environment(ProjectNavigation.self) private var navigation
 
    
    var body: some View {
        NavigationStack(path: .init(get: { navigation.navPath }, set: { navigation.navPath = $0 }), root: {
            if let item = navigation.selectedItem {
                JelloDocumentView(reference: item)
                    .navigationBarTitleDisplayMode(.automatic)
                    .navigationDestination(for: JelloDocumentReference.self, destination: { reference in
                        JelloDocumentView(reference: reference)
                    })
            } else {
                NoSelectedItemView()
            }
             
        })
    }
}
