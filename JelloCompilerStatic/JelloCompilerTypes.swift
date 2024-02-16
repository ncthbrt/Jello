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

public protocol HasRanking {
    var rank: Int {get}
}

public protocol PortConstraint {
    var ports: Set<UUID> {get}
    func apply<Value: Hashable & Equatable & HasCompositeSize & HasDimensionality & HasRanking>(assignments: inout [UUID: Value], domains: inout [UUID: [Value]]) -> ConstraintApplicationResult
}


public class SameTypesConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Hashable & Equatable & HasRanking>(assignments: inout [UUID: T], domains: inout [UUID: [T]]) -> ConstraintApplicationResult {
        let thisAssignments = ports.map({ assignments[$0] }).filter({ $0 != nil }).map({$0!})
        if let assignment = thisAssignments.first {
            if thisAssignments.contains(where: { $0 != assignment }) {
                return .contradiction
            } else {
                var changed: [UUID] = []
                for p in ports {
                    if !(domains[p] ?? []).contains(assignment) {
                        return .contradiction
                    }
                    if assignments[p] != assignment {
                        changed.append(p)
                        assignments[p] = assignment
                        domains[p] = [assignment]
                    }
                }
                if !changed.isEmpty {
                    return .dirty(changed)
                }
                return .unchanged
            }
        } else {
            var changed: [UUID] = []
            let theseDomains: [Set<T>] = ports.map({ Set<T>(domains[$0] ?? []) })
            let commonDomains: [T] = Array<T>(theseDomains.reduce(Set<T>(theseDomains.first ?? []), { prev, set in prev.intersection(set) }).sorted(by: { a, b in a.rank < b.rank }))
            if commonDomains.isEmpty {
                return .contradiction
            }
            
            for p in ports {
                if commonDomains.count != (domains[p]?.count ?? 0) {
                    domains[p] = Array(commonDomains)
                    changed.append(p)
                    if commonDomains.count == 1 {
                        assignments[p] = commonDomains[0]
                    }
                }
            }
            if !changed.isEmpty {
                return .dirty(changed)
            }
            return .unchanged
        }
    }
}

public class SameCompositeSizeConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Equatable & HasCompositeSize>(assignments: inout [UUID: T], domains: inout [UUID: [T]]) -> ConstraintApplicationResult {
        if let assignedCompositeSize = ports.map({ assignments[$0] }).map({$0?.compositeSize}).filter({ $0 != nil }).first {
            var changed: [UUID] = []
            for p in ports {
                let oldDomains = (domains[p] ?? [])
                let newDomains = oldDomains.filter({ $0.compositeSize == assignedCompositeSize })
                if newDomains.count == 0 {
                    return .contradiction
                }
                if newDomains.count != oldDomains.count {
                    changed.append(p)
                    if newDomains.count == 1 {
                        assignments[p] = newDomains[0]
                    }
                    domains[p] = newDomains
                }
            }
            if changed.isEmpty {
                return .unchanged
            }
            return .dirty(changed)
        } else {
            var changed: [UUID] = []
            
            let compositeSizesForPorts: [Set<CompositeSize?>] = ports.map({ p in (domains[p] ?? []).map({ $0.compositeSize }) }).map({ Set<CompositeSize?>($0) })
            let theseCompositeSizes: Set<CompositeSize?> = compositeSizesForPorts.reduce(Set<CompositeSize?>(compositeSizesForPorts.first ?? []), { prev, curr in prev.intersection(curr) })
            for p in ports {
                let oldDomains = (domains[p] ?? [])
                let newDomains = oldDomains.filter({ theseCompositeSizes.contains($0.compositeSize) })
                if newDomains.count == 0 {
                    return .contradiction
                }
                if newDomains.count != oldDomains.count {
                    changed.append(p)
                    domains[p] = newDomains
                    if newDomains.count == 1 {
                        assignments[p] = newDomains[0]
                    }
                }
            }
            
            if changed.isEmpty {
                return .unchanged
            }
            return .dirty(changed)
        }
    }
}


public class SameDimensionalityConstraint: PortConstraint {
    private(set) public var ports: Set<UUID>
    public init(ports: Set<UUID>) {
        self.ports = ports
    }
    
    public func apply<T: Equatable & HasDimensionality>(assignments: inout [UUID: T], domains: inout [UUID: [T]]) -> ConstraintApplicationResult {
        if let assignedCompositeSize = ports.map({ assignments[$0] }).map({$0?.dimensionality}).filter({ $0 != nil }).first {
            var changed: [UUID] = []
            for p in ports {
                let oldDomains = (domains[p] ?? [])
                let newDomains = oldDomains.filter({ $0.dimensionality == assignedCompositeSize })
                if newDomains.count == 0 {
                    return .contradiction
                }
                if newDomains.count != oldDomains.count {
                    changed.append(p)
                    if newDomains.count == 1 {
                        assignments[p] = newDomains[0]
                    }
                    domains[p] = newDomains
                }
            }
            if changed.isEmpty {
                return .unchanged
            }
            return .dirty(changed)
        } else {
            var changed: [UUID] = []
            let dimensionalitiesForPorts: [Set<Dimensionality?>] = ports.map({ p in (domains[p] ?? []).map({ $0.dimensionality }) }).map({ Set<Dimensionality?>($0) })
            let theseDimensionalities: Set<Dimensionality?> = dimensionalitiesForPorts.reduce(Set<Dimensionality?>(dimensionalitiesForPorts.first ?? []), { prev, curr in prev.intersection(curr) })
            for p in ports {
                let oldDomains = (domains[p] ?? [])
                let newDomains = oldDomains.filter({ theseDimensionalities.contains($0.dimensionality) })
                if newDomains.count == 0 {
                    return .contradiction
                }
                if newDomains.count != oldDomains.count {
                    changed.append(p)
                    domains[p] = newDomains
                    if newDomains.count == 1 {
                        assignments[p] = newDomains[0]
                    }
                }
            }
            
            if changed.isEmpty {
                return .unchanged
            }
            return .dirty(changed)
        }
    }
}



public enum JelloTextureDataType: Int, Codable, CaseIterable, Equatable {
    case float = 0
    case float3 = 1
    case float2 = 2
    case float4 = 3
    case int = 4
}

public enum JelloConcreteDataType: Int, Codable, Equatable, CaseIterable, HasCompositeSize, HasDimensionality, HasRanking {
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

    case proceduralField1d_float = 400
    case proceduralField1d_float2 = 401
    case proceduralField1d_float3 = 402
    case proceduralField1d_float4 = 403
    
    case proceduralField2d_float = 500
    case proceduralField2d_float2 = 501
    case proceduralField2d_float3 = 502
    case proceduralField2d_float4 = 503
    
    case proceduralField3d_float = 600
    case proceduralField3d_float2 = 601
    case proceduralField3d_float3 = 602
    case proceduralField3d_float4 = 603
    
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
        case .proceduralField1d_float:
            return .s1
        case .proceduralField1d_float2:
            return .s2
        case .proceduralField1d_float3:
            return .s3
        case .proceduralField1d_float4:
            return .s4
        case .proceduralField2d_float:
            return .s1
        case .proceduralField2d_float2:
            return .s2
        case .proceduralField2d_float3:
            return .s3
        case .proceduralField2d_float4:
            return .s4
        case .proceduralField3d_float:
            return .s1
        case .proceduralField3d_float2:
            return .s2
        case .proceduralField3d_float3:
            return .s3
        case .proceduralField3d_float4:
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
        case .proceduralField1d_float:
            return .d1
        case .proceduralField1d_float2:
            return .d1
        case .proceduralField1d_float3:
            return .d1
        case .proceduralField1d_float4:
            return .d1
        case .proceduralField2d_float:
            return .d2
        case .proceduralField2d_float2:
            return .d2
        case .proceduralField2d_float3:
            return .d2
        case .proceduralField2d_float4:
            return .d2
        case .proceduralField3d_float:
            return .d3
        case .proceduralField3d_float2:
            return .d3
        case .proceduralField3d_float3:
            return .d3
        case .proceduralField3d_float4:
            return .d3
        case .slabMaterial:
            return nil
        }
    }
    
    public var rank: Int { 1 }
}

public enum JelloConstantValue: Codable, Equatable {
    case float(Float)
    case float2(vector_float2)
    case float3(vector_float3)
    case float4(vector_float4)
    case int(Int32)
    case bool(Bool)
}


public enum JelloGraphDataType: Int, Codable, Equatable, HasCompositeSize, HasDimensionality, HasRanking {
    case any = 0
    case anyFloat = 1
    case float4 = 2
    case float3 = 3
    case float2 = 4
    case float = 5
    case int = 6
    case bool = 7
    case anyField = 8
    case anyMaterial = 30
    case slabMaterial = 31    
    
    case anyFloat123 = 32
    
    
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

    case proceduralField1d_float = 400
    case proceduralField1d_float2 = 401
    case proceduralField1d_float3 = 402
    case proceduralField1d_float4 = 403
    
    case proceduralField2d_float = 500
    case proceduralField2d_float2 = 501
    case proceduralField2d_float3 = 502
    case proceduralField2d_float4 = 503
    
    case proceduralField3d_float = 600
    case proceduralField3d_float2 = 601
    case proceduralField3d_float3 = 602
    case proceduralField3d_float4 = 603
    
    case anyField_float = 700
    case anyField_float2 = 701
    case anyField_float3 = 702
    case anyField_float4 = 703
    
    case anyField_1d = 800
    case anyField_2d = 801
    case anyField_3d = 802
    
    case anyProceduralField = 900
    
    case anyProceduralField_float = 901
    case anyProceduralField_float2 = 902
    case anyProceduralField_float3 = 903
    case anyProceduralField_float4 = 904
    
    case anyProceduralField_1d = 1000
    case anyProceduralField_2d = 1001
    case anyProceduralField_3d = 1002
    
    case anyTexture = 1100
    
    case anyTexture_float = 1101
    case anyTexture_float2 = 1102
    case anyTexture_float3 = 1103
    case anyTexture_float4 = 1104
    
    case anyTexture_1d = 1200
    case anyTexture_2d = 1201
    case anyTexture_3d = 1202

    
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
        case .proceduralField1d_float:
            return .s1
        case .proceduralField1d_float2:
            return .s2
        case .proceduralField1d_float3:
            return .s3
        case .proceduralField1d_float4:
            return .s4
        case .proceduralField2d_float:
            return .s1
        case .proceduralField2d_float2:
            return .s2
        case .proceduralField2d_float3:
            return .s3
        case .proceduralField2d_float4:
            return .s4
        case .proceduralField3d_float:
            return .s1
        case .proceduralField3d_float2:
            return .s2
        case .proceduralField3d_float3:
            return .s3
        case .proceduralField3d_float4:
            return .s4
        case .slabMaterial:
            return nil
        case .any:
            return nil
        case .anyFloat:
            return nil
        case .anyFloat123:
            return nil
        case .anyField:
            return nil
        case .anyMaterial:
            return nil
        case .anyField_float:
            return .s1
        case .anyField_float2:
            return .s2
        case .anyField_float3:
            return .s3
        case .anyField_float4:
            return .s4
        case .anyField_1d:
            return nil
        case .anyField_2d:
            return nil
        case .anyField_3d:
            return nil
        case .anyProceduralField_float:
            return .s1
        case .anyProceduralField_float2:
            return .s2
        case .anyProceduralField_float3:
            return .s3
        case .anyProceduralField_float4:
            return .s4
        case .anyProceduralField_1d:
            return nil
        case .anyProceduralField_2d:
            return nil
        case .anyProceduralField_3d:
            return nil
        case .anyTexture:
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
        case .anyProceduralField:
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
        case .proceduralField1d_float:
            return .d1
        case .proceduralField1d_float2:
            return .d1
        case .proceduralField1d_float3:
            return .d1
        case .proceduralField1d_float4:
            return .d1
        case .proceduralField2d_float:
            return .d2
        case .proceduralField2d_float2:
            return .d2
        case .proceduralField2d_float3:
            return .d2
        case .proceduralField2d_float4:
            return .d2
        case .proceduralField3d_float:
            return .d3
        case .proceduralField3d_float2:
            return .d3
        case .proceduralField3d_float3:
            return .d3
        case .proceduralField3d_float4:
            return .d3
        case .slabMaterial:
            return nil
        case .any:
            return nil
        case .anyFloat:
            return nil
        case .anyField:
            return nil
        case .anyMaterial:
            return nil
        case .anyField_float:
            return nil
        case .anyField_float2:
            return nil
        case .anyField_float3:
            return nil
        case .anyField_float4:
            return nil
        case .anyField_1d:
            return .d1
        case .anyField_2d:
            return .d2
        case .anyField_3d:
            return .d3
        case .anyProceduralField_float:
            return nil
        case .anyProceduralField_float2:
            return nil
        case .anyProceduralField_float3:
            return nil
        case .anyProceduralField_float4:
            return nil
        case .anyProceduralField_1d:
            return .d1
        case .anyProceduralField_2d:
            return .d2
        case .anyProceduralField_3d:
            return .d3
        case .anyTexture:
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
        case .anyProceduralField:
            return nil
        case .anyFloat123:
            return nil
        }
    }
    
    public var rank: Int {
        switch self {
        case .any:
            return 1
        case .anyFloat, .anyField, .anyMaterial:
            return 2
        case .anyField_float, .anyField_float2, .anyField_float3, .anyField_float4:
            return 3
        case .anyField_1d, .anyField_2d, .anyField_3d:
            return 3
        case .anyTexture, .anyProceduralField:
            return 3
        case .anyTexture_float, .anyTexture_float2, .anyTexture_float3, .anyTexture_float4:
            return 4
        case .anyTexture_1d, .anyTexture_2d, .anyTexture_3d:
            return 4
        case .anyProceduralField_float, .anyProceduralField_float2, .anyProceduralField_float3, .anyProceduralField_float4:
            return 4
        case .anyProceduralField_1d, .anyProceduralField_2d, .anyProceduralField_3d:
            return 4
        case .anyFloat123:
            return 4
        default:
            return 5
        }
    }
}

public func getDomain(input: JelloGraphDataType) -> [JelloConcreteDataType] {
    switch input {
    case .any:
        return JelloConcreteDataType.allCases
    case .anyFloat:
        return [.float, .float2, .float3, .float4]
    case .anyFloat123:
        return [.float, .float2, .float3]
    case .anyMaterial:
        return [.slabMaterial]
    case .anyField:
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
            
            .proceduralField1d_float,
            .proceduralField1d_float2,
            .proceduralField1d_float3,
            .proceduralField1d_float4,
            
            .proceduralField2d_float,
            .proceduralField2d_float2,
            .proceduralField2d_float3,
            .proceduralField2d_float4,
            
            .proceduralField3d_float,
            .proceduralField3d_float2,
            .proceduralField3d_float3,
            .proceduralField3d_float4
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
        
    case .proceduralField1d_float:
        return [.proceduralField1d_float]
    case .proceduralField1d_float2:
        return [.proceduralField1d_float2]
    case .proceduralField1d_float3:
        return [.proceduralField1d_float3]
    case .proceduralField1d_float4:
        return [.proceduralField1d_float4]
        
    case .proceduralField2d_float:
        return [.proceduralField2d_float]
    case .proceduralField2d_float2:
        return [.proceduralField2d_float2]
    case .proceduralField2d_float3:
        return [.proceduralField2d_float3]
    case .proceduralField2d_float4:
        return [.proceduralField2d_float4]
        
    case .proceduralField3d_float:
        return [.proceduralField3d_float]
    case .proceduralField3d_float2:
        return [.proceduralField3d_float2]
    case .proceduralField3d_float3:
        return [.proceduralField3d_float3]
    case .proceduralField3d_float4:
        return [.proceduralField3d_float4]
    case .slabMaterial:
        return [.slabMaterial]
    case .anyProceduralField:
        return [
            .proceduralField1d_float,
            .proceduralField1d_float2,
            .proceduralField1d_float3,
            .proceduralField1d_float4,
            
            .proceduralField2d_float,
            .proceduralField2d_float2,
            .proceduralField2d_float3,
            .proceduralField2d_float4,
            
            .proceduralField3d_float,
            .proceduralField3d_float2,
            .proceduralField3d_float3,
            .proceduralField3d_float4
        ]
    case .anyField_float:
        return [.proceduralField1d_float, .proceduralField2d_float, .proceduralField3d_float, .texture1d_float, .texture2d_float, .texture3d_float]
    case .anyField_float2:
        return [.proceduralField1d_float2, .proceduralField2d_float2, .proceduralField3d_float2, .texture1d_float2, .texture2d_float2, .texture3d_float2]
    case .anyField_float3:
        return [.proceduralField1d_float3, .proceduralField2d_float3, .proceduralField3d_float3, .texture1d_float3, .texture2d_float3, .texture3d_float3]
    case .anyField_float4:
        return [.proceduralField1d_float4, .proceduralField2d_float4, .proceduralField3d_float4, .texture1d_float4, .texture2d_float4, .texture3d_float4]
    case .anyField_1d:
        return [.proceduralField1d_float, .proceduralField1d_float2, .proceduralField1d_float3, .proceduralField1d_float4, .texture1d_float, .texture1d_float2, .texture1d_float3, .texture1d_float4]
    case .anyField_2d:
        return [.proceduralField2d_float, .proceduralField2d_float2, .proceduralField2d_float3, .proceduralField2d_float4, .texture2d_float, .texture2d_float2, .texture2d_float3, .texture2d_float4]
    case .anyField_3d:
        return [.proceduralField3d_float, .proceduralField3d_float2, .proceduralField3d_float3, .proceduralField3d_float4, .texture3d_float, .texture3d_float2, .texture3d_float3, .texture3d_float4]
    case .anyProceduralField_float:
        return [.proceduralField1d_float, .proceduralField2d_float, .proceduralField3d_float]
    case .anyProceduralField_float2:
        return [.proceduralField1d_float2, .proceduralField2d_float2, .proceduralField3d_float2]
    case .anyProceduralField_float3:
        return [.proceduralField1d_float3, .proceduralField2d_float3, .proceduralField3d_float3]
    case .anyProceduralField_float4:
        return [.proceduralField1d_float4, .proceduralField2d_float4, .proceduralField3d_float4]
    case .anyProceduralField_1d:
        return [.proceduralField1d_float, .proceduralField1d_float2, .proceduralField1d_float3, .proceduralField1d_float4]
    case .anyProceduralField_2d:
        return [.proceduralField2d_float, .proceduralField2d_float2, .proceduralField2d_float3, .proceduralField2d_float4]
    case .anyProceduralField_3d:
        return [.proceduralField3d_float, .proceduralField3d_float2, .proceduralField3d_float3, .proceduralField3d_float4]
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
            .texture3d_float4
        ]
    case .anyTexture_float:
        return [
           .texture1d_float,
           .texture2d_float,
           .texture3d_float,
       ]
    case .anyTexture_float2:
        return [
           .texture1d_float2,
           .texture2d_float2,
           .texture3d_float2,
       ]
    case .anyTexture_float3:
        return [
           .texture1d_float3,
           .texture2d_float3,
           .texture3d_float3,
       ]
    case .anyTexture_float4:
        return [
           .texture1d_float4,
           .texture2d_float4,
           .texture3d_float4,
       ]
    case .anyTexture_1d:
        return [.texture1d_float, .texture1d_float2, .texture1d_float3, .texture1d_float4]
    case .anyTexture_2d:
        return [.texture2d_float, .texture2d_float2, .texture2d_float3, .texture2d_float4]
    case .anyTexture_3d:
        return [.texture3d_float, .texture3d_float2, .texture3d_float3, .texture3d_float4]
    }
    
    
}


public enum CompilerComputationDimension: Codable, Equatable, Hashable {
    case dimension(Int, Int, Int)
}

public struct CompilerComputationDomain: OptionSet, Codable, Hashable, Equatable, Identifiable {
    public var rawValue: UInt32
    
    public static let constant = CompilerComputationDomain([])
    public static let timeVarying = CompilerComputationDomain(rawValue: 1 << 0)
    public static let modelDependant = CompilerComputationDomain(rawValue: 1 << 1)
    public static let transformDependant = CompilerComputationDomain(rawValue: 1 << 2)

    public var id: CompilerComputationDomain { self }
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
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

public struct SpirvTextureBinding : Codable, Equatable {
    public let texture: JelloComputeIOTexture
    public let spirvId: UInt32
}

public struct SpirvComputeShader: Codable, Equatable {
    public let shader: [UInt32]
    public let outputComputeTexture: SpirvTextureBinding
    public let inputComputeTextures: [SpirvTextureBinding]
}

public struct SpirvComputeRasterizerShader: Codable, Equatable {
    public let shader: [UInt32]
    public let outputComputeTexture: SpirvTextureBinding
}

public struct SpirvVertexShader: Codable, Equatable {
    public let shader: [UInt32]
    public let inputComputeTextures: [SpirvTextureBinding]
}

public struct SpirvFragmentShader: Codable, Equatable {
    public let shader: [UInt32]
    public let inputComputeTextures: [SpirvTextureBinding]
}


public enum SpirvShader: Codable, Equatable {
    case computeRasterizer(SpirvComputeRasterizerShader)
    case compute(SpirvComputeShader)
    case vertex(SpirvVertexShader)
    case fragment(SpirvFragmentShader)
    
    var shader: [UInt32] {
        switch self {
        case .compute(let c):
            c.shader
        case .computeRasterizer(let r):
            r.shader
        case .fragment(let f):
            f.shader
        case .vertex(let v):
            v.shader
        }
    }
}

public struct JelloComputeIOTexture: Codable, Equatable, Hashable {
    public var originatingStage: UUID
    public var originatingPass: UInt32
    public var size: CompilerComputationDimension
    public var format: TextureFormat
    public var packing: TexturePacking

    
    public enum TextureFormat: Int, Codable, Equatable {
        case Rgba32f = 0
        case Rgba16f = 1
        case R32f = 2
        case R32i = 3
    }
    
    public enum TexturePacking: Int, Codable, Equatable {
        case int = 0
        case float = 1
        case float2 = 2
        case float3 = 3
        case float4 = 4
    }

    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originatingStage)
        hasher.combine(originatingPass)
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
    func buildShader(input: JelloCompilerInput) throws -> JelloCompilerOutputStage
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
