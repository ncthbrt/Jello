//
//  ProjectSidebarView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftUI
import SwiftData

struct ListEntryCategoryView<V: View>: View {
    let color: Color
    @ViewBuilder let label: V
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 2).fill(color).padding().frame(maxWidth: 110, maxHeight: 50)
            label.font(.caption.smallCaps().monospaced()).foregroundStyle(color)
        }
    }
    
}

struct MaterialListEntryView: View {
    @Environment(\.modelContext) private var modelContext
    let material: JelloMaterial
    let selected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(material.name).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(selected ? .black : (colorScheme == .dark ? .white : .black))
            Spacer()
            ListEntryCategoryView(color: selected ? .black: .blue, label: {Text("Material")}).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.borderless)
        .contextMenu(ContextMenu(menuItems: {
            Button {} label: {
                Image(systemName: "square.and.arrow.up")    
                Text("Export")
            }
            Button {
            } label: {
                Image(systemName: "doc.on.doc")
                Text("Duplicate")
            }
            Button(role: .destructive) {
                modelContext.delete(material)
            }
        label: {
            Image(systemName: "trash")
            Text("Delete")
        }
        })).background(selected ? .blue : .clear)

    }
}

struct FunctionListEntryView: View {
    @Environment(\.modelContext) private var modelContext
    
    let function: JelloFunction
    let selected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        HStack {
            Text(function.name).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(selected ? .black : .white)
            Spacer()
            ListEntryCategoryView(color: selected ? .black : .orange, label: {Text("Function")}).frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(selected ? .black : (colorScheme == .dark ? .white : .black))
        }.contextMenu(ContextMenu(menuItems: {
            Button {
            } label: {
                Image(systemName: "doc.on.doc")
                Text("Duplicate")
            }
            Button(role: .destructive) {
                modelContext.delete(function)
            }
        label: {
            Image(systemName: "trash")
            Text("Delete")
        }
        }))
    }
}

struct SidebarListEntryView : View {
    var document: JelloDocument
    let selected: Bool

    var body: some View {
        switch(document) {
        case .material(let material):
            MaterialListEntryView(material: material, selected: selected)
        case .function(let function):
            FunctionListEntryView(function: function, selected: selected)
        }
    }
}

fileprivate struct ProjectSidebarViewResultsList : View {
    @Bindable var navigation: ProjectNavigation
    
    @Query private var materials: [JelloMaterial]
    @Query private var functions: [JelloFunction]

    private var documents : [JelloDocument] {
        let materials = materials.map({JelloDocument.material($0)})
        let functions = functions.map({JelloDocument.function($0)})
        var results = materials
        results.append(contentsOf: functions)
        return results.sorted(by: {a, b in a.name.localizedCompare(b.name) == .orderedDescending })
    }
    
    init(navigation: ProjectNavigation, isSearching: Bool) {
        self.navigation = navigation
        _functions = Query(filter: Self.functionPredicate(searchText: navigation.searchText, searchTag: navigation.searchTag, isSearching: isSearching))
        _materials = Query(filter: Self.materialPredicate(searchText: navigation.searchText, searchTag: navigation.searchTag, isSearching: isSearching))
    }

    var accentColor: Color {
        switch(navigation.selectedItem?.type){
            case .function:
                return Color.orange
            case .material:
                return Color.blue
            case .none:
                return Color.clear
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List(documents, id: \JelloDocument.reference, selection: $navigation.selectedItem) {
                document in SidebarListEntryView(document: document, selected: navigation.selectedItem?.id == document.id)
            }.tint(self.accentColor)
        }
    }
    

    static func materialPredicate(
        searchText: String,
        searchTag: JelloDocumentSearchTag,
        isSearching: Bool
    ) -> Predicate<JelloMaterial> {
        let materialSearchTag = JelloDocumentSearchTag.material
        let allSearchTag = JelloDocumentSearchTag.all

        return #Predicate<JelloMaterial> { material in
            !isSearching ||
            (
                (searchText.isEmpty || material.name.contains(searchText))
                &&
                (searchTag == materialSearchTag || searchTag == allSearchTag)
             )
        }
    }
    
    static func functionPredicate(
        searchText: String,
        searchTag: JelloDocumentSearchTag,
        isSearching: Bool
    ) -> Predicate<JelloFunction> {
        let functionSearchTag = JelloDocumentSearchTag.function
        let allSearchTag = JelloDocumentSearchTag.all
        
        return #Predicate<JelloFunction> { function in
            !isSearching ||
            (
                (searchText.isEmpty || function.name.contains(searchText))
                &&
                (functionSearchTag == searchTag || allSearchTag == searchTag)
            )
        }
    }
}


struct ProjectSidebarView: View {
    @Environment(ProjectNavigation.self) private var navigation: ProjectNavigation
    @State var isSearching: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ProjectSidebarViewResultsList(navigation: navigation, isSearching: isSearching)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    ControlGroup {
                        Button { addMaterial() } label: { Text("New Material") }
                        Button { addFunction() } label: { Text("New Function") }
                    } label: {
                        Image(systemName: "plus").frame(width: 24, height: 24)
                    }.controlGroupStyle(.palette)
                    NavigationLink (destination: { Text("Project Settings") }, label: {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 24, height: 24)
                    })
                }
            }
            .searchable(text: .init(get: { navigation.searchText }, set: { navigation.searchText = $0 }), isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always))
            .searchScopes(.init(get:{ navigation.searchTag }, set: { navigation.searchTag = $0 })) {
                Text("All").background(.blue).tag(JelloDocumentSearchTag.all)
                Text("Func").background(.blue).tag(JelloDocumentSearchTag.function)
                Text("Material").tag(JelloDocumentSearchTag.material)
                Text("Model").background(.red).tag(JelloDocumentSearchTag.model)
                Text("Texture").tag(JelloDocumentSearchTag.texture)
            }
    }
    
    
    private func addMaterial() {
        let material = JelloMaterial.newMaterial(modelContext: modelContext)
        navigation.selectedItem = .material(material.uuid)
    }
    
    private func addFunction(){
        let jelloFunction = JelloFunction()
        modelContext.insert(jelloFunction)
        navigation.selectedItem = .function(jelloFunction.uuid)
    }
}



#Preview {
    ProjectSidebarView()
        .environment(ProjectNavigation())
        .modelContainer(for: [JelloMaterial.self, JelloFunction.self], inMemory: true)

}
