//
//  JelloAst.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/07.
//

import Foundation
import SpirvMacrosShared
import SpirvMacros

public enum JelloGraphDataType: Int, Codable, CaseIterable {
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
    case anyMaterial = 12
    case slabMaterial = 13
}

public class JelloCompilerInput {
    public var output: Output
    public var graph: CompilerGraph
    
    public init(output: Output, graph: CompilerGraph) {
        self.output = output
        self.graph = graph
    }
    
    public enum Output {
        case materialOutput(MaterialOutputCompilerNode)
        case previewOutput(PreviewOutputCompilerNode)
        
        public var node: CompilerNode {
            switch self {
            case .materialOutput(let mo):
                return mo
            case .previewOutput(let po):
                return po
            }
        }
    }
}


public class MaterialOutputCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public static func install() {}
    public var branchTags: Set<UUID>
    public init(id: UUID, inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}

public class PreviewOutputCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public static func install() {}
    public var branchTags: Set<UUID>
    
    public init(id: UUID, inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
        inputPort.node = self
    }
}

public protocol CompilerNode {
    var id: UUID { get }
    static func install()
    var inputPorts: [InputCompilerPort] { get }
    var outputPorts: [OutputCompilerPort] { get }
    var branchTags: Set<UUID> { get set }
}


public protocol BranchCompilerNode {
    var subNodes: [UUID: [CompilerNode]] {get set}
    var branches: [UUID] {get}
}


public class IfElseCompilerNode : CompilerNode, BranchCompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public static func install() {}
    public var branchTags: Set<UUID> = []
    public var subNodes: [UUID: [CompilerNode]] = [:]
    public var branches: [UUID]
    public var trueBranchTag: UUID
    public var falseBranchTag: UUID
    
    public init(id: UUID, condition: InputCompilerPort, ifTrue: InputCompilerPort, ifFalse: InputCompilerPort, outputPort: OutputCompilerPort) {
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

public class InputCompilerPort {
    public var node: CompilerNode?
    public var incomingEdge: CompilerEdge?
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

public class OutputCompilerPort {
    public var node: CompilerNode? = nil
    public var outgoingEdges: [CompilerEdge] = []
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

public class CompilerEdge {
    public var inputPort: InputCompilerPort
    public var outputPort: OutputCompilerPort
    
    public init(inputPort: InputCompilerPort, outputPort: OutputCompilerPort) {
        self.inputPort = inputPort
        self.outputPort = outputPort
        self.inputPort.incomingEdge = self
        self.outputPort.outgoingEdges.append(self)
    }
}


public class CompilerGraph {
    public var nodes: [CompilerNode]
    
    public init(nodes: [CompilerNode]) {
        self.nodes = nodes
    }
    
    public convenience init() {
        self.init(nodes: [])
    }
}
