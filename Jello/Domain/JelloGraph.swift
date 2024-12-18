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
import JelloCompilerStatic

@Model
final class JelloOutputPort {
    var name: String
    
    @Attribute(.unique) var uuid: UUID

    var baseDataType: JelloGraphDataType
    var currentDataType: JelloGraphDataType

    var node: JelloNode?
    var index: UInt8

    @Relationship(inverse: \JelloEdge.outputPort)
    var edges: [JelloEdge] = []
    
    fileprivate(set) var positionX: Float
    fileprivate(set) var positionY: Float
    
    
    fileprivate(set) var nodeOffsetX: Float
    fileprivate(set) var nodeOffsetY: Float
    
    @Transient
    var nodeOffset : CGPoint {
        CGPoint(x: CGFloat(nodeOffsetX), y: CGFloat(nodeOffsetY))
    }
    
    @Transient
    var worldPosition: CGPoint {
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

    init(uuid: UUID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode, nodePositionX: Float, nodePositionY: Float, nodeOffsetX: Float, nodeOffsetY: Float) {
        self.uuid = uuid
        self.name = name
        self.index = index
        self.baseDataType = dataType
        self.currentDataType = dataType
        self.edges = []
        self.node = node
        self.nodeOffsetX = nodeOffsetX
        self.nodeOffsetY = nodeOffsetY
        self.positionX = nodePositionX + nodeOffsetX
        self.positionY = nodePositionY + nodeOffsetY
    }
}

@Model
final class JelloInputPort {

    @Attribute(.unique) var uuid: UUID
    
    var index: UInt8
    
    var name: String
    var baseDataType: JelloGraphDataType
    var currentDataType: JelloGraphDataType
    
    var node: JelloNode?

    @Relationship(inverse: \JelloEdge.inputPort)
    var edge: JelloEdge? = nil
    
    var positionX: Float
    var positionY: Float
    
    var nodeOffsetX: Float
    var nodeOffsetY: Float
    
    @Transient
    var nodeOffset : CGPoint {
        CGPoint(x: CGFloat(nodeOffsetX), y: CGFloat(nodeOffsetY))
    }
    
    @Transient
    var worldPosition: CGPoint {
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
    
    init(uuid: UUID, index: UInt8, name: String, dataType: JelloGraphDataType, node: JelloNode, nodePositionX: Float, nodePositionY: Float, nodeOffsetX: Float, nodeOffsetY: Float) {
        self.uuid = uuid
        self.index = index
        self.name = name
        self.baseDataType = dataType
        self.currentDataType = dataType
        self.node = node
        self.positionX = nodePositionX + nodeOffsetX
        self.positionY = nodePositionY + nodeOffsetY
        self.nodeOffsetX = nodeOffsetX
        self.nodeOffsetY = nodeOffsetY
    }
    
}



@Model
final class JelloNode  {

    @Transient
    var name: String? {
        switch nodeType {
        case .builtIn(let builtInType):
            return String(describing: builtInType)
        case .userFunction(_):
            return "function?.name"
        case .material(_):
            return "material?.name"
        }
    }

    @Attribute(.unique) var uuid: UUID
    var graph: JelloGraph?
    var material: JelloMaterial?
    var function: JelloFunction?
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNodeData.node)
    var data: [JelloNodeData] = []
    
    fileprivate(set) var minX: Float
    fileprivate(set) var minY: Float
    fileprivate(set) var maxX: Float
    fileprivate(set) var maxY: Float
    fileprivate(set) var width: Float
    fileprivate(set) var height: Float
    
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
                    port.worldPosition = self.position + port.nodeOffset
                }
                for port in outputPorts {
                    port.worldPosition = self.position + port.nodeOffset
                }

            }
        }
    }
    
    private var builtIn: Int
    
    @Transient
    var nodeType: JelloNodeType {
        if let m = material {
            JelloNodeType.material(m.uuid)
        } else if let f = function {
            JelloNodeType.userFunction(f.uuid)
        } else {
            JelloNodeType.builtIn(JelloBuiltInNodeSubtype.init(rawValue: builtIn)!)
        }
    }
    
    
    @Relationship(deleteRule: .cascade, inverse: \JelloInputPort.node)
    private var inputPorts: [JelloInputPort] = []
    
    @Relationship(deleteRule: .cascade, inverse: \JelloOutputPort.node)
    private var outputPorts: [JelloOutputPort] = []
    
    
    private init(builtIn: JelloBuiltInNodeSubtype?, material: JelloMaterial?, function: JelloFunction?, graph: JelloGraph, uuid: UUID, positionX: Float, positionY: Float, width: Float, height: Float) {
        self.builtIn = builtIn?.rawValue ?? 0
        self.graph = graph
        self.uuid = uuid
        self.material = material
        self.function = function
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        minX = Float(positionX) - Float(width) / 2
        maxX = Float(positionX) + Float(width) / 2
        minY = Float(positionY) - Float(height) / 2
        maxY = Float(positionY) + Float(height) / 2
    }
    
    
    convenience init(material: JelloMaterial, graph: JelloGraph, position: CGPoint) {
        self.init(builtIn: nil, material: material, function: nil, graph: graph, uuid: UUID(), positionX: Float(position.x), positionY: Float(position.y), width: 0, height: 0)
    }
    
    convenience init(function: JelloFunction, graph: JelloGraph, position: CGPoint) {
        self.init(builtIn: nil, material: nil, function: function, graph: graph, uuid: UUID(), positionX: Float(position.x), positionY: Float(position.y), width: 0, height: 0)
    }
    
    
    convenience init(builtIn: JelloBuiltInNodeSubtype, graph: JelloGraph, position: CGPoint) {
        self.init(builtIn: builtIn, material: nil, function: nil, graph: graph, uuid: UUID(), positionX: Float(position.x), positionY: Float(position.y), width: 0, height: 0)
    }

}

@Model
final class JelloEdge {
  
    @Attribute(.unique) var uuid: UUID

    var graph: JelloGraph?
    
    var dataType: JelloGraphDataType
    
    var outputPort: JelloOutputPort?
    
    var inputPort: JelloInputPort?

    
    fileprivate(set) var minX: Float
    fileprivate(set) var minY: Float
    fileprivate(set) var maxX: Float
    fileprivate(set) var maxY: Float
    
    fileprivate(set) var startPositionX: Float
    fileprivate(set) var startPositionY: Float
    
    fileprivate(set) var endPositionX: Float
    fileprivate(set) var endPositionY: Float
    
    fileprivate(set) var freeEndPositionX: Float
    fileprivate(set) var freeEndPositionY: Float
    
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
                if port.node?.graph?.uuid == graphId && JelloGraphDataType.isPortTypeCompatible(edge: dataType, port: port.currentDataType) && (port.edge == nil || port.edge == self) && !dependencies.contains(port.node?.uuid ?? UUID()) {
                    let portPosition = port.worldPosition
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
            
            
            if let port = closestPort, let endNodeId = port.node?.uuid, let outputPortId = outputPort?.uuid, let startNodeId = outputPort?.node?.uuid {
                self.endPositionX = port.positionX
                self.endPositionY = port.positionY

                if self.inputPort != port {
                    let outputPort = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.uuid == outputPortId }))) ?? []).first!
                    let startNode = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.uuid == startNodeId }))) ?? []).first!
                    let startNodeController = JelloNodeControllerFactory.getController(startNode)
                    startNodeController.onOutputPortDisconnected(port: outputPort, edge: self)
                    if let oldInputPortId = self.inputPort?.uuid, let oldEndNodeId = self.inputPort?.node?.uuid {
                        let oldInputPort = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.uuid == oldInputPortId }))) ?? []).first!
                        let oldEndNode = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.uuid == oldEndNodeId }))) ?? []).first!
                        let oldEndNodeController = JelloNodeControllerFactory.getController(oldEndNode)
                        oldEndNodeController.onInputPortDisconnected(port: oldInputPort, edge: self)
                    }
                    self.inputPort = port
                    let newEndNode = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.uuid == endNodeId }))) ?? []).first!
                    let newEndNodeController = JelloNodeControllerFactory.getController(newEndNode)
                    startNodeController.onOutputPortConnected(port: outputPort, edge: self)
                    newEndNodeController.onInputPortConnected(port: port, edge: self)

                    withAnimation(.easeIn.speed(0.5)) {
                        if let graphId = graph?.uuid, let modelContext = modelContext {
                            try! updateTypesInGraph(modelContext: modelContext, graphId: graphId)
                        }
                        self.dataType = JelloGraphDataType.getMostSpecificType(a: outputPort.currentDataType, b: port.currentDataType)
                    }
                }
            } else {
                if let outputPortId = outputPort?.uuid, let startNodeId = outputPort?.node?.uuid, let oldInputPortId = self.inputPort?.uuid, let oldEndNodeId = self.inputPort?.node?.uuid  {
                    let outputPort = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.uuid == outputPortId }))) ?? []).first!
                    let startNode = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.uuid == startNodeId }))) ?? []).first!
                    let startNodeController = JelloNodeControllerFactory.getController(startNode)
                    startNodeController.onOutputPortDisconnected(port: outputPort, edge: self)
                    
                    let oldInputPort = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.uuid == oldInputPortId }))) ?? []).first!
                    let oldEndNode = ((try! modelContext?.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.uuid == oldEndNodeId }))) ?? []).first!
                    let oldEndNodeController = JelloNodeControllerFactory.getController(oldEndNode)
                    oldEndNodeController.onInputPortDisconnected(port: oldInputPort, edge: self)
                    self.inputPort = nil
                    withAnimation(.easeIn) {
                        if let graphId = graph?.uuid, let modelContext = modelContext {
                            try! updateTypesInGraph(modelContext: modelContext, graphId: graphId)
                        }
                        self.dataType = outputPort.currentDataType
                    }
                }
            }
            
            self.minX = min(startPositionX, endPositionX)
            self.maxX = max(startPositionX, endPositionX)
            self.minY = min(startPositionY, endPositionY)
            self.maxY = max(startPositionY, endPositionY)
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

    convenience init(graph: JelloGraph, outputPort: JelloOutputPort, inputPort: JelloInputPort) {
        self.init(graph: graph, uuid: UUID(), dataType: JelloGraphDataType.getMostSpecificType(a: outputPort.currentDataType, b: inputPort.currentDataType), outputPort: outputPort, inputPort: inputPort, startPositionX: outputPort.positionX, startPositionY: outputPort.positionY, endPositionX: inputPort.positionX, endPositionY: inputPort.positionY)
    }
    
    convenience init(graph: JelloGraph, outputPort: JelloOutputPort) {
        self.init(graph: graph, uuid: UUID(), dataType: JelloGraphDataType.getMostSpecificType(a: outputPort.currentDataType, b: .any), outputPort: outputPort, inputPort: nil, startPositionX: outputPort.positionX, startPositionY: outputPort.positionY, endPositionX: outputPort.positionX, endPositionY: outputPort.positionY)
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
        self.minX = min(startPositionX, endPositionX)
        self.maxX = max(startPositionX, endPositionX)
        self.minY = min(startPositionY, endPositionY)
        self.maxY = max(startPositionY, endPositionY)
    }
}

@Model
final class JelloGraph {
    @Attribute(.unique) var uuid: UUID
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.graph)
    private var nodes: [JelloNode] = []
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.graph)
    private var edges: [JelloEdge] = []
    
    var material: JelloMaterial?
    var function: JelloFunction?
    
    init(uuid: UUID, material: JelloMaterial?, function: JelloFunction?) {
        self.uuid = uuid
        self.material = material
        self.function = function
    }
    
    convenience init(material: JelloMaterial){
        self.init(uuid: UUID(), material: material, function: nil)
    }
    
    convenience init(function: JelloFunction){
        self.init(uuid: UUID(), material: nil, function: function)
    }
}


