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
    
    public func writeFragment() {
        let condPort = inputPorts.first!
        let truePort = inputPorts[1]
        let falsePort = inputPorts[2]
        
        let maybeCondResultId = condPort.incomingEdge?.outputPort.getOrReserveId()
        var condId: UInt32 = maybeCondResultId ?? 0
        if maybeCondResultId == nil {
            let typeBool = #typeDeclaration(opCode: SpirvOpTypeBool)
            condId = #typeDeclaration(opCode: SpirvOpConstantFalse, [typeBool])
        }
        
        let inputOutputTypeId = declareType(dataType: truePort.concreteDataType!)
        var defaultZeroValueConstantId: UInt32 = 0
        if truePort.incomingEdge == nil || falsePort.incomingEdge == nil {
            defaultZeroValueConstantId = #typeDeclaration(opCode: SpirvOpConstantNull, [inputOutputTypeId])
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
                node.writeFragment()
            }
            ifTrue = truePort.incomingEdge!.outputPort.getOrReserveId()
        }
        #functionBody(opCode: SpirvOpBranch, [endLabel])
        #functionBody(opCode: SpirvOpLabel, [falseLabel])
        if let falseBranch = subNodes[falseBranchTag] {
            for node in falseBranch {
                node.writeFragment()
            }
            ifFalse = falsePort.incomingEdge!.outputPort.getOrReserveId()
        }
        #functionBody(opCode: SpirvOpBranch, [endLabel])
        #functionBody(opCode: SpirvOpLabel, [endLabel])
        let outputPort = outputPorts.first!
        let outputId = outputPort.getOrReserveId()
        #functionBody(opCode: SpirvOpPhi, [inputOutputTypeId, outputId, ifTrue, trueLabel, ifFalse, falseLabel])
        
    }
    
    public func writeVertex(){}
    
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
            let f2Type = declareType(dataType: .float3)
            let c1Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c1Id], float(f3.x))
            let c2Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c2Id], float(f3.y))
            let c3Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c3Id], float(f3.z))
            #globalDeclaration(opCode: SpirvOpConstantComposite, [f2Type, constantId, c1Id, c2Id, c3Id])
            break
        case .float4(let f4):
            let floatType = declareType(dataType: .float)
            let f2Type = declareType(dataType: .float4)
            let c1Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c1Id], float(f4.x))
            let c2Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c2Id], float(f4.y))
            let c3Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c3Id], float(f4.z))
            let c4Id = #id
            #globalDeclaration(opCode: SpirvOpConstant, [floatType, c4Id], float(f4.w))
            #globalDeclaration(opCode: SpirvOpConstantComposite, [f2Type, constantId, c1Id, c2Id, c3Id, c4Id])
            break
        }
    }
    
    public func writeFragment() {

    }
    
    public func writeVertex(){}
    
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
    }
}



public class PreviewOutputCompilerNode: CompilerNode {
    public var id: UUID
    public var inputPorts: [InputCompilerPort]
    public var outputPorts: [OutputCompilerPort] = []
    public func install() {}
    public func writeFragment() {
        let inputPort = inputPorts.first!
        let floatTypeId = #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
        let float4TypeId = declareType(dataType: .float4)
        let float4PointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassOutput.rawValue, float4TypeId])
        let outputVariableId = JelloCompilerBlackboard.fragOutputColorId
        #debugNames(opCode: SpirvOpName, [outputVariableId], #stringLiteral("frag_out"))
        #annotation(opCode: SpirvOpDecorate, [outputVariableId, SpirvDecorationLocation.rawValue, 0])
        #globalDeclaration(opCode: SpirvOpVariable, [float4PointerTypeId, outputVariableId, SpirvStorageClassOutput.rawValue])
        var resultId: UInt32 = 0
        if let edge = inputPort.incomingEdge {
            switch(inputPort.concreteDataType!) {
            case .bool:
                resultId = #id
                let zeroVector = #typeDeclaration(opCode: SpirvOpConstantNull, [float4TypeId])
                let oneFloat = #typeDeclaration(opCode: SpirvOpConstant, [floatTypeId], float(1))
                let oneVector = #typeDeclaration(opCode: SpirvOpConstantComposite, [float4TypeId, oneFloat, oneFloat, oneFloat, oneFloat])
                #iff(edge.outputPort.getOrReserveId()) {
                }
                #functionBody(opCode: SpirvOpPhi, [float4TypeId, resultId, oneVector, zeroVector])
                break
            case .float:
                resultId = #id
                let outId = edge.outputPort.getOrReserveId()
                #functionBody(opCode: SpirvOpVectorShuffle, [float4TypeId, resultId, outId, outId, 0, 0, 0, 0])
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
            resultId = #typeDeclaration(opCode: SpirvOpConstantNull, [float4TypeId])
        }
        #functionBody(opCode: SpirvOpStore, [outputVariableId, resultId])
    }
    
    public func writeVertex(){
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
