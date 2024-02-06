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

public enum CompositeSize: Int, Codable, Equatable {
    case s1 = 0
    case s2 = 1
    case s3 = 2
    case s4 = 3
}
public enum Dimensionality: Int, Codable, Equatable {
    case d1 = 0
    case d2 = 1
    case d3 = 2
    case d4 = 3
}

public protocol HasCompositeSize {
    var compositeSize: CompositeSize? {get}
}

public protocol HasDimensionality {
    var dimensionality: Dimensionality? {get}
}

public protocol PortConstraint {
    var ports: Set<UUID> {get}
    func apply<Value: Equatable & HasCompositeSize & HasDimensionality>(assignments: inout [UUID: Value], domains: inout [UUID: [Value]], port: UUID, type: Value) -> ConstraintApplicationResult
}


public class SameTypesConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Equatable & HasCompositeSize>(assignments: inout [UUID: T], domains: inout [UUID: [T]], port: UUID, type: T) -> ConstraintApplicationResult {
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

public class SameCompositeSizeConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Equatable & HasCompositeSize & HasDimensionality>(assignments: inout [UUID: T], domains: inout [UUID: [T]], port: UUID, type: T) -> ConstraintApplicationResult {
        var changed: [UUID] = []
        if let thisCompositeSize = type.compositeSize {
            for p in ports {
                if let a = assignments[p] {
                    if a.compositeSize != thisCompositeSize {
                        return .contradiction
                    }
                } else {
                    let domain = (domains[p] ?? []).filter({$0.compositeSize == thisCompositeSize})
                    domains[p] = domain
                    if domain.isEmpty {
                        return .contradiction
                    } else if domain.count == 1, let a = domain.first {
                        assignments[p] = a
                        changed.append(p)
                    }
                }
            }
        }
        
        
        if !changed.isEmpty {
            return .dirty(changed)
        }
        return .unchanged
    }
}



public class SameDimensionalityConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Equatable & HasDimensionality & HasCompositeSize>(assignments: inout [UUID: T], domains: inout [UUID: [T]], port: UUID, type: T) -> ConstraintApplicationResult {
        var changed: [UUID] = []
        if let thisDimensionality = type.dimensionality {
            for p in ports {
                if let a = assignments[p] {
                    if a.dimensionality != thisDimensionality {
                        return .contradiction
                    }
                } else {
                    let domain = (domains[p] ?? []).filter({$0.dimensionality == thisDimensionality})
                    domains[p] = domain
                    if domain.isEmpty {
                        return .contradiction
                    } else if domain.count == 1, let a = domain.first {
                        assignments[p] = a
                        changed.append(p)
                    }
                }
            }
        }
        
        
        if !changed.isEmpty {
            return .dirty(changed)
        }
        return .unchanged
    }
}


public enum JelloTextureDataType: Int, Codable, CaseIterable, Equatable {
    case float = 0
    case float3 = 1
    case float2 = 2
    case float4 = 3
    case int = 4
}

public enum JelloConcreteDataType: Int, Codable, Equatable, CaseIterable, HasCompositeSize, HasDimensionality {
    case float = 0
    case float2 = 1
    case float3 = 2
    case float4 = 3
    case int = 4
    case bool = 5
    
    case texture1d_float = 100
    case texture1d_float2 = 101
    case texture1d_float3 = 102
    case texture1d_float4 = 103
    
    case texture2d_float = 200
    case texture2d_float2 = 201
    case texture2d_float3 = 202
    case texture2d_float4 = 203
    
    case texture3d_float = 300
    case texture3d_float2 = 301
    case texture3d_float3 = 302
    case texture3d_float4 = 303

    case proceduralTexture1d_float = 400
    case proceduralTexture1d_float2 = 401
    case proceduralTexture1d_float3 = 402
    case proceduralTexture1d_float4 = 403
    
    case proceduralTexture2d_float = 500
    case proceduralTexture2d_float2 = 501
    case proceduralTexture2d_float3 = 502
    case proceduralTexture2d_float4 = 503
    
    case proceduralTexture3d_float = 600
    case proceduralTexture3d_float2 = 601
    case proceduralTexture3d_float3 = 602
    case proceduralTexture3d_float4 = 603
    
    case slabMaterial = 1000
    
    public var compositeSize: CompositeSize? {
        switch self {
        case .float:
            return .s1
        case .float2:
            return .s2
        case .float3:
            return .s3
        case .float4:
            return .s4
        case .int:
            return .s1
        case .bool:
            return .s1
        case .texture1d_float:
            return .s1
        case .texture1d_float2:
            return .s2
        case .texture1d_float3:
            return .s3
        case .texture1d_float4:
            return .s4
        case .texture2d_float:
            return .s1
        case .texture2d_float2:
            return .s2
        case .texture2d_float3:
            return .s3
        case .texture2d_float4:
            return .s4
        case .texture3d_float:
            return .s1
        case .texture3d_float2:
            return .s2
        case .texture3d_float3:
            return .s3
        case .texture3d_float4:
            return .s4
        case .proceduralTexture1d_float:
            return .s1
        case .proceduralTexture1d_float2:
            return .s2
        case .proceduralTexture1d_float3:
            return .s3
        case .proceduralTexture1d_float4:
            return .s4
        case .proceduralTexture2d_float:
            return .s1
        case .proceduralTexture2d_float2:
            return .s2
        case .proceduralTexture2d_float3:
            return .s3
        case .proceduralTexture2d_float4:
            return .s4
        case .proceduralTexture3d_float:
            return .s1
        case .proceduralTexture3d_float2:
            return .s2
        case .proceduralTexture3d_float3:
            return .s3
        case .proceduralTexture3d_float4:
            return .s4
        case .slabMaterial:
            return nil
        }
    }
    
    public var dimensionality: Dimensionality? {
        switch self {
        case .float:
            return .d1
        case .float2:
            return .d2
        case .float3:
            return .d3
        case .float4:
            return .d4
        case .int:
            return .d1
        case .bool:
            return .d1
        case .texture1d_float:
            return .d1
        case .texture1d_float2:
            return .d1
        case .texture1d_float3:
            return .d1
        case .texture1d_float4:
            return .d1
        case .texture2d_float:
            return .d2
        case .texture2d_float2:
            return .d2
        case .texture2d_float3:
            return .d2
        case .texture2d_float4:
            return .d2
        case .texture3d_float:
            return .d3
        case .texture3d_float2:
            return .d3
        case .texture3d_float3:
            return .d3
        case .texture3d_float4:
            return .d3
        case .proceduralTexture1d_float:
            return .d1
        case .proceduralTexture1d_float2:
            return .d1
        case .proceduralTexture1d_float3:
            return .d1
        case .proceduralTexture1d_float4:
            return .d1
        case .proceduralTexture2d_float:
            return .d2
        case .proceduralTexture2d_float2:
            return .d2
        case .proceduralTexture2d_float3:
            return .d2
        case .proceduralTexture2d_float4:
            return .d2
        case .proceduralTexture3d_float:
            return .d3
        case .proceduralTexture3d_float2:
            return .d3
        case .proceduralTexture3d_float3:
            return .d3
        case .proceduralTexture3d_float4:
            return .d3
        case .slabMaterial:
            return nil
        }
    }
}

public enum JelloConstantValue: Codable, Equatable {
    case float(Float)
    case float2(vector_float2)
    case float3(vector_float3)
    case float4(vector_float4)
    case int(Int32)
    case bool(Bool)
}


public enum JelloGraphDataType: Int, Codable, CaseIterable, Equatable, HasCompositeSize, HasDimensionality {
    case any = 0
    case anyFloat = 1
    case float4 = 2
    case float3 = 3
    case float2 = 4
    case float = 5
    case int = 6
    case bool = 7
    case anyTexture = 8
    case anyMaterial = 30
    case slabMaterial = 31    
    
    case texture1d_float = 100
    case texture1d_float2 = 101
    case texture1d_float3 = 102
    case texture1d_float4 = 103
    
    case texture2d_float = 200
    case texture2d_float2 = 201
    case texture2d_float3 = 202
    case texture2d_float4 = 203
    
    case texture3d_float = 300
    case texture3d_float2 = 301
    case texture3d_float3 = 302
    case texture3d_float4 = 303

    case proceduralTexture1d_float = 400
    case proceduralTexture1d_float2 = 401
    case proceduralTexture1d_float3 = 402
    case proceduralTexture1d_float4 = 403
    
    case proceduralTexture2d_float = 500
    case proceduralTexture2d_float2 = 501
    case proceduralTexture2d_float3 = 502
    case proceduralTexture2d_float4 = 503
    
    case proceduralTexture3d_float = 600
    case proceduralTexture3d_float2 = 601
    case proceduralTexture3d_float3 = 602
    case proceduralTexture3d_float4 = 603
    
    case anyTexture_float = 700
    case anyTexture_float2 = 701
    case anyTexture_float3 = 702
    case anyTexture_float4 = 703
    
    case anyTexture_1d = 800
    case anyTexture_2d = 801
    case anyTexture_3d = 802
    
    case anyProceduralTexture_float = 900
    case anyProceduralTexture_float2 = 901
    case anyProceduralTexture_float3 = 902
    case anyProceduralTexture_float4 = 903
    
    case anyProceduralTexture_1d = 1000
    case anyProceduralTexture_2d = 1001
    case anyProceduralTexture_3d = 1002
    
    public var compositeSize: CompositeSize? {
        switch self {
        case .float:
            return .s1
        case .float2:
            return .s2
        case .float3:
            return .s3
        case .float4:
            return .s4
        case .int:
            return .s1
        case .bool:
            return .s1
        case .texture1d_float:
            return .s1
        case .texture1d_float2:
            return .s2
        case .texture1d_float3:
            return .s3
        case .texture1d_float4:
            return .s4
        case .texture2d_float:
            return .s1
        case .texture2d_float2:
            return .s2
        case .texture2d_float3:
            return .s3
        case .texture2d_float4:
            return .s4
        case .texture3d_float:
            return .s1
        case .texture3d_float2:
            return .s2
        case .texture3d_float3:
            return .s3
        case .texture3d_float4:
            return .s4
        case .proceduralTexture1d_float:
            return .s1
        case .proceduralTexture1d_float2:
            return .s2
        case .proceduralTexture1d_float3:
            return .s3
        case .proceduralTexture1d_float4:
            return .s4
        case .proceduralTexture2d_float:
            return .s1
        case .proceduralTexture2d_float2:
            return .s2
        case .proceduralTexture2d_float3:
            return .s3
        case .proceduralTexture2d_float4:
            return .s4
        case .proceduralTexture3d_float:
            return .s1
        case .proceduralTexture3d_float2:
            return .s2
        case .proceduralTexture3d_float3:
            return .s3
        case .proceduralTexture3d_float4:
            return .s4
        case .slabMaterial:
            return nil
        case .any:
            return nil
        case .anyFloat:
            return nil
        case .anyTexture:
            return nil
        case .anyMaterial:
            return nil
        case .anyTexture_float:
            return .s1
        case .anyTexture_float2:
            return .s2
        case .anyTexture_float3:
            return .s3
        case .anyTexture_float4:
            return .s4
        case .anyTexture_1d:
            return nil
        case .anyTexture_2d:
            return nil
        case .anyTexture_3d:
            return nil
        case .anyProceduralTexture_float:
            return .s1
        case .anyProceduralTexture_float2:
            return .s2
        case .anyProceduralTexture_float3:
            return .s3
        case .anyProceduralTexture_float4:
            return .s4
        case .anyProceduralTexture_1d:
            return nil
        case .anyProceduralTexture_2d:
            return nil
        case .anyProceduralTexture_3d:
            return nil
        }
    }
    
    public var dimensionality: Dimensionality? {
        switch self {
        case .float:
            return .d1
        case .float2:
            return .d2
        case .float3:
            return .d3
        case .float4:
            return .d4
        case .int:
            return .d1
        case .bool:
            return .d1
        case .texture1d_float:
            return .d1
        case .texture1d_float2:
            return .d1
        case .texture1d_float3:
            return .d1
        case .texture1d_float4:
            return .d1
        case .texture2d_float:
            return .d2
        case .texture2d_float2:
            return .d2
        case .texture2d_float3:
            return .d2
        case .texture2d_float4:
            return .d2
        case .texture3d_float:
            return .d3
        case .texture3d_float2:
            return .d3
        case .texture3d_float3:
            return .d3
        case .texture3d_float4:
            return .d3
        case .proceduralTexture1d_float:
            return .d1
        case .proceduralTexture1d_float2:
            return .d1
        case .proceduralTexture1d_float3:
            return .d1
        case .proceduralTexture1d_float4:
            return .d1
        case .proceduralTexture2d_float:
            return .d2
        case .proceduralTexture2d_float2:
            return .d2
        case .proceduralTexture2d_float3:
            return .d2
        case .proceduralTexture2d_float4:
            return .d2
        case .proceduralTexture3d_float:
            return .d3
        case .proceduralTexture3d_float2:
            return .d3
        case .proceduralTexture3d_float3:
            return .d3
        case .proceduralTexture3d_float4:
            return .d3
        case .slabMaterial:
            return nil
        case .any:
            return nil
        case .anyFloat:
            return nil
        case .anyTexture:
            return nil
        case .anyMaterial:
            return nil
        case .anyTexture_float:
            return nil
        case .anyTexture_float2:
            return nil
        case .anyTexture_float3:
            return nil
        case .anyTexture_float4:
            return nil
        case .anyTexture_1d:
            return .d1
        case .anyTexture_2d:
            return .d2
        case .anyTexture_3d:
            return .d3
        case .anyProceduralTexture_float:
            return nil
        case .anyProceduralTexture_float2:
            return nil
        case .anyProceduralTexture_float3:
            return nil
        case .anyProceduralTexture_float4:
            return nil
        case .anyProceduralTexture_1d:
            return .d1
        case .anyProceduralTexture_2d:
            return .d2
        case .anyProceduralTexture_3d:
            return .d3
        }
    }
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
        return [
            .texture1d_float,
            .texture1d_float2,
            .texture1d_float3,
            .texture1d_float4,
            
            .texture2d_float,
            .texture2d_float2,
            .texture2d_float3,
            .texture2d_float4,
            
            .texture3d_float,
            .texture3d_float2,
            .texture3d_float3,
            .texture3d_float4,
            
            .proceduralTexture1d_float,
            .proceduralTexture1d_float2,
            .proceduralTexture1d_float3,
            .proceduralTexture1d_float4,
            
            .proceduralTexture2d_float,
            .proceduralTexture2d_float2,
            .proceduralTexture2d_float3,
            .proceduralTexture2d_float4,
            
            .proceduralTexture3d_float,
            .proceduralTexture3d_float2,
            .proceduralTexture3d_float3,
            .proceduralTexture3d_float4
        ]
    case .int:
        return [.int]
    case .bool:
        return [.bool]
    case .float:
        return [.float]
    case .float2:
        return [.float2]
    case .float3:
        return [.float3]
    case .float4:
        return [.float4]
    case .texture1d_float:
        return [.texture1d_float]
    case .texture1d_float2:
        return [.texture1d_float2]
    case .texture1d_float3:
        return [.texture1d_float3]
    case .texture1d_float4:
        return [.texture1d_float4]
        
    case .texture2d_float:
        return [.texture2d_float]
    case .texture2d_float2:
        return [.texture2d_float2]
    case .texture2d_float3:
        return [.texture2d_float3]
    case .texture2d_float4:
        return [.texture2d_float4]
        
    case .texture3d_float:
        return [.texture3d_float]
    case .texture3d_float2:
        return [.texture3d_float2]
    case .texture3d_float3:
        return [.texture3d_float3]
    case .texture3d_float4:
        return [.texture3d_float4]
        
    case .proceduralTexture1d_float:
        return [.proceduralTexture1d_float]
    case .proceduralTexture1d_float2:
        return [.proceduralTexture1d_float2]
    case .proceduralTexture1d_float3:
        return [.proceduralTexture1d_float3]
    case .proceduralTexture1d_float4:
        return [.proceduralTexture1d_float4]
        
    case .proceduralTexture2d_float:
        return [.proceduralTexture2d_float]
    case .proceduralTexture2d_float2:
        return [.proceduralTexture2d_float2]
    case .proceduralTexture2d_float3:
        return [.proceduralTexture2d_float3]
    case .proceduralTexture2d_float4:
        return [.proceduralTexture2d_float4]
        
    case .proceduralTexture3d_float:
        return [.proceduralTexture3d_float]
    case .proceduralTexture3d_float2:
        return [.proceduralTexture3d_float2]
    case .proceduralTexture3d_float3:
        return [.proceduralTexture3d_float3]
    case .proceduralTexture3d_float4:
        return [.proceduralTexture3d_float4]
    case .slabMaterial:
        return [.slabMaterial]
    case .anyTexture_float:
        return [.proceduralTexture1d_float, .proceduralTexture2d_float, .proceduralTexture3d_float, .texture1d_float, .texture2d_float, .texture3d_float]
    case .anyTexture_float2:
        return [.proceduralTexture1d_float2, .proceduralTexture2d_float2, .proceduralTexture3d_float2, .texture1d_float2, .texture2d_float2, .texture3d_float2]
    case .anyTexture_float3:
        return [.proceduralTexture1d_float3, .proceduralTexture2d_float3, .proceduralTexture3d_float3, .texture1d_float3, .texture2d_float3, .texture3d_float3]
    case .anyTexture_float4:
        return [.proceduralTexture1d_float4, .proceduralTexture2d_float4, .proceduralTexture3d_float4, .texture1d_float4, .texture2d_float4, .texture3d_float4]
    case .anyTexture_1d:
        return [.proceduralTexture1d_float, .proceduralTexture1d_float2, .proceduralTexture1d_float3, .proceduralTexture1d_float4, .texture1d_float, .texture1d_float2, .texture1d_float3, .texture1d_float4]
    case .anyTexture_2d:
        return [.proceduralTexture2d_float, .proceduralTexture2d_float2, .proceduralTexture2d_float3, .proceduralTexture2d_float4, .texture2d_float, .texture2d_float2, .texture2d_float3, .texture2d_float4]
    case .anyTexture_3d:
        return [.proceduralTexture3d_float, .proceduralTexture3d_float2, .proceduralTexture3d_float3, .proceduralTexture3d_float4, .texture3d_float, .texture3d_float2, .texture3d_float3, .texture3d_float4]
    case .anyProceduralTexture_float:
        return [.proceduralTexture1d_float, .proceduralTexture2d_float, .proceduralTexture3d_float]
    case .anyProceduralTexture_float2:
        return [.proceduralTexture1d_float2, .proceduralTexture2d_float2, .proceduralTexture3d_float2]
    case .anyProceduralTexture_float3:
        return [.proceduralTexture1d_float3, .proceduralTexture2d_float3, .proceduralTexture3d_float3]
    case .anyProceduralTexture_float4:
        return [.proceduralTexture1d_float4, .proceduralTexture2d_float4, .proceduralTexture3d_float4]
    case .anyProceduralTexture_1d:
        return [.proceduralTexture1d_float, .proceduralTexture1d_float2, .proceduralTexture1d_float3, .proceduralTexture1d_float4]
    case .anyProceduralTexture_2d:
        return [.proceduralTexture2d_float, .proceduralTexture2d_float2, .proceduralTexture2d_float3, .proceduralTexture2d_float4]
    case .anyProceduralTexture_3d:
        return [.proceduralTexture3d_float, .proceduralTexture3d_float2, .proceduralTexture3d_float3, .proceduralTexture3d_float4]
    }
}


public enum CompilerComputationDimension: Codable, Equatable, Hashable {
    case dimension(Int, Int, Int)
}

public enum CompilerComputationDomain: Int, Codable, Hashable, Equatable, Identifiable {
    case constant = 0
    case timeVarying = 1
    case modelDependant = 2
    
    public var id: CompilerComputationDomain { self }
}

public protocol HasComputationDimensionCompilerNode {
    var computationDimension: CompilerComputationDimension {get}
}


public enum GraphOutputNode {
    case materialOutput(MaterialOutputCompilerNode)
    case previewOutput(PreviewOutputCompilerNode)
    case computeOutput(ComputeCompilerNode)
    
    public var node: CompilerNode & SubgraphCompilerNode {
        switch self {
        case .materialOutput(let mo):
            return mo
        case .previewOutput(let po):
            return po
        case .computeOutput(let co):
            return co
        }
    }
    
    static func fromSubgraphNode(subgraphNode: SubgraphCompilerNode) -> GraphOutputNode {
        if let mo = subgraphNode as? MaterialOutputCompilerNode {
            return .materialOutput(mo)
        }
        if let po = subgraphNode as? PreviewOutputCompilerNode {
            return .previewOutput(po)
        } else {
            return .computeOutput(subgraphNode as! ComputeCompilerNode)
        }
    }
}

public class JelloCompilerInput {
    public var id: UUID
    public var output: GraphOutputNode
    public var graph: CompilerGraph
    public var dependencies: Set<UUID> = []
    public var dependants: Set<UUID> = []
    

    public init(id: UUID, output: GraphOutputNode, graph: CompilerGraph) {
        self.id = id
        self.output = output
        self.graph = graph
    }
}

public enum SpirvShader: Codable, Equatable {
    case compute(CompilerComputationDimension, [UInt32], [JelloIOTexture], JelloIOTexture)
    case vertex([UInt32], [JelloIOTexture])
    case fragment([UInt32], [JelloIOTexture])
}

public struct JelloIOTexture: Codable, Equatable, Hashable {
    public var originatingStage: UUID
    public var size: CompilerComputationDimension
    public var format: TextureFormat
    public var packing: TexturePacking

    
    public enum TextureFormat: Int, Codable, Equatable {
        case Rgba32f = 0
        case Rgba16f = 1
        case R32f = 2
    }
    
    public enum TexturePacking: Int, Codable, Equatable {
        case float = 1
        case float2 = 2
        case float3 = 3
        case float4 = 4
    }

    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originatingStage)
    }
}

 

public struct JelloCompilerOutputStage: Codable, Equatable, Hashable {
    public var id: UUID
    public var dependencies: Set<UUID>
    public var dependants: Set<UUID>
    public var domain: CompilerComputationDomain
    public var shaders: [SpirvShader]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct JelloCompilerOutput: Equatable {
    public var stages: [JelloCompilerOutputStage]
}



public protocol CompilerNode {
    var id: UUID { get }
    func install(input: JelloCompilerInput)
    func write(input: JelloCompilerInput)
    var inputPorts: [InputCompilerPort] { get }
    var outputPorts: [OutputCompilerPort] { get }
    var branchTags: Set<UUID> { get set }
    var subgraphTags: Set<UUID> { get set }
    var computationDomain: CompilerComputationDomain? { get set }
    var constraints: [PortConstraint] { get }
}


public protocol SubgraphCompilerNode {
    var subgraph: JelloCompilerInput? {get set}
    func build(input: JelloCompilerInput) throws -> JelloCompilerOutputStage
}

public protocol BranchCompilerNode {
    var subNodes: [UUID: [CompilerNode]] { get set }
    var branches: [UUID] {get}
}


public class InputCompilerPort: Hashable, Identifiable {
    public var id: UUID
    public var node: CompilerNode?
    public var incomingEdge: CompilerEdge?
    
    /// Starts a new branch
    public var newBranchId: UUID?
    public var newSubgraphId: UUID?

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
    
    @discardableResult public init(inputPort: InputCompilerPort, outputPort: OutputCompilerPort) {
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
