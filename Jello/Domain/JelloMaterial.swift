//
//  Item.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData

@Model
final class JelloMaterial {
    
    @Attribute(.unique) var uuid: UUID
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.material)
    private var dependants: [JelloNode]
    
    var name: String

    var userDescription: String

    @Relationship(deleteRule: .cascade)
    var graph: JelloGraph
    

    init(uuid: UUID, name: String, userDescription: String, graph: JelloGraph, dependants: [JelloNode]) {
        self.name = name
        self.uuid = uuid
        self.graph = graph
        self.userDescription = userDescription
        self.dependants = dependants
    }
    
    convenience init(){
        self.init(uuid: UUID(), name: "Untitled Material", userDescription: "", graph: JelloGraph(), dependants: [])
    }
    
    static func newMaterial(modelContext: ModelContext) -> JelloMaterial {
        let material = JelloMaterial()
        try! modelContext.transaction {
            modelContext.insert(material)
            var outputNode = JelloNode(builtIn: .materialOutput, graph: material.graph, position: CGPoint(x: JelloNode.standardNodeWidth * 3, y: 0))
            let outputNodeId = outputNode.uuid
            modelContext.insert(outputNode)
            outputNode = (try! modelContext.fetch(FetchDescriptor<JelloNode>(predicate: #Predicate{ $0.uuid == outputNodeId }))).first!

            let outputNodeController = JelloNodeControllerFactory.getController(outputNode)
            outputNodeController.setup(node: outputNode)
            
            var slabShaderNode = JelloNode(builtIn: .slabShader, graph: material.graph, position: CGPoint(x: JelloNode.standardNodeWidth, y: 0))
            modelContext.insert(slabShaderNode)
            let slabShaderNodeId = slabShaderNode.uuid
            slabShaderNode = (try! modelContext.fetch(FetchDescriptor<JelloNode>(predicate: #Predicate{ $0.uuid == slabShaderNodeId }))).first!
            let slabShaderNodeController = JelloNodeControllerFactory.getController(slabShaderNode)
            slabShaderNodeController.setup(node: slabShaderNode)
            

            let outputPort = try! modelContext.fetch(FetchDescriptor<JelloOutputPort>(predicate: #Predicate{ $0.node?.uuid == slabShaderNodeId }))
            let inputPort = try! modelContext.fetch(FetchDescriptor<JelloInputPort>(predicate: #Predicate { $0.node?.uuid == outputNodeId }))
            
            let edge = JelloEdge(graph: material.graph, outputPort: outputPort.first!, inputPort: inputPort.first!)
            modelContext.insert(edge)
        }
        return material
    }
}
