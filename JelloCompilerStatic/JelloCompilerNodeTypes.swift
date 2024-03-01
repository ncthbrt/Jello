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
    public var computationDomain: CompilerComputationDomain?
    
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
    public var computationDomain: CompilerComputationDomain? = .transformDependant
    public var subgraph: JelloCompilerInput? = nil
    
    public func buildShader(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
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



public class BuiltInCompilerNode : CompilerNode {
    public var id: UUID
    private let normalize : Bool
    public var inputPorts: [InputCompilerPort] = []
    public var outputPorts: [OutputCompilerPort]
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?

    public func install(input: JelloCompilerInput) {
        self.requestPointerId()
    }
    
    public func write(input: JelloCompilerInput) {
        let typeId = declareType(dataType: outputPorts.first!.concreteDataType!)
        let resultId = getPointerId()
        if !normalize {
            outputPorts.first!.setReservedId(reservedId: resultId)
            return
        }
        let normalizeResultId = #id
        #functionBody(opCode: SpirvOpExtInst, [typeId, normalizeResultId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Normalize.rawValue, resultId])
        outputPorts.first!.setReservedId(reservedId: normalizeResultId)
    }
    
    public var branchTags: Set<UUID> = []
    public var branches: [UUID] = []
    public var constraints: [PortConstraint] { [] }
    public let getPointerId: () -> UInt32
    public let requestPointerId: () -> ()
    
    
    public init(id: UUID = UUID(), outputPort: OutputCompilerPort, type: JelloConcreteDataType, getPointerId: @escaping () -> UInt32, requestPointerId: @escaping () -> (), normalize: Bool, computationDomain: CompilerComputationDomain) {
        self.id = id
        self.inputPorts =  []
        self.outputPorts = [outputPort]
        self.getPointerId = getPointerId
        self.normalize = normalize
        self.requestPointerId = requestPointerId
        self.computationDomain = computationDomain
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
    
    public func buildShader(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
        var shaders: [SpirvShader] = []
        if (computationDomain ?? .constant).contains(.modelDependant) {
            shaders.append(try buildComputeRasterizerShader(input: input))
        }
        shaders.append(try buildOutputSpirvShader(input: input))
        return JelloCompilerOutputStage(id: input.id, dependencies: input.dependencies, dependants: input.dependants, shaders: shaders)
    }
    
    private func buildComputeRasterizerShader(input: JelloCompilerInput) throws -> SpirvShader {
        let nodes = input.graph.nodes
        var outputTextureId: UInt32 = 0
        let compute = #document({
            let entryPoint = #id
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityVariablePointersStorageBuffer.rawValue])

            let glsl450Id = #id
            #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
            JelloCompilerBlackboard.glsl450ExtId = glsl450Id
            
            let dimensions: [UInt32] = [128, 1, 1]
            
            #executionMode(opCode: SpirvOpExecutionMode, [entryPoint, SpirvExecutionModeLocalSize.rawValue], dimensions)
            
            #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
            
            JelloCompilerBlackboard.gl_GlobalInvocationID = #id
            let intType = declareType(dataType: .int)
            let int3Type = #typeDeclaration(opCode: SpirvOpTypeVector, [intType, 3])
            
            let int3PointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, int3Type])
            #globalDeclaration(opCode: SpirvOpVariable, [int3PointerType, JelloCompilerBlackboard.gl_GlobalInvocationID, SpirvStorageClassInput.rawValue])
            #annotation(opCode: SpirvOpDecorate, [JelloCompilerBlackboard.gl_GlobalInvocationID, SpirvDecorationBuiltIn.rawValue, SpirvBuiltInGlobalInvocationId.rawValue])
            
            // Declare inputs for vertex data
            let vertexDataTypeId = VertexData.register()
            var vertexDataOffset: UInt32 = 0
            #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId, 0, SpirvDecorationOffset.rawValue, vertexDataOffset])
            vertexDataOffset += 16
            #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId, 1, SpirvDecorationOffset.rawValue, vertexDataOffset])
            vertexDataOffset += 16
            #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId, 2, SpirvDecorationOffset.rawValue, vertexDataOffset])
            vertexDataOffset += 16
            #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId, 3, SpirvDecorationOffset.rawValue, vertexDataOffset])
            vertexDataOffset += 16
            #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId, 4, SpirvDecorationOffset.rawValue, vertexDataOffset])
            vertexDataOffset += 16

            #annotation(opCode: SpirvOpDecorate, [vertexDataTypeId, SpirvDecorationBlock.rawValue])
            let vertexDataBufferPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, vertexDataTypeId])
            #annotation(opCode: SpirvOpDecorate, [vertexDataBufferPointerTypeId, SpirvDecorationArrayStride.rawValue, vertexDataOffset])
            
            let verticesDataBuffer = #id
            #globalDeclaration(opCode: SpirvOpVariable, [vertexDataBufferPointerTypeId, verticesDataBuffer, SpirvStorageClassStorageBuffer.rawValue])
            #debugNames(opCode: SpirvOpName, [verticesDataBuffer], #stringLiteral("vertices"))
            #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer, SpirvDecorationDescriptorSet.rawValue, geometryInputDescriptorSet])
            #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer, SpirvDecorationBinding.rawValue, verticesBinding])
            JelloCompilerBlackboard.entryPointInterfaceIds.append(verticesDataBuffer)
            #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer, SpirvDecorationNonWritable.rawValue])

            
            
            let indicesDataBufferTypeId = #typeDeclaration(opCode: SpirvOpTypeStruct, [intType])
            #debugNames(opCode: SpirvOpMemberName, [indicesDataBufferTypeId, 0], #stringLiteral("index"))
            #annotation(opCode: SpirvOpDecorate, [indicesDataBufferTypeId, SpirvDecorationBlock.rawValue])
            #annotation(opCode: SpirvOpMemberDecorate, [indicesDataBufferTypeId, 0, SpirvDecorationOffset.rawValue, 0])
            let indicesDataBufferPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, indicesDataBufferTypeId])
            #annotation(opCode: SpirvOpDecorate, [indicesDataBufferPointerTypeId, SpirvDecorationArrayStride.rawValue, 4])

            let indicesDataBuffer = #id
            #debugNames(opCode: SpirvOpName, [indicesDataBuffer], #stringLiteral("indices"))
            #globalDeclaration(opCode: SpirvOpVariable, [indicesDataBufferPointerTypeId, indicesDataBuffer, SpirvStorageClassStorageBuffer.rawValue])
            #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer, SpirvDecorationDescriptorSet.rawValue, geometryInputDescriptorSet])
            #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer, SpirvDecorationBinding.rawValue, indicesBinding])
            JelloCompilerBlackboard.entryPointInterfaceIds.append(indicesDataBuffer)
            #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer, SpirvDecorationNonWritable.rawValue])


            // Declare output for triangle IDs
            
            let triangleIndexTextureTypeId = #typeDeclaration(opCode: SpirvOpTypeImage, [intType, SpirvDim2D.rawValue], [0 /* No depth */, 0 /* Not arrayed */, 0 /* Single sampled */, 2 /* Compatible w/ Read Write */, SpirvImageFormatR32i.rawValue])
            let triangleIndexOutputId = #id
            JelloCompilerBlackboard.entryPointInterfaceIds.append(triangleIndexOutputId)
            outputTextureId = triangleIndexOutputId

            #annotation(opCode: SpirvOpDecorate, [triangleIndexOutputId, SpirvDecorationDescriptorSet.rawValue, computeTextureInputOutputDescriptorSet])
            #annotation(opCode: SpirvOpDecorate, [triangleIndexOutputId, SpirvDecorationBinding.rawValue, computeTextureOutputBinding])

            let triangleIndexTexPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniform.rawValue, triangleIndexTextureTypeId])
            #globalDeclaration(opCode: SpirvOpVariable, [triangleIndexTexPointerTypeId, triangleIndexOutputId, SpirvStorageClassUniform.rawValue])
            
            for node in nodes {
                node.install(input: input)
            }
            
            let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
            
            let floatType = declareType(dataType: .float)
            
            #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelGLCompute.rawValue], [entryPoint], #stringLiteral("computeMain"), JelloCompilerBlackboard.entryPointInterfaceIds, [JelloCompilerBlackboard.gl_GlobalInvocationID])
            
            let typeComputeFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
            #debugNames(opCode: SpirvOpName, [typeComputeFunction], #stringLiteral("computeMain"))
            #functionHead(opCode: SpirvOpFunction, [typeVoid, entryPoint, 0, typeComputeFunction])
            let globalScopeId = #id
            #functionHead(opCode: SpirvOpLabel, [globalScopeId])

            let invocationId = #id
            let triangleIndexId = #id
            #functionBody(opCode: SpirvOpLoad, [int3Type, invocationId, JelloCompilerBlackboard.gl_GlobalInvocationID])
            #functionBody(opCode: SpirvOpCompositeExtract, [intType, triangleIndexId, invocationId, 0])

            let threeInt = #id
            let oneInt = #id
            let indicesIndex1 = #id
            let indicesIndex2 = #id
            let indicesIndex3 = #id
            let indicesIndexAccessChain1 = #id
            let indicesIndexAccessChain2 = #id
            let indicesIndexAccessChain3 = #id
            let index1 = #id
            let index2 = #id
            let index3 = #id
            let vertexAccessChain1 = #id
            let vertexAccessChain2 = #id
            let vertexAccessChain3 = #id
            let vertex1 = #id
            let vertex2 = #id
            let vertex3 = #id
            let uv1 = #id
            let uv2 = #id
            let uv3 = #id
            #globalDeclaration(opCode: SpirvOpConstant, [intType, threeInt, 3])
            #globalDeclaration(opCode: SpirvOpConstant, [intType, oneInt, 1])
            #functionBody(opCode: SpirvOpIMul, [intType, indicesIndex1, triangleIndexId, threeInt])
            #functionBody(opCode: SpirvOpIAdd, [intType, indicesIndex2, indicesIndex1, oneInt])
            #functionBody(opCode: SpirvOpIAdd, [intType, indicesIndex3, indicesIndex2, oneInt])
            let zeroInt = #id
            #globalDeclaration(opCode: SpirvOpConstant, [intType, zeroInt, 0])
            let intStorageBufferPointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, intType])
            #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain1, indicesDataBuffer, indicesIndex1, zeroInt])
            #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain2, indicesDataBuffer, indicesIndex2, zeroInt])
            #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain3, indicesDataBuffer, indicesIndex3, zeroInt])
            #functionBody(opCode: SpirvOpLoad, [intType, index1, indicesIndexAccessChain1])
            #functionBody(opCode: SpirvOpLoad, [intType, index2, indicesIndexAccessChain2])
            #functionBody(opCode: SpirvOpLoad, [intType, index3, indicesIndexAccessChain3])
            
            let vertexStorageBufferPointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, vertexDataTypeId])
            #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain1, verticesDataBuffer, index1])
            #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain2, verticesDataBuffer, index2])
            #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain3, verticesDataBuffer, index3])
            #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId, vertex1, vertexAccessChain1])
            #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId, vertex2, vertexAccessChain2])
            #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId, vertex3, vertexAccessChain3])
            
            let float2Type = declareType(dataType: .float2)
            #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv1, vertex1, 1])
            #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv2, vertex2, 1])
            #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv3, vertex3, 1])

                        
            let minUVId = #id
            let maxUVId = #id
        
            // START CALCULATE UV BOUNDING BOX
            let minUV1UV2 = #id
            #functionBody(opCode: SpirvOpExtInst, [float2Type, minUV1UV2, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450FMin.rawValue, uv1, uv2])
            #functionBody(opCode: SpirvOpExtInst, [float2Type, minUVId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450FMax.rawValue, minUV1UV2, uv3])
            
            let maxUV1UV2 = #id
            #functionBody(opCode: SpirvOpExtInst, [float2Type, maxUV1UV2, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450FMax.rawValue, uv1, uv2])
            #functionBody(opCode: SpirvOpExtInst, [float2Type, maxUVId, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450FMax.rawValue, maxUV1UV2, uv3])
            
            let pixelBoundsMinF = #id
            let pixelBoundsMaxF = #id
            let textureSizeF = #id
            
            let zeroF = declareNullValueConstant(dataType: .float)
            let sizeXF = #id
            let sizeYF = #id
            
            let oneFId = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, oneFId], float(Float(1)))
            let oneIId = #id
            #globalDeclaration(opCode: SpirvOpConstant, [intType, oneIId], int(1))
            
            if case .dimension(let dimX, let dimY, _) = computationDimension {
                #globalDeclaration(opCode: SpirvOpConstant, [floatType, sizeXF], float(Float(dimX)))
                #globalDeclaration(opCode: SpirvOpConstant, [floatType, sizeYF], float(Float(dimY)))
                #globalDeclaration(opCode: SpirvOpConstantComposite, [float2Type, textureSizeF, sizeXF, sizeYF])
            }
            #functionBody(opCode: SpirvOpFMul, [float2Type, pixelBoundsMinF, minUVId, textureSizeF])
            #functionBody(opCode: SpirvOpFMul, [float2Type, pixelBoundsMaxF, maxUVId, textureSizeF])
            
            
            let conservativePixelBoundsMaxF = #id
            #functionBody(opCode: SpirvOpExtInst, [float2Type, conservativePixelBoundsMaxF, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Ceil.rawValue, pixelBoundsMaxF])

            
            let int2Type = #typeDeclaration(opCode: SpirvOpTypeVector, [intType, 2])
            
            let pixelBoundsMinI = #id
            #functionBody(opCode: SpirvOpConvertFToS, [int2Type, pixelBoundsMinI, pixelBoundsMinF])
            
            let pixelBoundsMaxI = #id
            #functionBody(opCode: SpirvOpConvertFToS, [int2Type, pixelBoundsMaxI, conservativePixelBoundsMaxF])
            
            let pixelMinX = #id
            #functionBody(opCode: SpirvOpCompositeExtract, [intType, pixelMinX, pixelBoundsMinI, 0])
            let pixelMinY = #id
            #functionBody(opCode: SpirvOpCompositeExtract, [intType, pixelMinY, pixelBoundsMinI, 1])
            let pixelMaxX = #id
            #functionBody(opCode: SpirvOpCompositeExtract, [intType, pixelMaxX, pixelBoundsMaxI, 0])
            let pixelMaxY = #id
            #functionBody(opCode: SpirvOpCompositeExtract, [intType, pixelMaxY, pixelBoundsMaxI, 1])
            
            // END CALCULATE UV BOUNDING BOX
            
            
            // BEGIN CONSTANT VALUES FOR CALCULATING BARYCENTRIC COORDS
            let deltaUV2UV1 = #id
            let deltaUV3UV1 = #id
            let baryDenominator = #id
            let oneOverBaryDenominator = #id
            
            let deltaUV2UV1X = #id
            let deltaUV2UV1Y = #id
            let deltaUV3UV1X = #id
            let deltaUV3UV1Y = #id
            
            let boolType = declareType(dataType: .bool)
            #functionBody(opCode: SpirvOpFSub, [float2Type, deltaUV2UV1, uv2, uv1])
            #functionBody(opCode: SpirvOpFSub, [float2Type, deltaUV3UV1, uv3, uv1])

            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaUV2UV1X, deltaUV2UV1, 0])
            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaUV2UV1Y, deltaUV2UV1, 1])
            
            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaUV3UV1X, deltaUV3UV1, 0])
            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaUV3UV1Y, deltaUV3UV1, 1])
            
            
            let deltaUV2UV1XMdeltaUV3UV1Y = #id
            #functionBody(opCode: SpirvOpFMul, [floatType, deltaUV2UV1XMdeltaUV3UV1Y, deltaUV2UV1X, deltaUV3UV1Y])
            let deltaUV3UV1XMdeltaUV2UV1Y = #id
            #functionBody(opCode: SpirvOpFMul, [floatType, deltaUV3UV1XMdeltaUV2UV1Y, deltaUV3UV1X, deltaUV2UV1Y])
            
            #functionBody(opCode: SpirvOpFSub, [floatType, baryDenominator, deltaUV2UV1XMdeltaUV3UV1Y, deltaUV3UV1XMdeltaUV2UV1Y])
            
            let ifDenominatorZeroCondValue = #id
            #functionBody(opCode: SpirvOpFOrdEqual, [boolType, ifDenominatorZeroCondValue, zeroF, baryDenominator])
            
            let ifDenominatorNonZeroMergeLabel = #id
            let ifDenominatorZeroLabel = #id
            #functionBody(opCode: SpirvOpSelectionMerge, [ifDenominatorNonZeroMergeLabel, 0])
            #functionBody(opCode: SpirvOpBranchConditional, [ifDenominatorZeroCondValue, ifDenominatorZeroLabel, ifDenominatorNonZeroMergeLabel])
            
            #functionBody(opCode: SpirvOpLabel, [ifDenominatorZeroLabel])
            #functionBody(opCode: SpirvOpReturn) // Return early if uv triangle has zero size
            
            #functionBody(opCode: SpirvOpLabel, [ifDenominatorNonZeroMergeLabel])
            #functionBody(opCode: SpirvOpFDiv, [floatType, oneOverBaryDenominator, oneFId, baryDenominator])
            
            // END CONSTANT VALUES FOR CALCULATING BARYCENTRIC COORDS
            
            // BEGIN CONSTANT VALUES FOR CALCULATING UV COORDS
            let uvDeltaX = #id
            let uvDeltaY = #id
            
            #functionBody(opCode: SpirvOpFDiv, [floatType, uvDeltaX, oneFId, sizeXF])
            #functionBody(opCode: SpirvOpFDiv, [floatType, uvDeltaY, oneFId, sizeYF])

            let startUVX = #id
            let startUVY = #id
            
            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, startUVX, minUVId, 0])
            #functionBody(opCode: SpirvOpCompositeExtract, [floatType, startUVY, minUVId, 1])
            // END CONSTANT VALUES FOR CALCULATING UV COORDS
            
            
            let xLoopMergePoint = #id
            let xContinueTarget = #id
            let xLoopHead = #id
            let xLoopBody = #id
            
            let yLoopMergePoint = #id
            let yContinueTarget = #id
            let yLoopHead = #id
            let yLoopBody = #id
            
            let xPixelPlusOne = #id
            let xUVNext = #id
            let yPixelPlusOne = #id
            let yUVNext = #id
            
            #functionBody(opCode: SpirvOpBranch, [xLoopHead])
            #functionBody(opCode: SpirvOpLabel, [xLoopHead])
            let pixelX = #id
            let uvX = #id
            #functionBody(opCode: SpirvOpPhi, [intType, pixelX], [pixelMinX, ifDenominatorNonZeroMergeLabel], [xPixelPlusOne, xContinueTarget])
            #functionBody(opCode: SpirvOpPhi, [floatType, uvX], [startUVX, ifDenominatorNonZeroMergeLabel], [xUVNext, xContinueTarget])
            let pixelXRangeCheck = #id
            #functionBody(opCode: SpirvOpSLessThan, [boolType, pixelXRangeCheck, pixelX, pixelMaxX])
            // Assign variables visble to loop body here, including OpPhi instructions
            #functionBody(opCode: SpirvOpLoopMerge, [xLoopMergePoint, xContinueTarget, 0 /* No loop inlining specifier */])
            #functionBody(opCode: SpirvOpBranchConditional, [pixelXRangeCheck, xLoopBody, xLoopMergePoint])
            #functionBody(opCode: SpirvOpLabel, [xLoopBody])
            #functionBody(opCode: SpirvOpBranch, [yLoopHead])
            
                #functionBody(opCode: SpirvOpLabel, [yLoopHead])
                let pixelY = #id
                let uvY = #id
                #functionBody(opCode: SpirvOpPhi, [intType, pixelY], [pixelMinY, xLoopBody], [yPixelPlusOne, yContinueTarget])
                #functionBody(opCode: SpirvOpPhi, [floatType, uvY], [startUVY, xLoopBody], [yUVNext, yContinueTarget])

                let pixelYRangeCheck = #id
                #functionBody(opCode: SpirvOpSLessThan, [boolType, pixelYRangeCheck, pixelY, pixelMaxY])
                #functionBody(opCode: SpirvOpLoopMerge, [yLoopMergePoint, yContinueTarget, 0 /* No loop inlining specifier */])
                #functionBody(opCode: SpirvOpBranchConditional, [pixelYRangeCheck, yLoopBody, yLoopMergePoint])
                #functionBody(opCode: SpirvOpLabel, [yLoopBody])
             
                // START Calculate Barycentric coordinates to interpolate values

                let thisUV = #id
                #functionBody(opCode: SpirvOpCompositeConstruct, [float2Type, thisUV, uvX, uvY])
            
                let deltaThisUVUV1 = #id
                let deltaThisUVUV1X = #id
                let deltaThisUVUV1Y = #id
                let baryU = #id
                let baryV = #id
                let baryW = #id
                // TODO ADD in Z Coordinate from group
                
                #functionBody(opCode: SpirvOpFSub, [float2Type, deltaThisUVUV1, thisUV, uv1])
                #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaThisUVUV1X, deltaThisUVUV1, 0])
                #functionBody(opCode: SpirvOpCompositeExtract, [floatType, deltaThisUVUV1Y, deltaThisUVUV1, 1])
                
                let deltaThisUVUV1XMdeltaUV3UV1Y = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, deltaThisUVUV1XMdeltaUV3UV1Y, deltaThisUVUV1X,  deltaUV3UV1Y])
                let deltaThisUVUV1YMdeltaUV3UV1X = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, deltaThisUVUV1YMdeltaUV3UV1X, deltaThisUVUV1Y,  deltaUV3UV1X])
                
                let deltaThisUVUV1XMdeltaUV3UV1YSdeltaThisUVUV1YMdeltaUV3UV1X = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, deltaThisUVUV1XMdeltaUV3UV1YSdeltaThisUVUV1YMdeltaUV3UV1X, deltaThisUVUV1XMdeltaUV3UV1Y,  deltaThisUVUV1YMdeltaUV3UV1X])
                #functionBody(opCode: SpirvOpFMul, [floatType, baryV, oneOverBaryDenominator,  deltaThisUVUV1XMdeltaUV3UV1YSdeltaThisUVUV1YMdeltaUV3UV1X])
            
                let deltaThisUVUV1YMdeltaUV2UV1X = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, deltaThisUVUV1YMdeltaUV2UV1X, deltaThisUVUV1Y,  deltaUV2UV1X])
                let deltaThisUVUV1XMdeltaUV2UV1Y = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, deltaThisUVUV1XMdeltaUV2UV1Y, deltaThisUVUV1X,  deltaUV2UV1Y])
                
            
                let deltaThisUVUV1YMdeltaUV2UV1XSdeltaThisUVUV1XMdeltaUV2UV1Y = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, deltaThisUVUV1YMdeltaUV2UV1XSdeltaThisUVUV1XMdeltaUV2UV1Y, deltaThisUVUV1YMdeltaUV2UV1X,  deltaThisUVUV1YMdeltaUV2UV1X])
                #functionBody(opCode: SpirvOpFMul, [floatType, baryW, oneOverBaryDenominator,  deltaThisUVUV1YMdeltaUV2UV1XSdeltaThisUVUV1XMdeltaUV2UV1Y])
                
                let oneMinusBaryV = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, oneMinusBaryV, oneFId, baryV])
                #functionBody(opCode: SpirvOpFSub, [floatType, baryU, oneMinusBaryV, baryW])
            
                let baryUIsNegative = #id
                let baryVIsNegative = #id
                let baryWIsNegative = #id
                #functionBody(opCode: SpirvOpFOrdLessThan, [boolType, baryUIsNegative, baryU, zeroF])
                #functionBody(opCode: SpirvOpFOrdLessThan, [boolType, baryVIsNegative, baryV, zeroF])
                #functionBody(opCode: SpirvOpFOrdLessThan, [boolType, baryWIsNegative, baryW, zeroF])
                let baryUOrVIsNegative = #id
                let baryUOrVorWIsNegative = #id
                #functionBody(opCode: SpirvOpLogicalOr, [boolType, baryUOrVIsNegative, baryUIsNegative, baryVIsNegative])
                #functionBody(opCode: SpirvOpLogicalOr, [boolType, baryUOrVorWIsNegative, baryUOrVIsNegative, baryWIsNegative])
                
            
                // END Calculate Barycentric coordinates to interpolate values
                // Test if in triangle
                let ifBaryMergeLabel = #id
                let ifBaryPositiveLabel = #id
                #functionBody(opCode: SpirvOpSelectionMerge, [ifBaryMergeLabel, 0])
                #functionBody(opCode: SpirvOpBranchConditional, [baryUOrVorWIsNegative, ifBaryMergeLabel, ifBaryPositiveLabel])
                #functionBody(opCode: SpirvOpLabel, [ifBaryPositiveLabel])
                
                let texelPointerId = #id
                let texCoordinateId: UInt32 = #id
                #functionBody(opCode: SpirvOpCompositeConstruct, [int2Type, texCoordinateId, pixelX, pixelY])
                let zeroI = #id
                #globalDeclaration(opCode: SpirvOpConstant, [intType, zeroI, 0])
                let texelMemorySemantics = #id
                let texelScope = #id
            
                let texelPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassImage.rawValue, intType])
                #functionBody(opCode: SpirvOpImageTexelPointer, [texelPointerTypeId, texelPointerId, outputTextureId, texCoordinateId, zeroI])
                #globalDeclaration(opCode: SpirvOpConstant, [intType, texelMemorySemantics, SpirvMemorySemanticsAcquireReleaseMask.rawValue | SpirvMemorySemanticsImageMemoryMask.rawValue])
                #globalDeclaration(opCode: SpirvOpConstant, [intType, texelScope, SpirvScopeCrossDevice.rawValue])
                #functionBody(opCode: SpirvOpAtomicSMax, [intType, #id, texelPointerId, texelScope, texelMemorySemantics, triangleIndexId])
                #functionBody(opCode: SpirvOpBranch, [ifBaryMergeLabel])
                #functionBody(opCode: SpirvOpLabel, [ifBaryMergeLabel])
                #functionBody(opCode: SpirvOpBranch, [yContinueTarget])
                #functionBody(opCode: SpirvOpLabel, [yContinueTarget])
                #functionBody(opCode: SpirvOpIAdd, [intType, yPixelPlusOne, pixelY, oneIId])
                #functionBody(opCode: SpirvOpFAdd, [floatType, yUVNext, uvY, uvDeltaY])
                #functionBody(opCode: SpirvOpBranch, [yLoopHead])
                #functionBody(opCode: SpirvOpLabel, [yLoopMergePoint])
                #functionBody(opCode: SpirvOpBranch, [xContinueTarget])
            
            #functionBody(opCode: SpirvOpLabel, [xContinueTarget])
            // Update values here
            #functionBody(opCode: SpirvOpIAdd, [intType, xPixelPlusOne, pixelX, oneIId])
            #functionBody(opCode: SpirvOpFAdd, [floatType, xUVNext, uvX, uvDeltaX])

            #functionBody(opCode: SpirvOpBranch, [xLoopHead])
            #functionBody(opCode: SpirvOpLabel, [xLoopMergePoint])
            #functionBody(opCode: SpirvOpReturn)
            #functionBody(opCode: SpirvOpFunctionEnd)
            SpirvFunction.instance.writeFunction()
            JelloCompilerBlackboard.clear()
        })
        
        for outputPort in nodes.flatMap({$0.outputPorts}) {
            outputPort.clearReservation()
        }
        
        if case .dimension(let x, let y, _) = computationDimension {
            return .computeRasterizer(SpirvComputeRasterizerShader(shader: compute, outputComputeTexture: SpirvTextureBinding(texture: JelloComputeIOTexture(originatingStage: self.id, originatingPass: 0, size: .dimension(x, y, 1), format: .R32i, packing: .int), spirvId: outputTextureId), domain: .modelDependant))
        }
        fatalError("Computation Dimension Required")
    }
    
    
    
    private func buildOutputSpirvShader(input: JelloCompilerInput) throws -> SpirvShader {
        let nodes = input.graph.nodes
        var inputTextures: [SpirvTextureBinding] = []
        var outputTextureBinding: SpirvTextureBinding? = nil


        let compute = #document({
            let entryPoint = #id
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityVariablePointersStorageBuffer.rawValue])
            let glsl450Id = #id
            #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
            JelloCompilerBlackboard.glsl450ExtId = glsl450Id
            
            var dimensions: [UInt32] = [1, 1, 1]
            if case .dimension(_, let y, let z) = computationDimension {
                if y == 1 && z == 1 {
                    dimensions[0] = 128
                } else if z == 1 {
                    dimensions[0] = 16
                    dimensions[1] = 8
                } else {
                    dimensions[0] = 8
                    dimensions[1] = 4
                    dimensions[2] = 4
                }
            }

            #executionMode(opCode: SpirvOpExecutionMode, [entryPoint, SpirvExecutionModeLocalSize.rawValue], dimensions)
            
            #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
            
            JelloCompilerBlackboard.gl_GlobalInvocationID = #id
            let intType = declareType(dataType: .int)
            let int3Type = #typeDeclaration(opCode: SpirvOpTypeVector, [intType, 3])
            let int3PointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, int3Type])
            let floatType = declareType(dataType: .float)
            #globalDeclaration(opCode: SpirvOpVariable, [int3PointerType, JelloCompilerBlackboard.gl_GlobalInvocationID, SpirvStorageClassInput.rawValue])
            #annotation(opCode: SpirvOpDecorate, [JelloCompilerBlackboard.gl_GlobalInvocationID, SpirvDecorationBuiltIn.rawValue, SpirvBuiltInGlobalInvocationId.rawValue])
            
            let outputTexId = #id
            let outputTexTypeId = #typeDeclaration(opCode: SpirvOpTypeImage, [floatType, self.spirvDimensionality.rawValue], [0 /* No depth */, 0 /* Not arrayed */, 0 /* Single sampled */, 2 /* Compatible w/ Read Write */, self.spirvFormat.rawValue])

            #annotation(opCode: SpirvOpDecorate, [outputTexId, SpirvDecorationDescriptorSet.rawValue, computeTextureInputOutputDescriptorSet])
            #annotation(opCode: SpirvOpDecorate, [outputTexId, SpirvDecorationBinding.rawValue, computeTextureOutputBinding])
            #debugNames(opCode: SpirvOpName, [outputTexId], #stringLiteral("outputTex"))

            let outputTexPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniform.rawValue, outputTexTypeId])
            #globalDeclaration(opCode: SpirvOpVariable, [outputTexPointerTypeId, outputTexId, SpirvStorageClassUniform.rawValue])
            JelloCompilerBlackboard.entryPointInterfaceIds.append(outputTexId)
            JelloCompilerBlackboard.outputComputeTexture = SpirvTextureBinding(texture: JelloComputeIOTexture(originatingStage: self.id, originatingPass:  (self.computationDomain?.contains(.modelDependant) ?? false) ? 1 : 0, size: computationDimension, format: format, packing: packing), spirvId: outputTexId)
            
            var triangleIndexInputId: UInt32? = nil
            var triangleIndexTextureTypeId: UInt32? = nil
            var vertexDataTypeId: UInt32? = nil
            var verticesDataBuffer: UInt32? = nil
            var indicesDataBuffer: UInt32? = nil
            if (computationDomain ?? .constant).contains(.modelDependant) {
                // Declare inputs for vertex data
                vertexDataTypeId = VertexData.register()
                var vertexDataOffset: UInt32 = 0
                #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId!, 0, SpirvDecorationOffset.rawValue, vertexDataOffset])
                vertexDataOffset += 16
                #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId!, 1, SpirvDecorationOffset.rawValue, vertexDataOffset])
                vertexDataOffset += 16
                #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId!, 2, SpirvDecorationOffset.rawValue, vertexDataOffset])
                vertexDataOffset += 16
                #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId!, 3, SpirvDecorationOffset.rawValue, vertexDataOffset])
                vertexDataOffset += 16
                #annotation(opCode: SpirvOpMemberDecorate, [vertexDataTypeId!, 4, SpirvDecorationOffset.rawValue, vertexDataOffset])
                vertexDataOffset += 16
                #annotation(opCode: SpirvOpDecorate, [vertexDataTypeId!, SpirvDecorationBlock.rawValue])

                let vertexDataBufferPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, vertexDataTypeId!])
                #annotation(opCode: SpirvOpDecorate, [vertexDataBufferPointerTypeId, SpirvDecorationArrayStride.rawValue, vertexDataOffset])

                verticesDataBuffer = #id
                #globalDeclaration(opCode: SpirvOpVariable, [vertexDataBufferPointerTypeId, verticesDataBuffer!, SpirvStorageClassStorageBuffer.rawValue])
                #debugNames(opCode: SpirvOpName, [verticesDataBuffer!], #stringLiteral("vertices"))
                #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer!, SpirvDecorationDescriptorSet.rawValue, geometryInputDescriptorSet])
                #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer!, SpirvDecorationBinding.rawValue, verticesBinding])
                JelloCompilerBlackboard.entryPointInterfaceIds.append(verticesDataBuffer!)
                #annotation(opCode: SpirvOpDecorate, [verticesDataBuffer!, SpirvDecorationNonWritable.rawValue])

                let indicesDataBufferTypeId = #typeDeclaration(opCode: SpirvOpTypeStruct, [intType])
                #debugNames(opCode: SpirvOpMemberName, [indicesDataBufferTypeId, 0], #stringLiteral("index"))
                #annotation(opCode: SpirvOpDecorate, [indicesDataBufferTypeId, SpirvDecorationBlock.rawValue])
                #annotation(opCode: SpirvOpMemberDecorate, [indicesDataBufferTypeId, 0, SpirvDecorationOffset.rawValue, 0])
                let indicesDataBufferPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, indicesDataBufferTypeId])
                #annotation(opCode: SpirvOpDecorate, [indicesDataBufferPointerTypeId, SpirvDecorationArrayStride.rawValue, 4])


                indicesDataBuffer = #id
                #debugNames(opCode: SpirvOpName, [indicesDataBuffer!], #stringLiteral("indices"))
                #globalDeclaration(opCode: SpirvOpVariable, [indicesDataBufferPointerTypeId, indicesDataBuffer!, SpirvStorageClassStorageBuffer.rawValue])
                #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer!, SpirvDecorationDescriptorSet.rawValue, geometryInputDescriptorSet])
                #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer!, SpirvDecorationBinding.rawValue, indicesBinding])
                JelloCompilerBlackboard.entryPointInterfaceIds.append(indicesDataBuffer!)
                #annotation(opCode: SpirvOpDecorate, [indicesDataBuffer!, SpirvDecorationNonWritable.rawValue])


                // Declare input for triangle IDs
                triangleIndexTextureTypeId = #typeDeclaration(opCode: SpirvOpTypeImage, [intType, (self.spirvDimensionality == SpirvDim1D ? SpirvDim1D : SpirvDim2D).rawValue], [0 /* No depth */, 0 /* Not arrayed */, 0 /* Single sampled */, 2 /* Compatible w/ Read Write */, SpirvImageFormatR32i.rawValue])
                triangleIndexInputId = #id
                if case .dimension(let x, let y, _) = computationDimension {
                    JelloCompilerBlackboard.inputComputeTextures.append(.init(texture: JelloComputeIOTexture(originatingStage: self.id, originatingPass: 0, size: .dimension(Int(x), Int(y), 1), format: .R32i, packing: .int), spirvId: triangleIndexInputId!))
                }

                #annotation(opCode: SpirvOpDecorate, [triangleIndexInputId!, SpirvDecorationDescriptorSet.rawValue, geometryInputDescriptorSet])
                #annotation(opCode: SpirvOpDecorate, [triangleIndexInputId!, SpirvDecorationBinding.rawValue, triangleIndexBinding])

                JelloCompilerBlackboard.entryPointInterfaceIds.append(triangleIndexInputId!)
                let triangleIndexTexPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, triangleIndexTextureTypeId!])
                #globalDeclaration(opCode: SpirvOpVariable, [triangleIndexTexPointerTypeId, triangleIndexInputId!, SpirvStorageClassUniformConstant.rawValue])
            }
            
            for node in nodes {
                node.install(input: input)
            }
            
            inputTextures = JelloCompilerBlackboard.inputComputeTextures
            outputTextureBinding = JelloCompilerBlackboard.outputComputeTexture
            let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
             
            #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelGLCompute.rawValue], [entryPoint], #stringLiteral("computeMain"), JelloCompilerBlackboard.entryPointInterfaceIds, [JelloCompilerBlackboard.gl_GlobalInvocationID])
            let typeComputeFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
            #debugNames(opCode: SpirvOpName, [typeComputeFunction], #stringLiteral("computeMain"))
            #functionHead(opCode: SpirvOpFunction, [typeVoid, entryPoint, 0, typeComputeFunction])
            #functionHead(opCode: SpirvOpLabel, [#id])
            
            let globalInvocationLoadId = #id
            #functionBody(opCode: SpirvOpLoad, [int3Type, globalInvocationLoadId, JelloCompilerBlackboard.gl_GlobalInvocationID])
            
            if (computationDomain ?? .constant).contains(.modelDependant) {
                let triangleIndexCoordId = #id
                let triangleIndexTexLoadId = #id
                let int2Type = #typeDeclaration(opCode: SpirvOpTypeVector, [intType, 2])
                switch spirvDimensionality {
                case SpirvDim1D:
                    #functionBody(opCode: SpirvOpVectorShuffle, [int2Type, triangleIndexCoordId, globalInvocationLoadId, globalInvocationLoadId, 0, 0xFFFFFFFF])
                case SpirvDim2D, SpirvDim3D:
                    #functionBody(opCode: SpirvOpVectorShuffle, [int2Type, triangleIndexCoordId, globalInvocationLoadId, globalInvocationLoadId, 0, 1])
                default:
                    fatalError("Unexpected Dimensionality")
                }
                
                #functionBody(opCode: SpirvOpLoad, [triangleIndexTextureTypeId!, triangleIndexTexLoadId, triangleIndexInputId!])
                let triangleIndex = #id
                #functionBody(opCode: SpirvOpImageRead, [intType, triangleIndex, triangleIndexTexLoadId, triangleIndexCoordId])
                let threeInt = #id
                let oneInt = #id
                let indicesIndex1 = #id
                let indicesIndex2 = #id
                let indicesIndex3 = #id
                let indicesIndexAccessChain1 = #id
                let indicesIndexAccessChain2 = #id
                let indicesIndexAccessChain3 = #id
                let index1 = #id
                let index2 = #id
                let index3 = #id
                let vertexAccessChain1 = #id
                let vertexAccessChain2 = #id
                let vertexAccessChain3 = #id
                let vertex1 = #id
                let vertex2 = #id
                let vertex3 = #id
                let uv1 = #id
                let uv2 = #id
                let uv3 = #id
                #globalDeclaration(opCode: SpirvOpConstant, [intType, threeInt, 3])
                #globalDeclaration(opCode: SpirvOpConstant, [intType, oneInt, 1])
                #functionBody(opCode: SpirvOpIMul, [intType, indicesIndex1, triangleIndex, threeInt])
                #functionBody(opCode: SpirvOpIAdd, [intType, indicesIndex2, indicesIndex1, oneInt])
                #functionBody(opCode: SpirvOpIAdd, [intType, indicesIndex3, indicesIndex2, oneInt])
                let zeroInt = #id
                #globalDeclaration(opCode: SpirvOpConstant, [intType, zeroInt, 0])
                let intStorageBufferPointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, intType])
                #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain1, indicesDataBuffer!, indicesIndex1, zeroInt])
                #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain2, indicesDataBuffer!, indicesIndex2, zeroInt])
                #functionBody(opCode: SpirvOpPtrAccessChain, [intStorageBufferPointerType, indicesIndexAccessChain3, indicesDataBuffer!, indicesIndex3, zeroInt])
                #functionBody(opCode: SpirvOpLoad, [intType, index1, indicesIndexAccessChain1])
                #functionBody(opCode: SpirvOpLoad, [intType, index2, indicesIndexAccessChain2])
                #functionBody(opCode: SpirvOpLoad, [intType, index3, indicesIndexAccessChain3])
                
                let vertexStorageBufferPointerType = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassStorageBuffer.rawValue, vertexDataTypeId!])
                #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain1, verticesDataBuffer!, index1])
                #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain2, verticesDataBuffer!, index2])
                #functionBody(opCode: SpirvOpPtrAccessChain, [vertexStorageBufferPointerType, vertexAccessChain3, verticesDataBuffer!, index3])
                #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId!, vertex1, vertexAccessChain1])
                #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId!, vertex2, vertexAccessChain2])
                #functionBody(opCode: SpirvOpLoad, [vertexDataTypeId!, vertex3, vertexAccessChain3])
                
                let float2Type = declareType(dataType: .float2)
                #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv1, vertex1, 1])
                #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv2, vertex2, 1])
                #functionBody(opCode: SpirvOpCompositeExtract, [float2Type, uv3, vertex3, 1])
                
                let thisUV = #id
                let zeroFloat = declareNullValueConstant(dataType: .float)
                let oneFloat = #id
                #globalDeclaration(opCode: SpirvOpConstant, [floatType, oneFloat], float(1))
                let float4Type = declareType(dataType: .float4)
                if case .dimension(let x, let y, let z) = computationDimension {
                    switch spirvDimensionality {
                    case SpirvDim1D:
                        let triangleIndexCoordIdFloat2 = #id
                        #functionBody(opCode: SpirvOpConvertSToF, [float2Type, triangleIndexCoordIdFloat2, triangleIndexCoordId])
                        let triangleIndexCoordIdFloat4 = #id
                        #functionBody(opCode: SpirvOpCompositeConstruct, [float4Type, triangleIndexCoordIdFloat4, triangleIndexCoordIdFloat2, zeroFloat, zeroFloat])
                        let dimX = #id
                        let dim = #id
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimX], float(Float(x)))
                        #globalDeclaration(opCode: SpirvOpConstantComposite, [float4Type, dim, dimX, oneFloat, oneFloat, oneFloat])
                        #functionBody(opCode: SpirvOpFDiv, [float4Type, thisUV, triangleIndexCoordIdFloat4, dim])
                    case SpirvDim2D:
                        let triangleIndexCoordIdFloat2 = #id
                        #functionBody(opCode: SpirvOpConvertSToF, [float2Type, triangleIndexCoordIdFloat2, triangleIndexCoordId])
                        let triangleIndexCoordIdFloat4 = #id
                        #functionBody(opCode: SpirvOpCompositeConstruct, [float4Type, triangleIndexCoordIdFloat4, triangleIndexCoordIdFloat2, zeroFloat, zeroFloat])
                        let dimX = #id
                        let dimY = #id
                        let dim = #id
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimX], float(Float(x)))
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimY], float(Float(y)))
                        #globalDeclaration(opCode: SpirvOpConstantComposite, [float4Type, dim, dimX, dimY, oneFloat, oneFloat])
                        #functionBody(opCode: SpirvOpFDiv, [float4Type, thisUV, triangleIndexCoordIdFloat4, dim])
                    case SpirvDim3D:
                        let triangleIndexCoordIdFloat2 = #id
                        #functionBody(opCode: SpirvOpConvertSToF, [float2Type, triangleIndexCoordIdFloat2, triangleIndexCoordId])
                        let triangleIndexCoordIdFloat4 = #id
                        #functionBody(opCode: SpirvOpCompositeConstruct, [float4Type, triangleIndexCoordIdFloat4, triangleIndexCoordIdFloat2, zeroFloat])
                        let dimX = #id
                        let dimY = #id
                        let dimZ = #id
                        let dim = #id
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimX], float(Float(x)))
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimY], float(Float(y)))
                        #globalDeclaration(opCode: SpirvOpConstant, [floatType, dimZ], float(Float(z)))
                        #globalDeclaration(opCode: SpirvOpConstantComposite, [float4Type, dim, dimX, dimY, dimZ, oneFloat])
                        #functionBody(opCode: SpirvOpFDiv, [float4Type, thisUV, triangleIndexCoordIdFloat4, dim])
                    default:
                        fatalError("Unexpected Dimensionality")
                    }
                }
                JelloCompilerBlackboard.texCoordId = thisUV
                let v0 = #id
                let v1 = #id
                let v2 = #id
                let thisUVFloat2 = #id
                #functionBody(opCode: SpirvOpVectorShuffle, [float2Type, thisUVFloat2, thisUV, thisUV, 0, 1])
                #functionBody(opCode: SpirvOpFSub, [float2Type, v0, uv2, uv1])
                #functionBody(opCode: SpirvOpFSub, [float2Type, v1, uv3, uv1])
                #functionBody(opCode: SpirvOpFSub, [float2Type, v2, thisUVFloat2, uv1])
                let d00 = #id
                let d01 = #id
                let d11 = #id
                let d20 = #id
                let d21 = #id
                #functionBody(opCode: SpirvOpDot, [floatType, d00, v0, v0])
                #functionBody(opCode: SpirvOpDot, [floatType, d01, v0, v1])
                #functionBody(opCode: SpirvOpDot, [floatType, d11, v1, v1])
                #functionBody(opCode: SpirvOpDot, [floatType, d20, v2, v0])
                #functionBody(opCode: SpirvOpDot, [floatType, d21, v2, v1])
                
                let d00_m_d11 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d00_m_d11, d00, d11])
                let d01_m_d01 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d01_m_d01, d01, d01])
                let denom = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, denom, d00_m_d11, d01_m_d01])
                let invDenom = #id
                #functionBody(opCode: SpirvOpFDiv, [floatType, invDenom, oneFloat, denom])
                
                let d11_m_d20 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d11_m_d20, d11, d20])
                let d01_m_d21 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d01_m_d21, d01, d21])
                
                let d00_m_d21 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d00_m_d21, d00, d21])
                let d01_m_d20 = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, d01_m_d20, d01, d20])
                let vWithoutDenom = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, vWithoutDenom, d11_m_d20, d01_m_d21])
                let v = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, v, vWithoutDenom, invDenom])
                
                let wWithoutDenom = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, wWithoutDenom, d00_m_d21, d01_m_d20])
                let w = #id
                #functionBody(opCode: SpirvOpFMul, [floatType, w, wWithoutDenom, invDenom])
                
                let oneMinusV = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, oneMinusV, oneFloat, v])
                let u = #id
                #functionBody(opCode: SpirvOpFSub, [floatType, u, oneMinusV, w])
                
                let float3TypeId = declareType(dataType: .float3)
                if JelloCompilerBlackboard.requireWorldPos {
                    fatalError("We're not taking in model view matrix yet")
                }
                if JelloCompilerBlackboard.requireNormal {
                    JelloCompilerBlackboard.normalId = interpolateBarycentric(typeId: float3TypeId, index: 2, vertex1: vertex1, vertex2: vertex2, vertex3: vertex3, u: u, v: v, w: w)
                }
                if JelloCompilerBlackboard.requireTangent {
                    JelloCompilerBlackboard.tangentId = interpolateBarycentric(typeId: float3TypeId, index: 3, vertex1: vertex1, vertex2: vertex2, vertex3: vertex3, u: u, v: v, w: w)
                }
                if JelloCompilerBlackboard.requireBitangent {
                    JelloCompilerBlackboard.bitangentId = interpolateBarycentric(typeId: float3TypeId, index: 4, vertex1: vertex1, vertex2: vertex2, vertex3: vertex3, u: u, v: v, w: w)
                }
                if JelloCompilerBlackboard.requireModelPos {
                    JelloCompilerBlackboard.modelPosId = interpolateBarycentric(typeId: float3TypeId, index: 0, vertex1: vertex1, vertex2: vertex2, vertex3: vertex3, u: u, v: v, w: w, normalize: false)
                }
            }

            for node in input.graph.nodes {
                node.write(input: input)
            }
            if let inputPort = inputPorts.first, let inputEdge = inputPort.incomingEdge {
                let otherOutputPort = inputEdge.outputPort
                let inputId = otherOutputPort.getOrReserveId()
                let outputTexLoadId = #id
                #functionBody(opCode: SpirvOpLoad, [outputTexTypeId, outputTexLoadId, outputTexId])
                let intType = declareType(dataType: .int)
                var coordExtractedId: UInt32 = 0
                switch spirvDimensionality {
                case SpirvDim1D:
                    coordExtractedId = #id
                    #functionBody(opCode: SpirvOpCompositeExtract, [intType, coordExtractedId, globalInvocationLoadId, 0])
                case SpirvDim2D:
                    coordExtractedId = #id
                    let int2Type = #typeDeclaration(opCode: SpirvOpTypeVector, [intType, 2])
                    #functionBody(opCode: SpirvOpVectorShuffle, [int2Type, coordExtractedId, globalInvocationLoadId, globalInvocationLoadId, 0, 1])
                case SpirvDim3D:
                    coordExtractedId = globalInvocationLoadId
                default:
                    fatalError("Unexpected Dimensionality")
                }
                var writeValueId: UInt32 = 0
                let float4TypeId = declareType(dataType: .float4)
                switch packing {
                case .int:
                    fatalError("Unsupported Type")
                case .float:
                    writeValueId = inputId
                case .float2:
                    writeValueId = #id
                    #functionBody(opCode: SpirvOpVectorShuffle, [float4TypeId, writeValueId, inputId, inputId, 0, 1, 0xFFFFFFFF, 0xFFFFFFFF])
                case .float3:
                    writeValueId = #id
                    #functionBody(opCode: SpirvOpVectorShuffle, [float4TypeId, writeValueId, inputId, inputId, 0, 1, 2, 0xFFFFFFFF])
                case .float4:
                    writeValueId = inputId
                }
                #functionBody(opCode: SpirvOpImageWrite, [outputTexLoadId, coordExtractedId, writeValueId, 0])
            }
            #functionBody(opCode: SpirvOpReturn)
            #functionBody(opCode: SpirvOpFunctionEnd)
            SpirvFunction.instance.writeFunction()
            JelloCompilerBlackboard.clear()
        })
        
        for outputPort in nodes.flatMap({$0.outputPorts}) {
            outputPort.clearReservation()
        }
        let computeShader = SpirvComputeShader(shader: compute, outputComputeTexture: outputTextureBinding!, inputComputeTextures: inputTextures, domain: computationDomain ?? .constant)
        return SpirvShader.compute(computeShader)
    }

    private func interpolateBarycentric(typeId: UInt32, index: UInt32, vertex1: UInt32, vertex2: UInt32, vertex3: UInt32, u: UInt32, v: UInt32, w: UInt32, normalize: Bool = true) -> UInt32 {
        let v1 = #id
        let v2 = #id
        let v3 = #id
        #functionBody(opCode: SpirvOpCompositeExtract, [typeId, v1, vertex1, index])
        #functionBody(opCode: SpirvOpCompositeExtract, [typeId, v2, vertex2, index])
        #functionBody(opCode: SpirvOpCompositeExtract, [typeId, v3, vertex3, index])
        let w1 = #id
        let w2 = #id
        let w3 = #id
        let sumW1W2 = #id
        let sumW = #id
        #functionBody(opCode: SpirvOpVectorTimesScalar, [typeId, w1, v1, u])
        #functionBody(opCode: SpirvOpVectorTimesScalar, [typeId, w2, v2, v])
        #functionBody(opCode: SpirvOpVectorTimesScalar, [typeId, w3, v3, w])
        #functionBody(opCode: SpirvOpFAdd, [typeId, sumW1W2, w1, w2])
        #functionBody(opCode: SpirvOpFAdd, [typeId, sumW, sumW1W2, w3])
        if normalize {
            let result = #id
            #functionBody(opCode: SpirvOpExtInst, [typeId, result, JelloCompilerBlackboard.glsl450ExtId, GLSLstd450Normalize.rawValue, sumW])
            return result
        }
        return w3
    }
    
    var spirvDimensionality: SpirvDim {
        switch outputPorts.first!.concreteDataType?.dimensionality ?? .d1 {
        case .d1: SpirvDim1D
        case .d2: SpirvDim2D
        case .d3: SpirvDim3D
        case .d4: fatalError("Unsupported Dimensionality")
        }
    }
    
    var format: JelloComputeIOTexture.TextureFormat {
        switch inputPorts.first!.concreteDataType {
        case .int: JelloComputeIOTexture.TextureFormat.R32f

        case .float: JelloComputeIOTexture.TextureFormat.R32f
        case .float2: JelloComputeIOTexture.TextureFormat.Rgba32f
        case .float3: JelloComputeIOTexture.TextureFormat.Rgba32f
        case .float4: JelloComputeIOTexture.TextureFormat.Rgba32f
        default: fatalError("Unsupported Data Type")
        }
    }
    
    var spirvFormat: SpirvImageFormat {
        switch inputPorts.first!.concreteDataType {
        case .float: SpirvImageFormatR32f
        case .float2: SpirvImageFormatRgba32f
        case .float3: SpirvImageFormatRgba32f
        case .float4: SpirvImageFormatRgba32f
        default: fatalError("Unsupported Data Type")
        }
    }
    
    var packing: JelloComputeIOTexture.TexturePacking {
        switch inputPorts.first!.concreteDataType {
        case .float: .float
        case .float2: .float2
        case .float3: .float3
        case .float4: .float4
        default: fatalError("Unsupported Data Type")
        }
    }

    
    public func install(input: JelloCompilerInput) {
        let index = JelloCompilerBlackboard.inputComputeTextures.count
        let floatType = declareType(dataType: .float)
        let imageType = #typeDeclaration(opCode: SpirvOpTypeImage, [floatType, spirvDimensionality.rawValue], [0 /* No depth */, 0 /* Not arrayed */, 0 /* single sampled */, 1 /* Sampled */, spirvFormat.rawValue])
        sampledImageTypeId = #typeDeclaration(opCode: SpirvOpTypeSampledImage, [imageType])
        inputTexId = #id
        #annotation(opCode: SpirvOpDecorate, [inputTexId, SpirvDecorationDescriptorSet.rawValue, computeTextureInputOutputDescriptorSet])
        #annotation(opCode: SpirvOpDecorate, [inputTexId, SpirvDecorationBinding.rawValue, UInt32(index)+1])
        #annotation(opCode: SpirvOpDecorate, [inputTexId, SpirvDecorationNonWritable.rawValue])

        let imagePointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, sampledImageTypeId])
        #globalDeclaration(opCode: SpirvOpVariable, [imagePointerTypeId, inputTexId, SpirvStorageClassUniformConstant.rawValue])
        JelloCompilerBlackboard.inputComputeTextures.append(.init(texture: JelloComputeIOTexture(originatingStage: self.id, originatingPass: (self.computationDomain ?? .constant).contains(.modelDependant) ? 1: 0, size: self.computationDimension, format: format, packing: packing), spirvId: inputTexId))
        JelloCompilerBlackboard.entryPointInterfaceIds.append(inputTexId)
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
    public var subgraphTags: Set<UUID> = []
    public var computationDomain: CompilerComputationDomain?
    public var subgraph: JelloCompilerInput? = nil

    public func buildShader(input: JelloCompilerInput) throws -> JelloCompilerOutputStage {
        try compileSpirvFragmentShader(input: input, outputBody: {})
    }

    public var constraints: [PortConstraint] { [] }
    public init(id: UUID, inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.node = self
            p.newBranchId = self.id
            p.newSubgraphId = self.id
        }
    }
}
