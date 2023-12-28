//
//  JelloAst.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/07.
//

import Foundation
import SpirvMacrosShared
import SpirvMacros
import SPIRV_Headers_Swift
import simd

public enum ConstraintApplicationResult {
    case dirty([UUID])
    case unchanged
    case contradiction
}

public protocol PortConstraint {
    var ports: Set<UUID> {get}
    func apply(assignments: inout [UUID: JelloConcreteDataType], domains: [UUID: [JelloConcreteDataType]], port: UUID, type: JelloConcreteDataType) -> ConstraintApplicationResult
}



public class SameTypesConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply(assignments: inout [UUID: JelloConcreteDataType], domains: [UUID: [JelloConcreteDataType]], port: UUID, type: JelloConcreteDataType) -> ConstraintApplicationResult {
        var changed: [UUID] = []
        for p in ports {
            let a = assignments[p]
            if a == nil {
                let domain = domains[p] ?? []
                if !domain.contains(where: {$0 == type}) {
                    return .contradiction
                }
                changed.append(port)
                assignments[p] = type
            }
            else if a != type {
                return .contradiction
            }
        }
        if !changed.isEmpty {
            return .dirty(changed)
        }
        return .unchanged
    }
}


public enum JelloConcreteDataType: Int, Codable, CaseIterable {
    case float4 = 1
    case float3 = 2
    case float2 = 3
    case float = 4
    case int = 5
    case bool = 6
    case texture1d = 7
    case texture2d = 8
    case texture3d = 9
    case slabMaterial = 10
}

public enum JelloConstantValue {
    case float(Float)
    case float2(vector_float2)
    case float3(vector_float3)
    case float4(vector_float4)
    case int(Int32)
    case bool(Bool)
}


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

public func getDomain(input: JelloGraphDataType) -> [JelloConcreteDataType] {
    switch input {
    case .any:
        return JelloConcreteDataType.allCases
    case .anyFloat:
        return [.float, .float2, .float3, .float4]
    case .anyMaterial:
        return [.slabMaterial]
    case .anyTexture:
        return [.texture1d, .texture2d, .texture3d]
    case .float:
        return [.float]
    case .float2:
        return [.float2]
    case .float3:
        return [.float3]
    case .float4:
        return [.float4]
    case .texture1d:
        return [.texture1d]
    case .texture2d:
        return [.texture2d]
    case .texture3d:
        return [.texture3d]
    case .int:
        return [.int]
    case .bool:
        return [.bool]
    case .slabMaterial:
        return [.slabMaterial]
    }
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
    public func install() {}
    public func write() {}
    public var branchTags: Set<UUID>
    public var constraints: [PortConstraint] { [] }
    public init(id: UUID, inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
    }
}


public protocol CompilerNode {
    var id: UUID { get }
    func install()
    func write()
    var inputPorts: [InputCompilerPort] { get }
    var outputPorts: [OutputCompilerPort] { get }
    var branchTags: Set<UUID> { get set }
    var constraints: [PortConstraint] { get }
}


public protocol BranchCompilerNode {
    var subNodes: [UUID: [CompilerNode]] {get set}
    var branches: [UUID] {get}
}


public class InputCompilerPort: Hashable, Identifiable {
    public var id: UUID
    public var node: CompilerNode?
    public var incomingEdge: CompilerEdge?
    
    /// Starts a new branch
    public var newBranchId: UUID?
    public var dataType: JelloGraphDataType
    public var concreteDataType: JelloConcreteDataType? = nil
    
    public init(id: UUID = UUID(), dataType: JelloGraphDataType = .any) {
        self.node = nil
        self.id = id
        self.incomingEdge = nil
        self.dataType = dataType
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: InputCompilerPort, rhs: InputCompilerPort) -> Bool {
        lhs.id == rhs.id
    }

}

public class OutputCompilerPort: Hashable, Identifiable {
    public var id: UUID
    public var node: CompilerNode? = nil
    public var outgoingEdges: [CompilerEdge] = []
    private(set) public var reservedSpirvId: UInt32? = nil
    public var dataType: JelloGraphDataType
    public var concreteDataType: JelloConcreteDataType? = nil
    
    public init(id: UUID = UUID(), dataType: JelloGraphDataType = .any) {
        self.dataType = dataType
        self.id = id
    }
    
    public func getOrReserveId() -> UInt32 {
        if let id = reservedSpirvId {
            return id
        }
        reservedSpirvId = #id
        return reservedSpirvId!
    }
    
    public func clearReservation() {
        reservedSpirvId = nil
    }
    
    public func setReservedId(reservedId: UInt32) {
        reservedSpirvId = reservedId
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: OutputCompilerPort, rhs: OutputCompilerPort) -> Bool {
        lhs.id == rhs.id
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
