//
//  ProjectPicker.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/02.
//

import SwiftUI
import SwiftData
import Foundation
import UniformTypeIdentifiers

struct ProjectPickerTile: View {
    let projectReference: JelloProjectReference
    let onOpen: () -> ()
    
    var body: some View {
        Button { onOpen() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20).stroke().fill(.white)
                Text(projectReference.name).font(.title3.monospaced()).foregroundStyle(.white)
            }.aspectRatio(1, contentMode: .fit).padding()
        }.buttonStyle(.borderless)
    }
    
}

class DummyDoc : Identifiable, Codable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jelloProject).suggestedFileName("Untitled Project")
    }
}

struct ProjectPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var projects: [JelloProjectReference]
    @State var showFilePicker : Bool = false
    @State var showFileExporter : Bool = false

    @Environment(\.openWindow) var openWindow
    @Environment(ProjectNavigation.self) private var navigation

    let columns = [GridItem(.flexible()), GridItem(.flexible()),GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    
    var body: some View {
        VStack {
            HStack {
                Circle().fill(Gradient(colors: [.green, .blue])).frame(width: 60, height: 60)
                Text("Jello").font(.largeTitle.monospaced()).padding().frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    showFileExporter = true
                } label: {
                    Image(systemName: "plus").resizable().frame(width: 30, height: 30)
                }.buttonStyle(.borderless).padding()
                    .fileExporter(isPresented: $showFileExporter, item: DummyDoc(), contentTypes: [.jelloProject], defaultFilename: "Untitled Project", onCompletion: { result in
                    switch result {
                    case .success(let file):
                        navigation.modelContainer = ProjectManagement.createNewJelloProjectFile(modelContext: modelContext, url: file)
                        break
                    case .failure(let err):
                        print(err)
                    }
                    })
                    .fileDialogConfirmationLabel(Text("Create"))
                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "square.and.arrow.down").resizable().frame(width: 30, height: 30)
                }
                .buttonStyle(.borderless)
                .padding()                
                .fileImporter(
                    isPresented: $showFilePicker,
                    allowedContentTypes: [.jelloProject],
                    allowsMultipleSelection: false
                ){ result in
                    switch result {
                    case .success(let files):
                        for file in files {
                            navigation.modelContainer = ProjectManagement.loadExistingJelloProjectFile(projects: projects, modelContext: modelContext, url: file)
                            break
                        }
                    case .failure(let error):
                        // handle error
                        print(error)
                    }
                }
            }
            if !projects.isEmpty {
                Text("Recents").font(.title).padding().frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(projects) { project in
                                ProjectPickerTile(projectReference: project, onOpen: {
                                    navigation.modelContainer = ProjectManagement.loadExistingJelloProjectFile(project: project)
                                })
                            }
                        }
                    }
                }
            } else {
                Spacer()
                Text("Create or Import a Jello project\nand it'll show up here").multilineTextAlignment(.center).font(.headline.italic().monospaced())
                Spacer()
            }
 
        }.padding().onOpenJelloProjectUrl()

    }
    
    
    
}



#Preview {
    ProjectPickerView()
        .modelContainer(for: [JelloProjectReference.self], inMemory: true)
}
