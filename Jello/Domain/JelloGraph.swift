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
    
    @Attribute(.unique) var uuid: UUID

    var dataType: JelloGraphDataType
    
    var node: JelloNode?
    var index: UInt8

    @Relationship(inverse: \JelloEdge.outputPort)
    private var edges: [JelloEdge]
    
    fileprivate(set) var positionX: Float
    fileprivate(set) var positionY: Float
    
    @Transient
    var position: CGPoint {
        get { CGPoint(x: CGFloat(positionX), y: CGFloat(positionY)) }
        set {
            positionX = Float(newValue.x)
            positionY = Float(newValue.y)
            if let context = modelContext {
                let edges = (try? context.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge> { $0.outputPort?.uuid == uuid }))) ?? []
                for edge in edges {
                    edge.startPositionX = positionX
                    edge.startPositionY = positionY
                }
            }
        }
    }

    init(uuid: UUID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode, edges: [JelloEdge], positionX: Float, positionY: Float) {
        self.uuid = uuid
        self.name = name
        self.index = index
        self.dataType = dataType
        self.edges = []
        self.node = node
        self.positionX = positionX
        self.positionY = positionY
    }
}

@Model
final class JelloInputPort {

    @Attribute(.unique) var uuid: UUID
    
    var index: UInt8
    
    var name: String
    var dataType: JelloGraphDataType
    
    var node: JelloNode?

    @Relationship(inverse: \JelloEdge.inputPort)
    var edge: JelloEdge? = nil
    
    fileprivate(set) var positionX: Float
    fileprivate(set) var positionY: Float
    
    @Transient
    var position: CGPoint {
        get { CGPoint(x: CGFloat(positionX), y: CGFloat(positionY)) }
        set {
            positionX = Float(newValue.x)
            positionY = Float(newValue.y)
            if let context = modelContext {
                let edges = (try? context.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge> { $0.inputPort?.uuid == uuid }))) ?? []
                for edge in edges {
                    edge.endPositionX = positionX
                    edge.endPositionY = positionY
                }
            }
        }
    }
    
    init(uuid: UUID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode, positionX: Float, positionY: Float) {
        self.uuid = uuid
        self.index = index
        self.name = name
        self.dataType = dataType
        self.node = node
        self.positionX = positionX
        self.positionY = positionY
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

    @Attribute(.unique) var uuid: UUID
    var graph: JelloGraph?
    var material: JelloMaterial?
    
    var function: JelloFunction?

    fileprivate(set) var minX: Float
    fileprivate(set) var minY: Float
    fileprivate(set) var maxX: Float
    fileprivate(set) var maxY: Float
    private var width: Float
    private var height: Float
    
    fileprivate(set) var positionX: Float
    fileprivate(set) var positionY: Float
    

    @Transient var size: CGSize {
        get { CGSize(width: CGFloat(width), height: CGFloat(height)) }
        set {
            width = Float(newValue.width)
            height = Float(newValue.height)
            minX = positionX - width / 2
            maxX = positionX + width / 2
            minY = positionY - height / 2
            maxY = positionY + height / 2
        }
    }
    
    @Transient
    var position: CGPoint {
        get {  CGPoint(x: CGFloat(positionX), y: CGFloat(positionY)) }
        set {
            positionX = Float(newValue.x)
            positionY = Float(newValue.y)
            minX = positionX - width / 2
            maxX = positionX + width / 2
            minY = positionY - height / 2
            maxY = positionY + height / 2
            if let context = modelContext {
                let inputPorts = (try? context.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort> { $0.node?.uuid == uuid }, sortBy: [SortDescriptor(\.index)]))) ?? []
                let outputPorts = (try? context.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort> { $0.node?.uuid == uuid }, sortBy: [SortDescriptor(\.index)]))) ?? []
                for port in inputPorts {
                    port.position = self.getInputPortWorldPosition(index: port.index, inputPortCount: inputPorts.count, outputPortCount: outputPorts.count)
                }
                for port in outputPorts {
                    port.position = self.getOutputPortWorldPosition(index: port.index, inputPortCount: inputPorts.count, outputPortCount: outputPorts.count)
                }

            }
        }
    }
    
    var type: JelloNodeType
     
    @Relationship(deleteRule: .cascade, inverse: \JelloInputPort.node)
    private var inputPorts: [JelloInputPort]
    
    @Relationship(deleteRule: .cascade, inverse: \JelloOutputPort.node)
    private var outputPorts: [JelloOutputPort]
    
    
    private init(type: JelloNodeType, material: JelloMaterial?, function: JelloFunction?, graph: JelloGraph, uuid: UUID, inputPorts: [JelloInputPort], outputPorts: [JelloOutputPort], position: CGPoint, size: CGSize) {
        self.type = type
        self.graph = graph
        self.uuid = uuid
        self.material = material
        self.function = function
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        positionX = Float(position.x)
        positionY = Float(position.y)
        width = Float(size.width)
        height = Float(size.height)
        minX = Float(position.x) - Float(size.width) / 2
        maxX = Float(position.x) + Float(size.width) / 2
        minY = Float(position.y) - Float(size.height) / 2
        maxY = Float(position.y) + Float(size.height) / 2
    }
    
    
    convenience init(material: JelloMaterial, graph: JelloGraph, position: CGPoint) {
        self.init(type: .material(material.uuid), material: material, function: nil, graph: graph, uuid: UUID(), inputPorts: [], outputPorts: [], position: position, size: .zero)
    }
    
    convenience init(function: JelloFunction, graph: JelloGraph, position: CGPoint) {
        self.init(type: .userFunction(function.uuid), material: nil, function: function, graph: graph, uuid: UUID(), inputPorts: [], outputPorts: [], position: position, size: .zero)
    }
    
    
    convenience init(builtIn: JelloBuiltInNodeSubtype, graph: JelloGraph, position: CGPoint) {
        self.init(type: .builtIn(builtIn), material: nil, function: nil, graph: graph, uuid: UUID(), inputPorts: [], outputPorts: [], position: position, size: .zero)
    }

}

@Model
final class JelloEdge {
  
    @Attribute(.unique) var uuid: UUID

    var graph: JelloGraph?
    
    var dataType: JelloGraphDataType
    
    var outputPort: JelloOutputPort?
    
    var inputPort: JelloInputPort?
    
    
    fileprivate(set) var startPositionX: Float
    fileprivate(set) var startPositionY: Float
    
    var endPositionX: Float
    var endPositionY: Float
    
    var freeEndPositionX: Float
    var freeEndPositionY: Float
    
    @Transient
    var endPosition: CGPoint {
        get {
            if inputPort != nil {
                return CGPoint(x: CGFloat(endPositionX), y: CGFloat(endPositionY))
            } else {
                return CGPoint(x: CGFloat(freeEndPositionX), y: CGFloat(freeEndPositionY))
            }
        } set {
            var minDist: CGFloat = CGFloat.greatestFiniteMagnitude
            var closestPort: JelloInputPort? = nil
            let graphId = graph?.uuid
            
            let minX: Float = Float(newValue.x) - JelloEdge.maxEdgeSnapDistance
            let minY: Float = Float(newValue.y) - JelloEdge.maxEdgeSnapDistance
            let maxX: Float = Float(newValue.x) + JelloEdge.maxEdgeSnapDistance
            let maxY: Float = Float(newValue.y) + JelloEdge.maxEdgeSnapDistance
            
            let inputPorts = ((try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.positionX >= minX && $0.positionX <= maxX && $0.positionY >= minY && $0.positionY <= maxY }))) ?? [])
            var dependencies: Set<UUID> = []
            if inputPorts.count > 0 {
                dependencies = getDependencies()
            }
            for port in inputPorts {
                if port.node?.graph?.uuid == graphId && JelloGraphDataType.isPortTypeCompatible(edge: dataType, port: port.dataType) && (port.edge == nil || port.edge == self) && !dependencies.contains(port.node?.uuid ?? UUID()) {
                    let portPosition = port.position
                    let dist = (newValue - portPosition).magnitude()
                    if dist < minDist {
                        minDist = dist
                        closestPort = port
                    }
                }
            }


            self.freeEndPositionX = Float(newValue.x)
            self.freeEndPositionY = Float(newValue.y)
            self.endPositionX = Float(newValue.x)
            self.endPositionY = Float(newValue.y)
            
            if let port = closestPort {
                self.inputPort = port
                self.endPositionX = port.positionX
                self.endPositionY = port.positionY
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
    }
    
    
    @Transient
    var startPosition: CGPoint {
        return CGPoint(x: CGFloat(startPositionX), y: CGFloat(startPositionY))
    }
    
    func getDependencies() -> Set<UUID> {
        guard let node = outputPort?.node else {
            return Set()
        }
        var dependencies = Set<UUID>()
        var incomingNodes: Deque<UUID> = Deque([node.uuid])
        
        while let first = incomingNodes.popFirst() {
            dependencies.insert(first)
            let inputPorts = (try? modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.uuid == first }))) ?? []
            incomingNodes.append(contentsOf: inputPorts.compactMap{$0.edge?.outputPort?.node?.uuid})
        }
        return dependencies
    }

     
    init(graph: JelloGraph, uuid: UUID, dataType: JelloGraphDataType, outputPort: JelloOutputPort, inputPort: JelloInputPort?, startPositionX: Float, startPositionY: Float, endPositionX: Float, endPositionY: Float) {
        self.graph = graph
        self.uuid = uuid
        self.dataType = dataType
        self.inputPort = inputPort
        self.outputPort = outputPort
        self.freeEndPositionX = .zero
        self.freeEndPositionY = .zero
        self.startPositionX = startPositionX
        self.startPositionY = startPositionY
        self.endPositionX = endPositionX
        self.endPositionY = endPositionY
    }
}

@Model
final class JelloGraph {
    @Attribute(.unique) var uuid: UUID
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.graph)
    private var nodes: [JelloNode]

    @Relationship(inverse: \JelloNode.graph)
    private var edges: [JelloEdge]

    init(uuid: UUID, nodes: [JelloNode], edges: [JelloEdge]) {
        self.uuid = uuid
        self.nodes = nodes
        self.edges = edges
    }
    
    convenience init(){
        self.init(uuid: UUID(), nodes: [], edges: [])
    }
}


