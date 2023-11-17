//
//  JelloGraph.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData
import OrderedCollections
import Collections
import SwiftUI

@Model
final class JelloOutputPort {
    var name: String
    
    @Attribute(.unique) var id: UUID

    var dataType: JelloGraphDataType
    
    var node: JelloNode?
    var index: UInt8

    @Relationship(inverse: \JelloEdge.outputPort)
    private var edges: [JelloEdge]
    

    init(id: ID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode, edges: [JelloEdge]) {
        self.id = id
        self.name = name
        self.index = index
        self.dataType = dataType
        self.edges = []
        self.node = node
    }
}

@Model
final class JelloInputPort {

    @Attribute(.unique) var id: UUID
    
    var index: UInt8
    
    var name: String
    var dataType: JelloGraphDataType
    
    var node: JelloNode?

    @Relationship(inverse: \JelloEdge.inputPort)
    var edge: JelloEdge? = nil
    
    init(id: ID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode) {
        self.id = id
        self.index = index
        self.name = name
        self.dataType = dataType
        self.node = node
    }
    
}


struct Point: Codable {
    let x: Float
    let y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    init(_ point: CGPoint) {
        self.x = Float(point.x)
        self.y = Float(point.y)
    }
}

extension CGPoint {
    init(_ point: Point){
        self.init(x: CGFloat(point.x), y: CGFloat(point.y))
    }
}

@Model
final class JelloNode  {

    var name: String? {
        switch type {
        case .builtIn(let builtInType):
            return String(describing: builtInType)
        case .userFunction(_):
            return function?.name
        case .material(_):
            return material?.name
        }
    }

    @Attribute(.unique) var id: UUID
    var graph: JelloGraph?
    
    private var persistedPosition: Point
    
    var material: JelloMaterial?
    
    var function: JelloFunction?

    
    @Transient
    var position: CGPoint {
        get {  CGPoint(persistedPosition) }
        set { persistedPosition = Point(newValue) }
    }
    
    var type: JelloNodeType
     
    @Relationship(deleteRule: .cascade, inverse: \JelloInputPort.node)
    private var inputPorts: [JelloInputPort]
    
    @Relationship(deleteRule: .cascade, inverse: \JelloOutputPort.node)
    private var outputPorts: [JelloOutputPort]
    
    
    private init(type: JelloNodeType, material: JelloMaterial?, function: JelloFunction?, graph: JelloGraph, id: ID, inputPorts: [JelloInputPort], outputPorts: [JelloOutputPort], position: CGPoint) {
        self.type = type
        self.graph = graph
        self.id = id
        self.material = material
        self.function = function
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        self.persistedPosition = Point(position)
    }
    
    
    convenience init(material: JelloMaterial, graph: JelloGraph, position: CGPoint) {
        self.init(type: .material(material.uuid), material: material, function: nil, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
    }
    
    convenience init(function: JelloFunction, graph: JelloGraph, position: CGPoint) {
        self.init(type: .userFunction(function.uuid), material: nil, function: function, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
    }
    
    
    convenience init(builtIn: JelloBuiltInNodeSubtype, graph: JelloGraph, position: CGPoint) {
        self.init(type: .builtIn(builtIn), material: nil, function: nil, graph: graph, id: UUID(), inputPorts: [], outputPorts: [], position: position)
    }

}

@Model
final class JelloEdge {
  
    @Attribute(.unique) var id: UUID

    var graph: JelloGraph?
    
    var dataType: JelloGraphDataType
    
    var outputPort: JelloOutputPort?
    
    var inputPort: JelloInputPort?

    private var freeEndPosition: Point
    
    @Transient
    var endPosition: CGPoint {
        if let iPort = inputPort, let node = iPort.node, !iPort.isDeleted {
            let nodeId = node.id
            let inputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.id == nodeId }))) ?? [])
            let outputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.id == nodeId }))) ?? [])
            return node.getInputPortWorldPosition(index: iPort.index, inputPortCount: inputPorts.count, outputPortCount: outputPorts.count)
        } else {
            return CGPoint(x: CGFloat(freeEndPosition.x), y: CGFloat(freeEndPosition.y))
        }
    }
    
    func getDependencies() -> Set<UUID> {
        
        guard let node = outputPort?.node else {
            return Set()
        }
        var dependencies = Set<UUID>()
        var incomingNodes: Deque<UUID> = Deque([node.id])
        
        while let first = incomingNodes.popFirst() {
            dependencies.insert(first)
            let inputPorts = (try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.id == first }))) ?? []
            incomingNodes.append(contentsOf: inputPorts.compactMap{$0.edge?.outputPort?.node?.id})
        }
        return dependencies
    }
    
    func setEndPosition(_ position: CGPoint) {
        modelContext?.processPendingChanges()
        let dependencies = getDependencies()
        var minDist: CGFloat = CGFloat.greatestFiniteMagnitude
        var closestPort: JelloInputPort? = nil
        // TODO: Test if this is performant enough at scale
        let graphId = graph?.id
        let nodes = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.graph?.id == graphId }))) ?? [])

        for node in nodes {
            if !dependencies.contains(node.id) {
                let nodeId = node.id
                let inputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.id == nodeId }))) ?? [])
                let outputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.id == nodeId }))) ?? [])
                for port in inputPorts {
                    if JelloGraphDataType.isPortTypeCompatible(edge: dataType, port: port.dataType) && (port.edge == nil || port.edge == self) {
                        let nodePosition = node.getInputPortWorldPosition(index: port.index, inputPortCount: inputPorts.count, outputPortCount: outputPorts.count)
                        let dist = (position - nodePosition).magnitude()
                        if dist < minDist && dist <= JelloEdge.maxEdgeSnapDistance {
                            minDist = dist
                            closestPort = port
                        }
                    }
                }
            }
        }

        self.freeEndPosition = Point(position)
        
        if let port = closestPort {
            self.inputPort = port
            withAnimation(.easeIn.speed(0.5)) {
                self.dataType = self.outputPort?.dataType ?? .any
                self.dataType = JelloGraphDataType.getMostSpecificType(a: outputPort?.dataType ?? .any, b: port.dataType)
            }
        } else {
            if let _ = self.inputPort {
                self.inputPort = nil
                withAnimation(.easeIn) {
                    self.dataType = self.outputPort?.dataType ?? .any
                }
            }
        }
    }
        

    var startPosition: CGPoint {
        
        if let oPort = outputPort, let node = oPort.node {
            let nodeId = node.id
            let inputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.id == nodeId }))) ?? [])
            let outputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.id == nodeId }))) ?? [])
            return node.getOutputPortWorldPosition(index: oPort.index, inputPortCount: inputPorts.count, outputPortCount: outputPorts.count)
        } else {
            return CGPoint(freeEndPosition)
        }
    }
     
    init(graph: JelloGraph, id: ID, dataType: JelloGraphDataType, outputPort: JelloOutputPort, inputPort: JelloInputPort?) {
        self.graph = graph
        self.id = id
        self.dataType = dataType
        self.inputPort = inputPort
        self.outputPort = outputPort
        self.freeEndPosition = Point(CGPoint.zero)
    }
}

@Model
final class JelloGraph {
    @Attribute(.unique) var id: UUID
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.graph)
    private var nodes: [JelloNode]

    @Relationship(inverse: \JelloNode.graph)
    private var edges: [JelloEdge]

    init(id: ID, nodes: [JelloNode], edges: [JelloEdge]) {
        self.id = id
        self.nodes = nodes
        self.edges = edges
    }
    
    convenience init(){
        self.init(id: UUID(), nodes: [], edges: [])
    }
}


