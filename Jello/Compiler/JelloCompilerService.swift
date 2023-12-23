//
//  JelloCompiler.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/12/06.
//

import Foundation
import SwiftUI
import SwiftData
import JelloCompilerStatic

@Observable class JelloCompilerService {
    @ObservationIgnored private var modelContext: ModelContext?
    
    func initialize(modelContext: ModelContext){
        self.modelContext = modelContext
    }
    
    func compileMaterialOutput(id: UUID) async {
        
        if let someModelContext = modelContext {
            guard let someMaterial = try? someModelContext.fetch(FetchDescriptor<JelloMaterial>(predicate: #Predicate{ $0.uuid == id })).first  else {
                return
            }
            let graphId = someMaterial.graph.uuid
            
            guard let someGraph = try? someModelContext.fetch(FetchDescriptor<JelloGraph>(predicate: #Predicate{ $0.uuid == graphId })).first else {
                return
            }
            
            guard let nodes = try? someModelContext.fetch(FetchDescriptor<JelloNode>(predicate: #Predicate{ $0.graph?.uuid == graphId })) else {
                return
            }
            
            guard let outputNode = nodes.filter({ $0.type == .builtIn(.materialOutput) }).first else {
                return
            }
            
            guard let edges = try? someModelContext.fetch(FetchDescriptor<JelloEdge>(predicate: #Predicate{ $0.graph?.uuid == graphId })) else {
                return
            }



        }
    }
    
}
