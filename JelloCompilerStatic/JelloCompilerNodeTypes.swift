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
        #iff(condId) {
            if let trueBranch = subNodes[trueBranchTag] {
                for node in trueBranch {
                    node.writeFragment()
                }
                ifTrue = truePort.incomingEdge!.outputPort.getOrReserveId()
            }
        } els: {
            if let falseBranch = subNodes[falseBranchTag] {
                for node in falseBranch {
                    node.writeFragment()
                }
                ifFalse = falsePort.incomingEdge!.outputPort.getOrReserveId()
            }
        }
        let outputPort = outputPorts.first!
        let outputId = outputPort.getOrReserveId()
        #functionBody(opCode: SpirvOpPhi, [inputOutputTypeId, outputId, ifTrue, ifFalse])
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
    
    public init(id: UUID, outputPort: OutputCompilerPort, value: JelloConstantValue) {
        self.id = id
        self.inputPorts =  []
        self.outputPorts = [outputPort]
        self.value = value
    }
}
