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
    let id : UUID
    
    @Query var functions: [JelloFunction]
    @State var newEdge: JelloEdge?
    @Environment(\.modelContext) var modelContext
    
    init(id: UUID) {
        self.id = id
        _functions = Query(filter: #Predicate<JelloFunction> { function in function.uuid == id })
    }
    
    var body: some View {
        if let function = functions.first {
            GraphView(graphId: function.graph.id, onOpenAddNodeMenu: { position in AddNewNodeMenuView(graph: function.graph, position: position, items: [:], includeMaterials: false) })
                .toolbarTitleDisplayMode(.inline)
                .navigationTitle(.init(get: { function.name }, set: {  function.name = $0 }))
                .navigationViewStyle(.stack)
        } else {
            NoSelectedItemView()
        }
    }
}



fileprivate struct JelloMaterialView: View {
    let id : UUID
    
    @Query var materials: [JelloMaterial]
    
    init(id: UUID) {
        self.id = id
        _materials = Query(filter: #Predicate<JelloMaterial> { material in material.uuid == id })
    }
    
    var body: some View {
        Text("Material View")
    }
}


fileprivate struct JelloDocumentView : View {
    let reference: JelloDocumentReference
    
    var body: some View {
        switch(reference){
        case .function(let id):
            JelloFunctionView(id: id)
        case .material(let id):
            JelloMaterialView(id: id)
        }
    }
}


struct JelloDocumentNavigationStackView: View {
    @Environment(ProjectNavigation.self) private var navigation
 
    
    var body: some View {
        NavigationStack(path: .init(get: { navigation.navPath }, set: { navigation.navPath = $0 }), root: {
            if let item = navigation.selectedItem {
                JelloDocumentView(reference: item)
                    .navigationDestination(for: JelloDocumentReference.self, destination: { reference in
                        JelloDocumentView(reference: reference)
                    })
            } else {
                NoSelectedItemView()
                    .navigationBarBackButtonHidden()
            }
             
        })
    }
}
