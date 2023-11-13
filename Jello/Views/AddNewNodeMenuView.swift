//
//  AddNewNodeMenuView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/11.
//

import SwiftUI
import OrderedCollections
import SwiftData

struct NewNodeMenuItemView : View {
    let name: String
    let description: String
    let previewImage: String? = nil
    
    var body: some View {
        HStack {
            Rectangle().aspectRatio(1, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundColor(.gray).padding(5)
            VStack(alignment: .leading) {
                Text(name).font(.title3.bold())
                Text(description).italic().multilineTextAlignment(.leading)
            }
        }.frame(height: 65)
    }
}




struct AddNewNodeMenuBuiltinSectionView : View {
    let category: JelloNodeCategory
    let items: [JelloBuiltInNodeDefinition]
    
    var body: some View {
        Section {
            ForEach(items, content: { item in
                NewNodeMenuItemView(name: item.name, description: item.description)
            })
        } header: {
            Text(String(describing: category.id))
        }
    }
}



struct AddNewNodeMenuUserFunctionSectionView : View {
    let items: [JelloFunction]
    
    var body: some View {
        Section {
            ForEach(items, content: { item in
                NewNodeMenuItemView(name: item.name, description: item.userDescription)
            })
        } header: {
            Text(String("User Functions"))
        }
    }
}



struct AddNewNodeMenuMaterialSectionView : View {
    let items: [JelloMaterial]
    
    var body: some View {
        Section {
            ForEach(items, content: { item in
                NewNodeMenuItemView(name: item.name, description: item.userDescription)
            })
        } header: {
            Text(String("Materials"))
        }
    }
}

struct AddNewNodeMenuView: View {
    @State private var searchText: String = ""
    @State private var selection: JelloNodeType? = nil
    @State private var searchBarInFocus: Bool = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    let graph: JelloGraph
    let position: CGPoint
    
    // TODO: Replace with static variable defined elsewhere
    let items: OrderedDictionary<JelloNodeCategory, [JelloBuiltInNodeDefinition]>
    let includeMaterials : Bool
    
    
    @Query var functions: [JelloFunction]
    @Query var materials: [JelloMaterial]
    
    

    var selectionBinding : Binding<JelloNodeType?> {
        .init(get: { selection }, set: { selection = $0;
            if let definiteSelection = selection {
                switch definiteSelection {
                case .builtIn(let builtIn):
                    modelContext.insert(JelloNode(builtIn: builtIn, graph: graph, position: position))
                case .material(let materialId):
                    let material = materials.first(where: { $0.uuid == materialId})!
                    modelContext.insert(JelloNode(material: material, graph: graph, position: position))
                case .userFunction(let functionId):
                    let function = functions.first(where: { $0.uuid == functionId})!
                    modelContext.insert(JelloNode(function: function, graph: graph, position: position))
                }
            }
            dismiss()
        })
    }
    
    var body: some View {
        NavigationStack {
            List(selection: selectionBinding) {
                ForEach(items.keys, content: { category in
                    AddNewNodeMenuBuiltinSectionView(category: category, items: items[category]!)
                })
                if includeMaterials && !materials.isEmpty {
                    AddNewNodeMenuMaterialSectionView(items: materials)
                }
                if !functions.isEmpty {
                    AddNewNodeMenuUserFunctionSectionView(items: functions)
                }
            }.tint(.green).searchable(text: $searchText, isPresented: $searchBarInFocus).navigationTitle("Add Node").navigationBarTitleDisplayMode(.inline).onAppear { searchBarInFocus = true }
        }
    }
}