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
    
    public func install() {
    }
    
    public func write() {
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
                node.write()
            }
            ifTrue = truePort.incomingEdge!.outputPort.getOrReserveId()
        }
        #functionBody(opCode: SpirvOpBranch, [endLabel])
        #functionBody(opCode: SpirvOpLabel, [falseLabel])
        if let falseBranch = subNodes[falseBranchTag] {
            for node in falseBranch {
                node.write()
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
    public func install() {
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
    
    public func write() {

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


public class PreviewOutputCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install() {}
    public func write() {
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
            case .texture1d:
                fatalError("Texture Preview Not Currently Supported")
            case .texture2d:
                fatalError("Texture Preview Not Currently Supported")
            case .texture3d:
                fatalError("Texture Preview Not Currently Supported")
            }
        } else {
            resultId = #id
            #globalDeclaration(opCode: SpirvOpConstantNull, [float4TypeId, resultId])
        }
        #functionBody(opCode: SpirvOpStore, [outputVariableId, resultId])
    }
    
    public var branchTags: Set<UUID>
    public var constraints: [PortConstraint] {[]}
    public init(id: UUID = UUID(), inputPort: InputCompilerPort) {
        self.id = id
        self.inputPorts = [inputPort]
        self.branchTags = Set([self.id])
        for p in inputPorts {
            p.newBranchId = self.id
        }
        inputPort.node = self
    }
}


public class AddCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install() {}
    
    public func write() {
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
    public func install() {}
    
    public func write() {
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
    public func install() {}
    
    public func write() {
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
    public func install() {}
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
    
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort]
    
    public func install() {
    }
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
    
    public func install() {
    }
    
    public func write() {
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
        }
    }
    
    private func processUnaryOperator(op: MathExpressionUnaryOperator, subExpr: MathExpression) -> UInt32 {
        let subExprResultId = processMathExpression(expression: subExpr)
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
            break
        }
        return resultId
    }
    
    
    private func processBinaryOperator(op: MathExpressionBinaryOperator, subExpr1: MathExpression, subExpr2: MathExpression) -> UInt32 {
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
