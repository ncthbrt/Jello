//
//  JelloAst.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/07.
//

import Foundation
import SpirvMacrosShared
import SpirvMacros

public class JelloCompilerInput {
    public var output: Output
    public var graph: Graph
    
    public init(output: Output, graph: Graph) {
        self.output = output
        self.graph = graph
    }
    
    public enum Output {
        case materialOutput(MaterialOutput)
        case vertexOutput(VertexOutput)
        case previewOutput(PreviewOutput)
        
        public var node: Node {
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


public class VertexOutput: Node {
    public var id: UUID
    public var inputPorts: [InputPort]
    public var outputPorts: [OutputPort] = []
    public static func install() {}
    public var branchTags: Set<UUID>
    
    public init(id: UUID, inputPorts: [InputPort]) {
        self.id = id
        self.inputPorts = inputPorts
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

public class MaterialOutput: Node {
    public var id: UUID
    public var inputPorts: [InputPort]
    public var outputPorts: [OutputPort] = []
    public static func install() {}
    public var branchTags: Set<UUID>
    public init(id: UUID, inputPort: InputPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

public class PreviewOutput: Node {
    public var id: UUID
    public var inputPorts: [InputPort]
    public var outputPorts: [OutputPort] = []
    public static func install() {}
    public var branchTags: Set<UUID>
    
    public init(id: UUID, inputPort: InputPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
        inputPort.node = self
    }
}

public protocol Node {
    var id: UUID { get }
    static func install()
    var inputPorts: [InputPort] { get }
    var outputPorts: [OutputPort] { get }
    var branchTags: Set<UUID> { get set }
}


public protocol BranchNode {
    var subNodes: [UUID: [Node]] {get set}
    var branches: [UUID] {get}
}


public class IfElseNode : Node, BranchNode {
    public var id: UUID
    public var inputPorts: [InputPort]
    public var outputPorts: [OutputPort] = []
    public static func install() {}
    public var branchTags: Set<UUID> = []
    public var subNodes: [UUID: [Node]] = [:]
    public var branches: [UUID]
    public var trueBranchTag: UUID
    public var falseBranchTag: UUID
    
    public init(id: UUID, condition: InputPort, ifTrue: InputPort, ifFalse: InputPort, outputPort: OutputPort) {
        self.id = id
        self.inputPorts =  [condition, ifTrue, ifFalse]
        self.outputPorts = [outputPort]
        self.trueBranchTag = UUID()
        self.falseBranchTag = UUID()
        self.branches = [trueBranchTag, falseBranchTag]
        ifTrue.newBranchId = trueBranchTag
        ifFalse.newBranchId = falseBranchTag
    }
}

public class InputPort {
    public var node: Node?
    public var incomingEdge: Edge?
    private var reservedSpirvId: UInt32? = nil;
    
    /// Starts a new branch
    public var newBranchId: UUID?
    
    public var inputSpirvId: UInt32? {
        reservedSpirvId ?? incomingEdge?.outputPort.reservedSpirvId
    }
    
    public init() {
        self.node = nil
        self.incomingEdge = nil
    }
    
    public func getOrReserveId() -> UInt32 {
        if let id = reservedSpirvId {
            return id
        }
        reservedSpirvId = #id
        return reservedSpirvId!
    }

}

public class OutputPort {
    public var node: Node? = nil
    public var outgoingEdges: [Edge] = []
    private(set) public var reservedSpirvId: UInt32? = nil
    
    public init() {
    }
    
    
    public func getOrReserveId() -> UInt32 {
        if let id = reservedSpirvId {
            return id
        }
        reservedSpirvId = #id
        return reservedSpirvId!
    }
}

public class Edge {
    public var inputPort: InputPort
    public var outputPort: OutputPort
    
    public init(inputPort: InputPort, outputPort: OutputPort) {
        self.inputPort = inputPort
        self.outputPort = outputPort
        self.inputPort.incomingEdge = self
        self.outputPort.outgoingEdges.append(self)
    }
}


public class Graph {
    public var nodes: [Node]
    
    public init(nodes: [Node]) {
        self.nodes = nodes
    }
    
    public convenience init() {
        self.init(nodes: [])
    }
}
