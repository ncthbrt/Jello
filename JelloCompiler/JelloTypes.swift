//
//  JelloAst.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/07.
//

import Foundation
import SpirvMacrosShared
import SpirvMacros

class JelloCompilerInput {
    var output: Output
    var graph: Graph
    
    init(output: Output, graph: Graph) {
        self.output = output
        self.graph = graph
    }
    
    enum Output {
        case materialOutput(MaterialOutput)
        case vertexOutput(VertexOutput)
        case previewOutput(PreviewOutput)
        
        var node: Node {
            switch self {
            case .materialOutput(let mo):
                return mo
            case .previewOutput(let po):
                return po
            case .vertexOutput(let vo):
                return vo
            }
        }
    }
}


class VertexOutput: Node {
    var id: UUID
    var inputPorts: [InputPort]
    var outputPorts: [InputPort] = []
    static func install() {}
    var branchTags: Set<UUID>

    init(id: UUID, inputPorts: [InputPort]) {
        self.id = id
        self.inputPorts = inputPorts
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

class MaterialOutput: Node {
    var id: UUID
    var inputPorts: [InputPort]
    var outputPorts: [InputPort] = []
    static func install() {}
    var branchTags: Set<UUID>
    
    init(id: UUID, inputPorts: [InputPort]) {
        self.id = id
        self.inputPorts = inputPorts
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

class PreviewOutput: Node {
    var id: UUID
    var inputPorts: [InputPort]
    var outputPorts: [InputPort] = []
    static func install() {}
    var branchTags: Set<UUID>
    
    init(id: UUID, inputPorts: [InputPort]) {
        self.id = id
        self.inputPorts = inputPorts
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

protocol Node {
    var id: UUID { get }
    static func install()
    var inputPorts: [InputPort] { get }
    var outputPorts: [InputPort] { get }
    
    var branchTags: Set<UUID> { get set }
}


class InputPort {
    var node: Node
    var incomingEdge: Edge?
    private var reservedSpirvId: UInt32? = nil;
    
    /// Starts a new branch
    var newBranchId: UUID?
    
    var inputSpirvId: UInt32? {
        reservedSpirvId ?? incomingEdge?.outputPort.reservedSpirvId
    }
    
    init(node: Node, incomingEdge: Edge? = nil) {
        self.node = node
        self.incomingEdge = incomingEdge
    }
    
    func reserveId() -> UInt32 {
        reservedSpirvId = #id
        return reservedSpirvId!
    }

}

class OutputPort {
    var node: Node
    var outgoingEdges: [Edge]
    private(set) var reservedSpirvId: UInt32?
    
    init(node: Node, outgoingEdges: [Edge]) {
        self.node = node
        self.outgoingEdges = outgoingEdges
        self.reservedSpirvId = nil
    }
    
    func reserveId() -> UInt32 {
        reservedSpirvId = #id
        return reservedSpirvId!
    }
}

class Edge {
    var inputPort: InputPort
    var outputPort: OutputPort
    
    init(inputPort: InputPort, outputPort: OutputPort) {
        self.inputPort = inputPort
        self.outputPort = outputPort
    }
}


class Graph {
    var nodes: [Node]
    var edges: [Edge]
    
    init(nodes: [Node], edges: [Edge]) {
        self.nodes = nodes
        self.edges = edges
    }
    
    convenience init() {
        self.init(nodes: [], edges: [])
    }
}
