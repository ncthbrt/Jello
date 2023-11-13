//
//  JelloGraph.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData
import OrderedCollections


enum JelloBuiltInNodeType : Int, Codable, CaseIterable, Hashable {
    case add = 0
    case subtract = 1
    
    var name : String {
        return String(describing: self).capitalized
    }
    
    static func == (lhs: JelloBuiltInNodeType, rhs: JelloBuiltInNodeType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

enum JelloNodeType: Equatable, Hashable, Codable {
    case builtIn(JelloBuiltInNodeType)
    case userFunction(UUID)
    case material(UUID)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .builtIn(let t):
            hasher.combine(t.hashValue)
        case .userFunction(let id):
            hasher.combine(id)
        case .material(let id):
            hasher.combine(id)
        }
    }
    
    
    static func == (lhs: JelloNodeType, rhs: JelloNodeType) -> Bool {
        switch (lhs, rhs) {
        case (.builtIn(let a), .builtIn(let b)):
            return a == b
        case (.userFunction(let a), .userFunction(let b)):
            return a == b
        case (.material(let a), .material(let b)):
            return a == b
        default:
            return false
        }
    }
}


enum JelloNodeCategory: Int, Codable, CaseIterable, Identifiable {
    case math = 0
    case other = 1
    
    var id: Int { self.rawValue }
}

struct JelloBuiltInNodeDefinition : Hashable, Identifiable, Equatable {
    var id: JelloNodeType {.builtIn(type)}
    let description: String
    let previewImage: String
    let category: JelloNodeCategory
    let type: JelloBuiltInNodeType
    
    var name: String {
        return type.name
    }
    
    init(description: String, previewImage: String, category: JelloNodeCategory, type: JelloBuiltInNodeType) {
        self.description = description
        self.previewImage = previewImage
        self.category = category
        self.type = type
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
    
    
    static func == (lhs: JelloBuiltInNodeDefinition, rhs: JelloBuiltInNodeDefinition) -> Bool {
        return lhs.type == rhs.type
    }
}


enum JelloGraphDataType: Int, Codable, CaseIterable {
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
    
    @Attribute(.unique) var id: UUID

    var dataType: JelloGraphDataType
    
    var node: JelloNode
    
    @Relationship(deleteRule: .cascade, inverse: \JelloEdge.outputPort)
    var edges: [JelloEdge]
    
    
    var position: CGPoint {
        didSet {
            updateEdgePositions()
        }
    }

    
    init(id: ID, name: String, dataType: JelloGraphDataType, node: JelloNode, edges: [JelloEdge], position: CGPoint) {
        self.id = id
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


struct Point: Codable {
    let x: Float
    let y: Float
}

@Model
final class JelloNode  {

    var name: String {
        switch type {
        case .builtIn(let builtInType):
            return String(describing: builtInType)
        case .userFunction(_):
            return function!.name
        case .material(_):
            return material!.name
        }
    }

    @Attribute(.unique) var id: UUID
    var graph: JelloGraph
    
    var persistedPosition: Point
    
    var material: JelloMaterial?
    
    var function: JelloFunction?

    
    @Transient
    var position: CGPoint {
        get {  CGPoint(x: CGFloat(persistedPosition.x), y: CGFloat(persistedPosition.y)) }
        set { persistedPosition = Point(x: Float(newValue.x), y: Float(newValue.y)) }
    }
    
    var type: JelloNodeType
     
    @Relationship(deleteRule: .cascade, inverse: \JelloInputPort.node)
    var inputPorts: [JelloInputPort]
    
    @Relationship(deleteRule: .cascade, inverse: \JelloOutputPort.node)
    var outputPorts: [JelloOutputPort]
    
    
    private init(type: JelloNodeType, material: JelloMaterial?, function: JelloFunction?, graph: JelloGraph, id: ID, inputPorts: [JelloInputPort], outputPorts: [JelloOutputPort], position: CGPoint) {
        self.type = type
        self.graph = graph
        self.id = id
        self.material = material
        self.function = function
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        self.persistedPosition = Point(x: Float(position.x), y: Float(position.y))
    }
    
    
    convenience init(material: JelloMaterial, graph: JelloGraph, position: CGPoint) {
        self.init(type: .material(material.uuid), material: material, function: nil, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
    }
    
    convenience init(function: JelloFunction, graph: JelloGraph, position: CGPoint) {
        self.init(type: .userFunction(function.uuid), material: nil, function: function, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
    }
    
    
    convenience init(builtIn: JelloBuiltInNodeType, graph: JelloGraph, position: CGPoint) {
        self.init(type: .builtIn(builtIn), material: nil, function: nil, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
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


