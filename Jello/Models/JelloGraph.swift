//
//  JelloGraph.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData
import OrderedCollections


enum JelloGraphDataType: Int, Codable {
    case any = 0
    case anyFloat = 1
    case float4 = 2
    case float3 = 3
    case float2 = 4
    case float = 5
    case int = 6
    case bool = 7
    case anyTexture = 8
    case texture1d = 9
    case texture2d = 10
    case texture3d = 11
}

@Model
final class JelloOutputPort {
    var name: String
    var id: String { name }
    var dataType: JelloGraphDataType
    
    var node: JelloNode
    
    @Relationship(deleteRule: .cascade, inverse: \JelloEdge.outputPort)
    var edges: [JelloEdge]
    
    
    var position: CGPoint {
        didSet {
            updateEdgePositions()
        }
    }

    
    init(name: String, dataType: JelloGraphDataType, node: JelloNode, edges: [JelloEdge], position: CGPoint) {
        self.name = name
        self.dataType = dataType
        self.edges = []
        self.node = node
        self.position = position
    }
    
    func updateEdgePositions() {
        
    }
}

@Model
final class JelloInputPort {

    @Attribute(.unique) var id: UUID
    
    var name: String
    var dataType: JelloGraphDataType
    
    var node: JelloNode
    
    
    @Relationship(deleteRule: .cascade, inverse: \JelloEdge.inputPort)
    var edge: JelloEdge?
    
    var position: CGPoint {
        didSet {
            updateEdgePosition()
        }
    }
    
    init(id: ID, name: String, dataType: JelloGraphDataType, node: JelloNode, edge: JelloEdge?, position: CGPoint) {
        self.id = id
        self.name = name
        self.dataType = dataType
        self.node = node
        self.edge = edge
        self.position = position
    }
    
    func updateEdgePosition() {
        
    }
}


@Model
final class JelloNode  {
    
    @Attribute(.unique) var id: UUID
    var graph: JelloGraph
    
    var position: CGPoint {
        didSet {
            updatePortPositions()
        }
    }
    
    
    @Relationship(deleteRule: .cascade, inverse: \JelloInputPort.node)
    var inputPorts: [JelloInputPort]
    
    @Relationship(deleteRule: .cascade, inverse: \JelloOutputPort.node)
    var outputPorts: [JelloOutputPort]
    
    
    init(graph: JelloGraph, id: ID, inputPorts: [JelloInputPort], outputPorts: [JelloOutputPort], position: CGPoint) {
        self.graph = graph
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        self.position = position
    }
  
    func updatePortPositions() {
        
    }
}

@Model
final class JelloEdge {
  
    @Attribute(.unique) var id: UUID

    var graph: JelloGraph
    
    var dataType: JelloGraphDataType
    
    var outputPort: JelloOutputPort
    
    var inputPort: JelloInputPort?

    init(graph: JelloGraph, id: ID, dataType: JelloGraphDataType, outputPort: JelloOutputPort, inputPort: JelloInputPort?) {
        self.graph = graph
        self.id = id
        self.dataType = dataType
        self.inputPort = inputPort
        self.outputPort = outputPort
    }
}

@Model
final class JelloGraph {
    @Attribute(.unique) var id: UUID
    

    @Relationship(deleteRule: .cascade, inverse: \JelloNode.graph)
    var nodes: [JelloNode]
    
    @Relationship(deleteRule: .cascade, inverse: \JelloEdge.graph)
    var edges: [JelloEdge]

    init(id: ID, nodes: [JelloNode], edges: [JelloEdge]) {
        self.id = id
        self.nodes = nodes
        self.edges = edges
    }
    
    convenience init(){
        self.init(id: UUID(), nodes: [], edges: [])
    }
}


