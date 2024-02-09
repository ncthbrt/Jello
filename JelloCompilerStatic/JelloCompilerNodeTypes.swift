//
//  JelloCompilerNodeTypes.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2023/12/27.
//

import Foundation
import SpirvMacros
import SpirvMacrosShared
import SPIRV_Headers_Swift

public class IfElseCompilerNode : CompilerNode, BranchCompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?
    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let condPort = inputPorts.first!
        let truePort = inputPorts[1]
        let falsePort = inputPorts[2]
        
        let maybeCondResultId = condPort.incomingEdge?.outputPort.getOrReserveId()
        var condId: UInt32 = maybeCondResultId ?? 0
        if maybeCondResultId == nil {
            let typeBool = #typeDeclaration(opCode: SpirvOpTypeBool)
            condId = #id
            #globalDeclaration(opCode: SpirvOpConstantFalse, [typeBool, condId])
        }
        
        let inputOutputTypeId = declareType(dataType: truePort.concreteDataType!)
        var defaultZeroValueConstantId: UInt32 = 0
        if truePort.incomingEdge == nil || falsePort.incomingEdge == nil {
            defaultZeroValueConstantId = #id
            #globalDeclaration(opCode: SpirvOpConstantNull, [inputOutputTypeId, defaultZeroValueConstantId])
        }
        
        var ifTrue = defaultZeroValueConstantId
        var ifFalse = defaultZeroValueConstantId

        let trueLabel = #id
        let falseLabel = #id
        let endLabel = #id
        #functionBody(opCode: SpirvOpSelectionMerge, [endLabel, 0])
        #functionBody(opCode: SpirvOpBranchConditional, [condId, trueLabel, falseLabel])
        #functionBody(opCode: SpirvOpLabel, [trueLabel])
        if let trueBranch = subNodes[trueBranchTag] {
            for node in trueBranch {
                node.write(input: input)
            }
            ifTrue = truePort.incomingEdge!.outputPort.getOrReserveId()
        }
        #functionBody(opCode: SpirvOpBranch, [endLabel])
        #functionBody(opCode: SpirvOpLabel, [falseLabel])
        if let falseBranch = subNodes[falseBranchTag] {
            for node in falseBranch {
                node.write(input: input)
            }
            ifFalse = falsePort.incomingEdge!.outputPort.getOrReserveId()
        }
        #functionBody(opCode: SpirvOpBranch, [endLabel])
        #functionBody(opCode: SpirvOpLabel, [endLabel])
        let outputPort = outputPorts.first!
        let outputId = outputPort.getOrReserveId()
        #functionBody(opCode: SpirvOpPhi, [inputOutputTypeId, outputId, ifTrue, trueLabel, ifFalse, falseLabel])
    }
    
    public var branchTags: Set<UUID> = []
    public var subNodes: [UUID: [CompilerNode]] = [:]
    public var branches: [UUID]
    public var trueBranchTag: UUID
    public var falseBranchTag: UUID
    public var constraints: [PortConstraint] {
        var ports = inputPorts.dropFirst().map({$0.id})
        ports.append(contentsOf: outputPorts.map({$0.id}))
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID, condition: InputCompilerPort, ifTrue: InputCompilerPort, ifFalse: InputCompilerPort, outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts =  [condition, ifTrue, ifFalse]
        self.outputPorts = [outputPort]
        self.trueBranchTag = UUID()
        self.falseBranchTag = UUID()
        self.branches = [trueBranchTag, falseBranchTag]
        ifTrue.newBranchId = trueBranchTag
        ifFalse.newBranchId = falseBranchTag
        condition.dataType = .bool
    }
}



public class ConstantCompilerNode : CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain? = .constant
    
    public func install(input: JelloCompilerInput) {
        let outputPort = outputPorts.first!
        let constantId = outputPort.getOrReserveId()
        switch(value) {
        case .bool(let b):
            let boolType = declareType(dataType: .bool)
            #globalDeclaration(opCode: b ? SpirvOpConstantTrue: SpirvOpConstantFalse, [boolType, constantId])
            break
        case .float(let f):
            let floatType = declareType(dataType: .float)
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, constantId], float(f))
            break
        case .int(let i):
            let intType = declareType(dataType: .int)
            #globalDeclaration(opCode: SpirvOpConstant, [intType, constantId], int(i))
            break
        case .float2(let f2):
            let floatType = declareType(dataType: .float)
            let f2Type = declareType(dataType: .float2)
            let c1Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c1Id], float(f2.x))
            let c2Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c2Id], float(f2.y))
            #globalDeclaration(opCode: SpirvOpConstantComposite, [f2Type, constantId, c1Id, c2Id])
            break
        case .float3(let f3):
            let floatType = declareType(dataType: .float)
            let f3Type = declareType(dataType: .float3)
            let c1Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c1Id], float(f3.x))
            let c2Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c2Id], float(f3.y))
            let c3Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c3Id], float(f3.z))
            #globalDeclaration(opCode: SpirvOpConstantComposite, [f3Type, constantId, c1Id, c2Id, c3Id])
            break
        case .float4(let f4):
            let floatType = declareType(dataType: .float)
            let f4Type = declareType(dataType: .float4)
            let c1Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c1Id], float(f4.x))
            let c2Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c2Id], float(f4.y))
            let c3Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c3Id], float(f4.z))
            let c4Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c4Id], float(f4.w))
            #globalDeclaration(opCode: SpirvOpConstantComposite, [f4Type, constantId, c1Id, c2Id, c3Id, c4Id])
            break
        }
    }
    
    public func write(input: JelloCompilerInput) {

    }
    
    public var branchTags: Set<UUID> = []

    public var branches: [UUID] = []
    public var constraints: [PortConstraint] { [] }
    private var value: JelloConstantValue
    
    public init(id: UUID = UUID(), outputPort: OutputCompilerPort, value: JelloConstantValue) {
        self.id = id
        self.inputPorts =  []
        self.outputPorts = [outputPort]
        self.value = value
        switch value {
        case .bool(_):
            outputPort.dataType = .bool
            break
        case .float(_):
            outputPort.dataType = .float
            break
        case .float2(_):
            outputPort.dataType = .float2
            break
        case .float3(_):
            outputPort.dataType = .float3
            break
        case .float4(_):
            outputPort.dataType = .float4
            break
        case .int(_):
            outputPort.dataType = .int
            break
        }
        outputPort.node = self
    }
}


public class PreviewOutputCompilerNode: CompilerNode & SubgraphCompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?
    public var subgraph: JelloCompilerInput? = nil
    
    public func build(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
        try compileSpirvFragmentShader(input: input, outputBody: {
            let inputPort = inputPorts.first!
            let floatTypeId = #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
            let float4TypeId = declareType(dataType: .float4)
            let float4PointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassOutput.rawValue, float4TypeId])
            let outputVariableId = JelloCompilerBlackboard.fragOutputColorId
            #debugNames(opCode: SpirvOpName, [outputVariableId], #stringLiteral("fragmentMain"))
            #annotation(opCode: SpirvOpDecorate, [outputVariableId, SpirvDecorationLocation.rawValue, 0])
            #globalDeclaration(opCode: SpirvOpVariable, [float4PointerTypeId, outputVariableId, SpirvStorageClassOutput.rawValue])
            
            var resultId: UInt32 = 0
            if let edge = inputPort.incomingEdge {
                switch(inputPort.concreteDataType!) {
                case .bool:
                    resultId = #id
                    let zeroVector = #id
                    #globalDeclaration(opCode: SpirvOpConstantNull, [float4TypeId, zeroVector])
                    let oneFloat = #id
                    #globalDeclaration(opCode: SpirvOpConstant, [floatTypeId, oneFloat], float(1))
                    let oneVector = #id
                    #globalDeclaration(opCode: SpirvOpConstantComposite, [float4TypeId, oneVector, oneFloat, oneFloat, oneFloat, oneFloat])
                    let trueLabel = #id
                    let falseLabel = #id
                    let endLabel = #id
                    #functionBody(opCode: SpirvOpSelectionMerge, [endLabel, 0])
                    #functionBody(opCode: SpirvOpBranchConditional, [edge.outputPort.getOrReserveId(), trueLabel, falseLabel])
                    #functionBody(opCode: SpirvOpLabel, [trueLabel])
                    #functionBody(opCode: SpirvOpBranch, [endLabel])
                    #functionBody(opCode: SpirvOpLabel, [falseLabel])
                    #functionBody(opCode: SpirvOpBranch, [endLabel])
                    #functionBody(opCode: SpirvOpLabel, [endLabel])
                    #functionBody(opCode: SpirvOpPhi, [float4TypeId, resultId, oneVector, trueLabel, zeroVector, falseLabel])
                    break
                case .float:
                    resultId = #id
                    let outId = edge.outputPort.getOrReserveId()
                    #functionBody(opCode: SpirvOpCompositeConstruct, [float4TypeId, resultId, outId, outId, outId, outId])
                    break
                case .float2:
                    resultId = #id
                    let outId = edge.outputPort.getOrReserveId()
                    #functionBody(opCode: SpirvOpVectorShuffle, [float4TypeId, resultId, outId, outId, 0, 1, 0xFFFFFFFF, 0xFFFFFFFF])
                    break
                case .float3:
                    resultId = #id
                    let outId = edge.outputPort.getOrReserveId()
                    #functionBody(opCode: SpirvOpVectorShuffle, [float4TypeId, resultId, outId, outId, 0, 1, 2, 0xFFFFFFFF])
                    break
                case .float4:
                    resultId = edge.outputPort.getOrReserveId()
                    break
                case .int:
                    fatalError("Integer Preview Not Currently Supported")
                    break
                case .slabMaterial:
                    fatalError("Material Preview Not Currently Supported")
                    break
                case .texture1d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture1d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture1d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture1d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture2d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture2d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture2d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture2d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture3d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture3d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture3d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .texture3d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField1d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField1d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField1d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField1d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField2d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField2d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField2d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField2d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField3d_float:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField3d_float2:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField3d_float3:
                    fatalError("Texture Preview Not Currently Supported")
                case .proceduralField3d_float4:
                    fatalError("Texture Preview Not Currently Supported")
                }
            } else {
                resultId = #id
                #globalDeclaration(opCode: SpirvOpConstantNull, [float4TypeId, resultId])
            }
            #functionBody(opCode: SpirvOpStore, [outputVariableId, resultId])
        })
    }
    
    public func install(input: JelloCompilerInput) {}
    
    public func write(input: JelloCompilerInput) {}
    
    public var branchTags: Set<UUID>
    public var constraints: [PortConstraint] {[]}
    public init(id: UUID = UUID(), inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
            p.newSubgraphId = self.id
            p.node = self
        }
    }
}


public class AddCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install(input: JelloCompilerInput) {}
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?
    
    public func write(input: JelloCompilerInput) {
        let fst = inputPorts.first!
        let typeId = declareType(dataType: fst.concreteDataType!)
        let zero = #id
        #globalDeclaration(opCode: SpirvOpConstantNull, [typeId, zero])
        var prevResultId = fst.incomingEdge?.outputPort.getOrReserveId() ?? zero
        guard let f = getAddOperation(typeId: typeId, dataType: fst.concreteDataType!) else {
            fatalError("\(fst.concreteDataType!) does not support the add operation")
        }
        for p in inputPorts.dropFirst().filter({$0.incomingEdge != nil}) {
            prevResultId = f(prevResultId, p.incomingEdge?.outputPort.getOrReserveId() ?? zero)
        }
        outputPorts.first!.setReservedId(reservedId: prevResultId)
    }
    
    func getAddOperation(typeId: UInt32, dataType: JelloConcreteDataType) -> ((UInt32, UInt32) -> UInt32)? {
        switch (dataType) {
        case .float, .float2, .float3, .float4:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpFAdd, [typeId, resultId, a, b])
                return resultId
            }
        case .int:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpIAdd, [typeId, resultId, a, b])
                return resultId
            }
        default:
            return nil
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        ports.append(contentsOf: outputPorts.map({$0.id}))
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = [outputPort]
        for p in inputPorts {
            p.node = self
        }
        outputPort.node = self
    }
}

public class SubtractCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install(input: JelloCompilerInput) {}
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func write(input: JelloCompilerInput) {
        let fst = inputPorts.first!
        let typeId = declareType(dataType: fst.concreteDataType!)
        let zero = #id
        #globalDeclaration(opCode: SpirvOpConstantNull, [typeId, zero])
        var prevResultId = fst.incomingEdge?.outputPort.getOrReserveId() ?? zero
        guard let f = getSubtractOperation(typeId: typeId, dataType: fst.concreteDataType!) else {
            fatalError("\(fst.concreteDataType!) does not support the subtract operation")
        }
        for p in inputPorts.dropFirst().filter({$0.incomingEdge != nil}) {
            prevResultId = f(prevResultId, p.incomingEdge?.outputPort.getOrReserveId() ?? zero)
        }
        outputPorts.first!.setReservedId(reservedId: prevResultId)
    }
    
    func getSubtractOperation(typeId: UInt32, dataType: JelloConcreteDataType) -> ((UInt32, UInt32) -> UInt32)? {
        switch (dataType) {
        case .float, .float2, .float3, .float4:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpFSub, [typeId, resultId, a, b])
                return resultId
            }
        case .int:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpISub, [typeId, resultId, a, b])
                return resultId
            }
        default:
            return nil
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        ports.append(contentsOf: outputPorts.map({$0.id}))
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = [outputPort]
        for p in inputPorts {
            p.node = self
        }
        outputPort.node = self
    }
}

public class MultiplyCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install(input: JelloCompilerInput) {}
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func write(input: JelloCompilerInput) {
        let fst = inputPorts.first!
        let typeId = declareType(dataType: fst.concreteDataType!)
        let zero = #id
        #globalDeclaration(opCode: SpirvOpConstantNull, [typeId, zero])
        var prevResultId = fst.incomingEdge?.outputPort.getOrReserveId() ?? zero
        guard let f = getMultiplyOperation(typeId: typeId, dataType: fst.concreteDataType!) else {
            fatalError("\(fst.concreteDataType!) does not support the mult operation")
        }
        for p in inputPorts.dropFirst().filter({$0.incomingEdge != nil}) {
            prevResultId = f(prevResultId, p.incomingEdge?.outputPort.getOrReserveId() ?? zero)
        }
        outputPorts.first!.setReservedId(reservedId: prevResultId)
    }
    
    func getMultiplyOperation(typeId: UInt32, dataType: JelloConcreteDataType) -> ((UInt32, UInt32) -> UInt32)? {
        switch (dataType) {
        case .float, .float2, .float3, .float4:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpFMul, [typeId, resultId, a, b])
                return resultId
            }
        case .int:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpIMul, [typeId, resultId, a, b])
                return resultId
            }
        default:
            return nil
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        ports.append(contentsOf: outputPorts.map({$0.id}))
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = [outputPort]
        for p in inputPorts {
            p.node = self
        }
        outputPort.node = self
    }
}


public class DivideCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install(input: JelloCompilerInput) {}
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func write(input: JelloCompilerInput) {
        let fst = inputPorts.first!
        let typeId = declareType(dataType: fst.concreteDataType!)
        let zero = #id
        #globalDeclaration(opCode: SpirvOpConstantNull, [typeId, zero])
        var prevResultId = fst.incomingEdge?.outputPort.getOrReserveId() ?? zero
        guard let f = getDivideOperation(typeId: typeId, dataType: fst.concreteDataType!) else {
            fatalError("\(fst.concreteDataType!) does not support the divide operation")
        }
        for p in inputPorts.dropFirst().filter({$0.incomingEdge != nil}) {
            prevResultId = f(prevResultId, p.incomingEdge?.outputPort.getOrReserveId() ?? zero)
        }
        outputPorts.first!.setReservedId(reservedId: prevResultId)
    }
    
    func getDivideOperation(typeId: UInt32, dataType: JelloConcreteDataType) -> ((UInt32, UInt32) -> UInt32)? {
        switch (dataType) {
        case .float, .float2, .float3, .float4:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpFDiv, [typeId, resultId, a, b])
                return resultId
            }
        case .int:
            return { a, b in
                let resultId = #id
                #functionBody(opCode: SpirvOpSDiv, [typeId, resultId, a, b])
                return resultId
            }
        default:
            return nil
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        ports.append(contentsOf: outputPorts.map({$0.id}))
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = [outputPort]
        for p in inputPorts {
            p.node = self
        }
        outputPort.node = self
    }
}



public class LoadCompilerNode : CompilerNode {
    public var id: UUID
    private let normalize : Bool
    public var inputPorts: [InputCompilerPort] = []
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let loadResultId = #id
        #functionBody(opCode: SpirvOpLoad, [typeId, loadResultId, getPointerId()])
        if !normalize {
            outputPorts.first!.setReservedId(reservedId: loadResultId)
            return
        }
        let normalizeResultId = #id
        #functionBody(opCode: SpirvOpExtInst, [typeId, normalizeResultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Normalize.rawValue, loadResultId])
        outputPorts.first!.setReservedId(reservedId: normalizeResultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    public var constraints: [PortConstraint] { [] }
    public let getPointerId: () -> UInt32
    
    
    public init(id: UUID = UUID(), outputPort: OutputCompilerPort, type: JelloConcreteDataType, getPointerId: @escaping () -> UInt32, normalize: Bool) {
        self.id = id
        self.inputPorts =  []
        self.outputPorts = [outputPort]
        self.getPointerId = getPointerId
        self.normalize = normalize
        outputPort.concreteDataType = type
        outputPort.node = self
        
    }
}



public class SwizzleCompilerNode : CompilerNode {
    public var computationDomain: CompilerComputationDomain?

    public enum SwizzleComponentSelector {
        case zero
        case index(UInt8)
        
        public static func == (lhs: SwizzleComponentSelector, rhs: SwizzleComponentSelector) -> Bool {
            switch (lhs, rhs) {
            case (.zero, .zero):
                return true
            case (.index(let a), .index(let b)) where a == b:
                return true
            default:
                return false
            }
        }
    }
    
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    
    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let inputPort = inputPorts.first!
        let outputPort = outputPorts.first!
        if inputPort.incomingEdge == nil {
            let resultId = declareNullValueConstant(dataType: outputPort.concreteDataType!)
            outputPort.setReservedId(reservedId: resultId)
        } else {
            let inId = inputPort.incomingEdge!.outputPort.getOrReserveId()
            let resultTypeId = declareType(dataType: outputPort.concreteDataType!)
            var resultId = #id
            if inputPort.concreteDataType == .float {
                let nullId = declareNullValueConstant(dataType: .float)
                if outputPort.concreteDataType != .float {
                    // Special case for the float type
                    
                    let components = selectors.map({selector in switch(selector){
                    case .zero:
                        return nullId
                    case .index(let idx) where idx == 0:
                        return inId
                    default:
                        fatalError("Received unexpected index")
                    }})
                    #functionBody(opCode: SpirvOpCompositeConstruct, [resultTypeId, resultId], components)
                } else {
                    if let fst = selectors.first, fst == .zero {
                        resultId = nullId
                    } else {
                        resultId = inId
                    }
                }
            } else {
                let components = selectors.map({selector in switch(selector){
                case .zero:
                    return UInt32(0xFFFFFFFF)
                case .index(let idx):
                    return UInt32(idx)
                }})

                let inId = inputPort.incomingEdge!.outputPort.getOrReserveId()
                #functionBody(opCode: SpirvOpVectorShuffle, [resultTypeId, resultId, inId, inId], components)
            }
            outputPort.setReservedId(reservedId: resultId)
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    public var constraints: [PortConstraint] { [] }
    public var selectors: [SwizzleComponentSelector] = []
    
    public init(id: UUID = UUID(), inputPort: InputCompilerPort, outputPort: OutputCompilerPort, selectors: [SwizzleComponentSelector]) {
        self.id = id
        self.inputPorts =  [inputPort]
        self.outputPorts = [outputPort]
        self.selectors = selectors
        
        inputPort.node = self
        outputPort.node = self
    }
    
    public static func buildSelectors(componentCount: Int, components: [Float]) -> [SwizzleComponentSelector] {
        let results: [SwizzleComponentSelector] = components.map({ UInt8($0) == 0 ? .zero : .index(UInt8($0 - 1))})
        return Array(results[0..<componentCount])
    }
}


public class UnaryOperatorCompilerNode : CompilerNode {
    public var id: UUID
    private let spirvOperator: SpirvOp
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let resultId = #id
        if let inputId = inputPorts.first!.incomingEdge?.outputPort.getOrReserveId() {
            #functionBody(opCode: spirvOperator, [typeId, resultId, inputId])
        } else {
            let nullId = declareNullValueConstant(dataType: inputPorts.first!.concreteDataType!)
            #functionBody(opCode: spirvOperator, [typeId, resultId, nullId])
        }
        outputPorts.first!.setReservedId(reservedId: resultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    private let uniformIO: Bool
    public var constraints: [PortConstraint] {
        if uniformIO {
            var ports = inputPorts.map({$0.id})
            ports.append(contentsOf: outputPorts.map({$0.id}))
            return [SameTypesConstraint(ports: Set(ports))]
        } else {
            return []
        }
    }
    
    public init(id: UUID = UUID(), inputPort: InputCompilerPort, outputPort: OutputCompilerPort, spirvOperator: SpirvOp, uniformIO: Bool) {
        self.id = id
        self.inputPorts =  [inputPort]
        self.outputPorts = [outputPort]
        self.spirvOperator = spirvOperator
        self.uniformIO = uniformIO
        inputPort.node = self
        outputPort.node = self
    }
}

public class UnaryGLSL450OperatorCompilerNode : CompilerNode {
    public var id: UUID
    private let glsl450Operator: GLSLstd450
    public var computationDomain: CompilerComputationDomain?

    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    
    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let resultId = #id
        if let inputId = inputPorts.first!.incomingEdge?.outputPort.getOrReserveId() {
            let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, glsl450Operator.rawValue, inputId])
        } else {
            let nullId = declareNullValueConstant(dataType: inputPorts.first!.concreteDataType!)
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, glsl450Operator.rawValue, nullId])
        }
        outputPorts.first!.setReservedId(reservedId: resultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    private let uniformIO: Bool
    public var constraints: [PortConstraint] {
        if uniformIO {
            var ports = inputPorts.map({$0.id})
            ports.append(contentsOf: outputPorts.map({$0.id}))
            return [SameTypesConstraint(ports: Set(ports))]
        } else {
            return []
        }
    }
    
    
    public init(id: UUID = UUID(), inputPort: InputCompilerPort, outputPort: OutputCompilerPort, glsl450Operator: GLSLstd450, uniformIO: Bool) {
        self.id = id
        self.inputPorts =  [inputPort]
        self.outputPorts = [outputPort]
        self.glsl450Operator = glsl450Operator
        self.uniformIO = uniformIO
        inputPort.node = self
        outputPort.node = self
    }
}


public class BinaryGLSL450OperatorCompilerNode : CompilerNode {
    public var id: UUID
    private let glsl450Operator: GLSLstd450
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let resultId = #id
        let input1Id: UInt32 = inputPorts[0].incomingEdge?.outputPort.getOrReserveId() ?? declareNullValueConstant(dataType: inputPorts[0].concreteDataType!)
        let input2Id: UInt32 = inputPorts[1].incomingEdge?.outputPort.getOrReserveId() ?? declareNullValueConstant(dataType: inputPorts[1].concreteDataType!)
        #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, glsl450Operator.rawValue, input1Id, input2Id])
        outputPorts.first!.setReservedId(reservedId: resultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    private let uniformIO: Bool
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        if uniformIO {
            ports.append(contentsOf: outputPorts.map({$0.id}))
        }
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    public init(id: UUID = UUID(), inputPort1: InputCompilerPort, inputPort2: InputCompilerPort, outputPort: OutputCompilerPort, glsl450Operator: GLSLstd450, uniformIO: Bool) {
        self.id = id
        self.inputPorts =  [inputPort1, inputPort2]
        self.outputPorts = [outputPort]
        self.glsl450Operator = glsl450Operator
        self.uniformIO = uniformIO
        inputPort1.node = self
        inputPort2.node = self
        outputPort.node = self
    }
}


public class BinaryOperatorCompilerNode : CompilerNode {
    public var id: UUID
    private let spirvOperator: SpirvOp
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let resultId = #id
        let input1Id: UInt32 = inputPorts[0].incomingEdge?.outputPort.getOrReserveId() ?? declareNullValueConstant(dataType: inputPorts[0].concreteDataType!)
        let input2Id: UInt32 = inputPorts[1].incomingEdge?.outputPort.getOrReserveId() ?? declareNullValueConstant(dataType: inputPorts[1].concreteDataType!)
        #functionBody(opCode: spirvOperator, [typeId, resultId, input1Id, input2Id])
        outputPorts.first!.setReservedId(reservedId: resultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    private let uniformIO: Bool
    public var constraints: [PortConstraint] {
        var ports = inputPorts.map({$0.id})
        if uniformIO {
            ports.append(contentsOf: outputPorts.map({$0.id}))
        }
        return [SameTypesConstraint(ports: Set(ports))]
    }
    
    
    public init(id: UUID = UUID(), inputPort1: InputCompilerPort, inputPort2: InputCompilerPort, outputPort: OutputCompilerPort, spirvOperator: SpirvOp, uniformIO: Bool) {
        self.id = id
        self.inputPorts =  [inputPort1, inputPort2]
        self.outputPorts = [outputPort]
        self.spirvOperator = spirvOperator
        self.uniformIO = uniformIO
        inputPort1.node = self
        inputPort2.node = self
        outputPort.node = self
    }
}



public class MathExpressionCompilerNode : CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        if let mathExpression = expression {
            outputPorts.first!.setReservedId(reservedId: processMathExpression(expression: mathExpression))
        } else {
            let valueId = declareNullValueConstant(dataType: .float)
            outputPorts.first!.setReservedId(reservedId: valueId)
        }
    }
    
    private func processMathExpression(expression: MathExpression) -> UInt32 {
        switch(expression) {
        case .literal(let value):
            let floatId = declareType(dataType: .float)
            let resultId = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatId, resultId], float(value))
            return resultId
        case .variable(let v):
            let inputPort = inputPorts[v.rawValue]
            if let edge = inputPort.incomingEdge {
                return edge.outputPort.getOrReserveId()
            } else {
                let valueId = declareNullValueConstant(dataType: .float)
                return valueId
            }
        case .unaryOperator(let op, let subExpr):
            return processUnaryOperator(op: op, subExpr: subExpr)
        case .binaryOperator(let op, let subExpr1, let subExpr2):
            return processBinaryOperator(op: op, subExpr1: subExpr1, subExpr2: subExpr2)
        case .constant(let constant):
            return processConstant(constant: constant)
        }
    }
    
    private func processUnaryOperator(op: MathExpressionPrefixUnaryOperator, subExpr: MathExpression) -> UInt32 {
        let subExprResultId = processMathExpression(expression: subExpr)
        if op == .unaryPlus {
            return subExprResultId
        }
        let typeId = declareType(dataType: .float)
        let resultId = #id
        switch op {
        case .sqrt:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Sqrt.rawValue, subExprResultId])
            break
        case .floor:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Floor.rawValue, subExprResultId])
            break
        case .ceil:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Ceil.rawValue, subExprResultId])
            break
        case .round:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Round.rawValue, subExprResultId])
            break
        case .cos:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Cos.rawValue, subExprResultId])
        case .acos:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Acos.rawValue, subExprResultId])
        case .sin:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Sin.rawValue, subExprResultId])
        case .asin:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Asin.rawValue, subExprResultId])
        case .tan:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Tan.rawValue, subExprResultId])
        case .atan:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Atan.rawValue, subExprResultId])
        case .abs:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450FAbs.rawValue, subExprResultId])
            break
        case .log:
            #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Log.rawValue, subExprResultId])
            break
        case .negate:
            #functionBody(opCode: SpirvOpFNegate, [typeId, resultId, subExprResultId])
        case .unaryPlus:
            return subExprResultId
        }
        return resultId
    }
    
    
    private func processBinaryOperator(op: MathExpressionInfixBinaryOperator, subExpr1: MathExpression, subExpr2: MathExpression) -> UInt32 {
        let subExprResultId1 = processMathExpression(expression: subExpr1)
        let subExprResultId2 = processMathExpression(expression: subExpr2)
        let resultId = #id
        let typeId = declareType(dataType: .float)
        switch op {
            case .add:
                #functionBody(opCode: SpirvOpFAdd, [typeId, resultId, subExprResultId1, subExprResultId2])
                break
            case .subtract:
                #functionBody(opCode: SpirvOpFSub, [typeId, resultId, subExprResultId1, subExprResultId2])
                break
            case .divide:
                #functionBody(opCode: SpirvOpFDiv, [typeId, resultId, subExprResultId1, subExprResultId2])
                break
            case .multiply:
                #functionBody(opCode: SpirvOpFMul, [typeId, resultId, subExprResultId1, subExprResultId2])
            break
            case .pow:
                #functionBody(opCode: SpirvOpExtInst, [typeId, resultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Pow.rawValue, subExprResultId1, subExprResultId2])
            break
        }
        return resultId
    }
    
    private func processConstant(constant: MathExpressionConstant) -> UInt32 {
        let typeId = declareType(dataType: .float)
        let resultId = #id
        switch constant {
            case .pi:
            #globalDeclaration(opCode: SpirvOpConstant, [typeId, resultId], float(.pi))
        case .e:
            #globalDeclaration(opCode: SpirvOpConstant, [typeId, resultId], float(2.7182818284590452353602874713526624977572))
        case .tau:
            #globalDeclaration(opCode: SpirvOpConstant, [typeId, resultId], float(.pi * 2))
        case .phi:
            #globalDeclaration(opCode: SpirvOpConstant, [typeId, resultId], float(1.618033988749))
        }
        return resultId
    }
    
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    private let expression: MathExpression?
    public var constraints: [PortConstraint] { [] }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort, expression: MathExpression?) {
        self.id = id
        self.inputPorts =  inputPorts
        self.outputPorts = [outputPort]
        self.expression = expression
        for port in inputPorts {
            port.node = self
        }
        outputPort.node = self
    }
}



public class CombineCompilerNode : CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let count = inputPorts.count
        let typeId = switch count {
        case 1:
            declareType(dataType: .float)
        case 2:
            declareType(dataType: .float2)
        case 3:
            declareType(dataType: .float3)
        case 4:
            declareType(dataType: .float4)
        default:
            fatalError("Only inputs of up to four components allowed")
        }
        
        let zeroId = inputPorts.contains(where: {$0.incomingEdge == nil}) ? declareNullValueConstant(dataType: .float) : nil
        if inputPorts.count == 1 {
            let id = if let edge = inputPorts.first!.incomingEdge {
                edge.outputPort.getOrReserveId()
            } else {
                zeroId!
            }
            outputPorts.first!.setReservedId(reservedId: id)
        } else {
            let components = inputPorts.map {
                if let edge = $0.incomingEdge {
                    edge.outputPort.getOrReserveId()
                } else {
                    zeroId!
                }
            }
            let resultId = #id
            #functionBody(opCode: SpirvOpCompositeConstruct, [typeId, resultId], components)
            outputPorts.first!.setReservedId(reservedId: resultId)
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    
    public var constraints: [PortConstraint] { [] }
    
    public init(id: UUID = UUID(), inputPorts: [InputCompilerPort], outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = [outputPort]
        for inputPort in inputPorts {
            inputPort.node = self
        }
        outputPort.node = self
    }
}



public class SeparateCompilerNode : CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let inputPort = inputPorts.first!
        let floatId = declareType(dataType: .float)
        for i in outputPorts.indices {
            let outputPort = outputPorts[i]
            if outputPort.outgoingEdges.count > 0 {
                let resultId = #id
                #functionBody(opCode: SpirvOpCompositeExtract, [floatId, resultId, inputPort.incomingEdge!.outputPort.getOrReserveId(), UInt32(i)])
                outputPort.setReservedId(reservedId: resultId)
            }
        }
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    
    public var constraints: [PortConstraint] { [] }
    
    public init(id: UUID = UUID(), inputPort: InputCompilerPort, outputPorts: [OutputCompilerPort]) {
        self.id = id
        self.inputPorts = [inputPort]
        self.outputPorts = outputPorts
        for outputPort in outputPorts {
            outputPort.node = self
        }
        inputPort.node = self
    }
}




public class SampleCompilerNode : CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
    }
    
    public func write(input: JelloCompilerInput) {
        let fieldInput = inputPorts[0]
        let positionInput = inputPorts[1]
        
        let maybeLodInput = inputPorts.count > 2 ? inputPorts[2] : nil

        let maybeFieldOutputPort = fieldInput.incomingEdge?.outputPort
        let maybePositionOutputPort = positionInput.incomingEdge?.outputPort
        let maybeLodOutputPort = maybeLodInput?.incomingEdge?.outputPort
        let maybeFieldId = maybeFieldOutputPort?.getOrReserveId()
        let maybePositionId = maybePositionOutputPort?.getOrReserveId()
        let maybeLodId = maybeLodOutputPort?.getOrReserveId()
        
        var resultId: UInt32 = 0
        
        switch fieldInput.concreteDataType {
        case .float:
            fatalError("Unexpected Type")
        case .float2:
            fatalError("Unexpected Type")
        case .float3:
            fatalError("Unexpected Type")
        case .float4:
            fatalError("Unexpected Type")
        case .int:
            fatalError("Unexpected Type")
        case .bool:
            fatalError("Unexpected Type")
        case .texture1d_float:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilitySampled1D.rawValue])
                let floatType = declareType(dataType: .float)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId,  SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .texture1d_float2:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilitySampled1D.rawValue])
                let float2Type = declareType(dataType: .float2)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .texture1d_float3:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilitySampled1D.rawValue])
                let float3Type = declareType(dataType: .float3)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .texture1d_float4:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilitySampled1D.rawValue])
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }
        case .texture2d_float:
            if let fieldId = maybeFieldId {
                let floatType = declareType(dataType: .float)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId,  SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .texture2d_float2:
            if let fieldId = maybeFieldId {
                let float2Type = declareType(dataType: .float2)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .texture2d_float3:
            if let fieldId = maybeFieldId {
                let float3Type = declareType(dataType: .float3)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .texture2d_float4:
            if let fieldId = maybeFieldId {
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float2)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }
        case .texture3d_float:
            if let fieldId = maybeFieldId {
                let floatType = declareType(dataType: .float)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId,  SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpCompositeExtract, [floatType, resultId, intermediateResultId, 0])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .texture3d_float2:
            if let fieldId = maybeFieldId {
                let float2Type = declareType(dataType: .float2)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, resultId, intermediateResultId, intermediateResultId, 0, 1])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .texture3d_float3:
            if let fieldId = maybeFieldId {
                let float3Type = declareType(dataType: .float3)
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                let intermediateResultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, intermediateResultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                    #functionBody(opCode: SpirvOpVectorShuffle, [float3Type, resultId, intermediateResultId, intermediateResultId, 0, 1, 2])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .texture3d_float4:
            if let fieldId = maybeFieldId {
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float)
                    }
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, positionId, SpirvOpImageQueryLod.rawValue, lodId])
                } else {
                    var lodId = maybeLodId ?? 0
                    if maybeLodId == nil {
                        lodId = declareNullValueConstant(dataType: .float2)
                    }
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpImageSampleExplicitLod, [float4Type, resultId, fieldId, nullVal, SpirvOpImageQueryLod.rawValue, lodId])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }

        case .proceduralField1d_float:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let floatType = declareType(dataType: .float)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .proceduralField1d_float2:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float2Type = declareType(dataType: .float2)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .proceduralField1d_float3:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float3Type = declareType(dataType: .float3)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .proceduralField1d_float4:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float)
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }
        case .proceduralField2d_float:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let floatType = declareType(dataType: .float)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .proceduralField2d_float2:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float2Type = declareType(dataType: .float2)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .proceduralField2d_float3:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float3Type = declareType(dataType: .float3)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .proceduralField2d_float4:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float2)
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }
        case .proceduralField3d_float:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let floatType = declareType(dataType: .float)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpFunctionCall, [floatType, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float)
                resultId = nullVal
            }
        case .proceduralField3d_float2:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float2Type = declareType(dataType: .float2)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpFunctionCall, [float2Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float2)
                resultId = nullVal
            }
        case .proceduralField3d_float3:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float3Type = declareType(dataType: .float3)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpFunctionCall, [float3Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float3)
                resultId = nullVal
            }
        case .proceduralField3d_float4:
            if let fieldId = maybeFieldId {
                #capability(opCode: SpirvOpCapability, [SpirvCapabilityGroupNonUniformQuad.rawValue])
                let float4Type = declareType(dataType: .float4)
                resultId = #id
                if let positionId = maybePositionId {
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, positionId])
                } else {
                    let nullVal = declareNullValueConstant(dataType: .float3)
                    #functionBody(opCode: SpirvOpFunctionCall, [float4Type, resultId, fieldId, nullVal])
                }
            } else {
                let nullVal = declareNullValueConstant(dataType: .float4)
                resultId = nullVal
            }
        case .slabMaterial:
            fatalError("Unexpected Type")
        case .none:
            fatalError("Expected Concrete Type")
        }
        
        outputPorts[0].setReservedId(reservedId: resultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    
    public var constraints: [PortConstraint] {
        return [
            SameDimensionalityConstraint(ports: Set([inputPorts[0].id, inputPorts[1].id])),
            SameCompositeSizeConstraint(ports: Set<UUID>([inputPorts[0].id, outputPorts[0].id]))
        ]
    }
    
    public init(id: UUID = UUID(), fieldInputPort: InputCompilerPort, positionInputPort: InputCompilerPort, lodInputPort: InputCompilerPort?, outputPort: OutputCompilerPort) {
        self.id = id
        self.inputPorts = [fieldInputPort, positionInputPort]
        if let lodPort = lodInputPort {
            self.inputPorts.append(lodPort)
        }
        self.outputPorts = [outputPort]
        for inputPort in inputPorts {
            inputPort.node = self
        }
        for outputPort in outputPorts {
            outputPort.node = self
        }
    }
}



public class ComputeCompilerNode : CompilerNode & HasComputationDimensionCompilerNode & SubgraphCompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDimension: CompilerComputationDimension
    public var computationDomain: CompilerComputationDomain?
    public var subgraph: JelloCompilerInput? = nil
    private var inputTexId: UInt32 = 0
    private var sampledImageTypeId: UInt32 = 0

    public func build(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
        let format: JelloIOTexture.TextureFormat = switch inputPorts.first!.concreteDataType {
            case .float: JelloIOTexture.TextureFormat.R32f
            case .float2: JelloIOTexture.TextureFormat.Rgba32f
            case .float3: JelloIOTexture.TextureFormat.Rgba32f
            case .float4: JelloIOTexture.TextureFormat.Rgba32f
            default: fatalError("Unsupported Data Type")
        }
        
        let packing: JelloIOTexture.TexturePacking = switch inputPorts.first!.concreteDataType {
            case .float: .float
            case .float2: .float2
            case .float3: .float3
            case .float4: .float4
            default: fatalError("Unsupported Data Type")
        }

        let nodes = input.graph.nodes
        var inputTextures: [JelloIOTexture] = []
        let compute = #document({
            let entryPoint = #id
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
            let glsl450Id = #id
            #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
            JelloCompilerBlackboard.glsl450ExtId = glsl450Id

            var dimensions: [UInt32] = [1, 1, 1]
            if case .dimension(_, let y, let z) = computationDimension {
                if y == 1 && z == 1 {
                    dimensions[0] = 64
                } else if z == 1 {
                    dimensions[0] = 8
                    dimensions[1] = 8
                } else {
                    dimensions[0] = 4
                    dimensions[1] = 4
                    dimensions[2] = 4
                }
            }
            
            #executionMode(opCode: SpirvOpExecutionMode, [entryPoint, SpirvExecutionModeLocalSize.rawValue], dimensions)
            
            #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
            for node in nodes {
                node.install(input: input)
            }
            inputTextures = JelloCompilerBlackboard.inputComputeTextures
            let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
            
            #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelGLCompute.rawValue], [entryPoint], #stringLiteral("computeMain"), JelloCompilerBlackboard.inputComputeIds)
            let typeComputeFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
            #debugNames(opCode: SpirvOpName, [typeComputeFunction], #stringLiteral("computeMain"))
            #functionHead(opCode: SpirvOpFunction, [typeVoid, entryPoint, 0, typeComputeFunction])
            #functionHead(opCode: SpirvOpLabel, [#id])
            for node in input.graph.nodes {
                node.write(input: input)
            }
            #functionBody(opCode: SpirvOpReturn)
            #functionBody(opCode: SpirvOpFunctionEnd)
            SpirvFunction.instance.writeFunction()
            JelloCompilerBlackboard.clear()
        })
        
        for outputPort in nodes.flatMap({$0.outputPorts}) {
            outputPort.clearReservation()
        }
        
        return JelloCompilerOutputStage(id: input.id, dependencies: input.dependencies, dependants: input.dependants, domain: computationDomain!, shaders: [.compute(self.computationDimension, compute, inputTextures,  JelloIOTexture(originatingStage: self.id, size: computationDimension, format: format, packing: packing))])
    }
    
    public func install(input: JelloCompilerInput) {
        let format: JelloIOTexture.TextureFormat = switch inputPorts.first!.concreteDataType {
            case .float: JelloIOTexture.TextureFormat.R32f
            case .float2: JelloIOTexture.TextureFormat.Rgba32f
            case .float3: JelloIOTexture.TextureFormat.Rgba32f
            case .float4: JelloIOTexture.TextureFormat.Rgba32f
            default: fatalError("Unsupported Data Type")
        }
        
        let spirvFormat: SpirvImageFormat = switch inputPorts.first!.concreteDataType {
            case .float: SpirvImageFormatR32f
            case .float2: SpirvImageFormatRgba32f
            case .float3: SpirvImageFormatRgba32f
            case .float4: SpirvImageFormatRgba32f
            default: fatalError("Unsupported Data Type")
        }
        
        let packing: JelloIOTexture.TexturePacking = switch inputPorts.first!.concreteDataType {
            case .float: .float
            case .float2: .float2
            case .float3: .float3
            case .float4: .float4
            default: fatalError("Unsupported Data Type")
        }
        let index = JelloCompilerBlackboard.inputComputeTextures.count
        let dim = outputPorts.first!.concreteDataType?.dimensionality ?? .d1
        let floatType = declareType(dataType: .float)
        let imageType = #typeDeclaration(opCode: SpirvOpTypeImage, [floatType, (dim == .d1 ? SpirvDim1D : (dim == .d2 ? SpirvDim2D : SpirvDim3D)).rawValue], [0 /* No depth */, 0 /* Not arrayed */, 0 /* single sampled */, 1 /* Sampled */, spirvFormat.rawValue, 0 /* Read Only */])
        sampledImageTypeId = #typeDeclaration(opCode: SpirvOpTypeSampledImage, [imageType])
        inputTexId = #id
        // Compute shader inputs get binding 3
        #annotation(opCode: SpirvOpDecorate, [inputTexId, SpirvDecorationDescriptorSet.rawValue, 3])
        #annotation(opCode: SpirvOpDecorate, [inputTexId, SpirvDecorationBinding.rawValue, UInt32(index)])

        let imagePointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, sampledImageTypeId])
        #globalDeclaration(opCode: SpirvOpVariable, [imagePointerTypeId, inputTexId, SpirvStorageClassUniformConstant.rawValue])
        JelloCompilerBlackboard.inputComputeTextures.append(JelloIOTexture(originatingStage: self.id, size: self.computationDimension,  format: format, packing: packing))
        JelloCompilerBlackboard.inputComputeIds.append(inputTexId)
    }
    
    public func write(input: JelloCompilerInput) {
        let resultId = outputPorts.first!.getOrReserveId()
        #functionBody(opCode: SpirvOpLoad, [sampledImageTypeId, resultId, inputTexId])
    }
    
    public var branchTags: Set<UUID>
    public var branches: [UUID] = []
    
    public var constraints: [PortConstraint] {
        var p = inputPorts.map({$0.id})
        p.append(contentsOf: outputPorts.map({$0.id}))
        return [SameCompositeSizeConstraint(ports: Set(p))]
    }
    
    public init(id: UUID = UUID(), inputPort: InputCompilerPort, outputPort: OutputCompilerPort, computationDimension: CompilerComputationDimension) {
        self.id = id
        self.inputPorts = [inputPort]
        self.outputPorts = [outputPort]
        self.computationDimension = computationDimension
        self.branchTags = Set()
        for p in inputPorts {
            p.node = self
            p.newBranchId = self.id
            p.newSubgraphId = self.id
        }
        for outputPort in outputPorts {
            outputPort.node = self
        }
    }
}
    

public class MaterialOutputCompilerNode: CompilerNode & SubgraphCompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install(input: JelloCompilerInput) {}
    public func write(input: JelloCompilerInput) {}
    public var branchTags: Set<UUID>
    public var subgraphTags: Set<UUID>
    public var computationDomain: CompilerComputationDomain?
    public var subgraph: JelloCompilerInput? = nil

    public func build(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
        try compileSpirvFragmentShader(input: input, outputBody: {})
    }

    public var constraints: [PortConstraint] { [] }
    public init(id: UUID, inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        self.subgraphTags = Set([self.id])
        for p in inputPorts {
            p.node = self
            p.newBranchId = self.id
            p.newSubgraphId = self.id
        }
    }
}
