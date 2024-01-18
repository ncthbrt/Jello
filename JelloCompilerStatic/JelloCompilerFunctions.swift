//
//  JelloFunctions.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/21.
//

import Foundation
import Collections
import Algorithms
import SpirvMacros
import SPIRV_Headers_Swift
import SpirvMacrosShared

public func labelBranches(input: JelloCompilerInput){
    let startNode = input.output.node
    var queue = Deque(startNode.inputPorts.filter({$0.incomingEdge != nil}).map({(branchId: $0.newBranchId!, port: $0)}))
    while !queue.isEmpty {
        let (branchId: branchId, port: port) = queue.popFirst()!
        var node = port.incomingEdge!.outputPort.node!
        node.branchTags.insert(branchId)
        for port in node.inputPorts {
            if port.incomingEdge != nil {
                let newBranchId = port.newBranchId ?? branchId
                queue.append((branchId: newBranchId, port: port))
            }
        }
    }
}

public func pruneGraph(input: JelloCompilerInput){
    let graph = input.graph
    graph.nodes = graph.nodes.filter({!$0.branchTags.isEmpty})
}


func getInputEdgeCount(node: CompilerNode) -> UInt {
    UInt(node.inputPorts.filter({$0.incomingEdge != nil}).count)
}

public func topologicallyOrderGraph(input: JelloCompilerInput){
    var visitedNodes: Set<UUID> = []
    func hasNoDependencies(node: CompilerNode) -> Bool {
        return node.inputPorts.filter({ port in
            if let incomingEdge = port.incomingEdge {
                return !visitedNodes.contains(incomingEdge.outputPort.node!.id)
            }
            return false
        }).isEmpty
    }

    var results: [CompilerNode] = input.graph.nodes.filter({hasNoDependencies(node: $0)})
    var i = 0
    while i < results.count {
        let item = results[i]
        visitedNodes.insert(item.id)
        for successorNode in item.outputPorts.flatMap({$0.outgoingEdges}).map({$0.inputPort.node!}) {
            if hasNoDependencies(node: successorNode){
                results.append(successorNode)
            }
        }
        i += 1
    }
    input.graph.nodes = results
}



enum CouldNotConcretiseTypesError: Error {
    case couldNotConcretiseTypesError
}

func propagateConstraintsFromCurrentPort(port start: UUID, assignments: inout [UUID: JelloConcreteDataType], domains: [UUID: [JelloConcreteDataType]], constraints: [UUID:[PortConstraint]]) -> Bool {
    var queue = Deque<UUID>([start])
    var type: JelloConcreteDataType = assignments[start]!
    while !queue.isEmpty {
        let currentPort = queue.popFirst()!
        let constraintsForCurrentPort = constraints[currentPort] ?? []
        type = assignments[currentPort]!
        for constraint in constraintsForCurrentPort {
            switch constraint.apply(assignments: &assignments, domains: domains, port: currentPort, type: type) {
            case .contradiction:
                return false
            case .dirty(let dirtyPorts):
                queue.append(contentsOf: dirtyPorts)
                break
            case .unchanged:
                break
            }
        }
    }
    return true
}

func concretiseTypesInGraphImpl(remainingPorts: ArraySlice<UUID>, domains: [UUID: [JelloConcreteDataType]], assignments: [UUID: JelloConcreteDataType], constraints: [UUID:[PortConstraint]]) -> [UUID: JelloConcreteDataType]? {
    if remainingPorts.count == 0 {
        return assignments
    }
        
    let currentPort = remainingPorts.first!
    guard let domain = domains[currentPort] else {
        return nil
    }
    
    if assignments[currentPort] != nil {
        let nextRemainingPorts = remainingPorts.dropFirst()
        var nextAssignments = assignments
        if !propagateConstraintsFromCurrentPort(port: currentPort, assignments: &nextAssignments, domains: domains, constraints: constraints) {
            return nil
        }
        if let result = concretiseTypesInGraphImpl(remainingPorts: nextRemainingPorts, domains: domains, assignments: assignments, constraints: constraints) {
            return result
        }
        return nil
    }
    
    for value in domain {
        var nextAssignments = assignments
        nextAssignments[currentPort] = value
        if !propagateConstraintsFromCurrentPort(port: currentPort, assignments: &nextAssignments, domains: domains, constraints: constraints) {
            continue
        }
        let nextRemainingPorts = remainingPorts.dropFirst()
        if let result = concretiseTypesInGraphImpl(remainingPorts: nextRemainingPorts, domains: domains, assignments: nextAssignments, constraints: constraints) {
            return result
        }
    }
    
    return nil
}

public func concretiseTypesInGraph(input: JelloCompilerInput) throws {
    let inputPorts = input.graph.nodes.flatMap({$0.inputPorts})
    let outputPorts = input.graph.nodes.flatMap({$0.outputPorts})
    
    var domains : [UUID: [JelloConcreteDataType]] = [:]
    for port in inputPorts {
        domains[port.id] = getDomain(input: port.dataType)
    }
    for port in outputPorts {
        domains[port.id] = getDomain(input: port.dataType)
    }

    // Create a topologically ordered set of ports
    var ports: [UUID] = []
    for node in input.graph.nodes {
        ports.append(contentsOf: node.inputPorts.map({$0.id}))
        ports.append(contentsOf: node.outputPorts.map({$0.id}))
    }
    
    var assignments: [UUID: JelloConcreteDataType] = [:]
    
  
    // Set up constraints
    var constraints: [PortConstraint] = []
    
    // Edge constraints
    
    let edges = inputPorts.filter({$0.incomingEdge != nil}).map({$0.incomingEdge!})
    for edge in edges {
        constraints.append(SameTypesConstraint(ports: [edge.inputPort.id, edge.outputPort.id]))
    }
    
    // Node constraints
    for node in input.graph.nodes {
        constraints.append(contentsOf: node.constraints)
    }
    
    // Create a lookup so that we can conveniently find the set of constraints for a given node
    var constraintsMapped: [UUID: [PortConstraint]] = [:]
    for constraint in constraints {
        for constraintPort in constraint.ports {
            var constrainForPort = constraintsMapped[constraintPort] ?? []
            constrainForPort.append(constraint)
            constraintsMapped[constraintPort] = constrainForPort
        }
    }
    
    // Optimization. Assign types that only have one value in the domain first
    for port in ports {
        if let d = domains[port], d.count == 1, let type = d.first {
            assignments[port] = type
            if !propagateConstraintsFromCurrentPort(port: port, assignments: &assignments, domains: domains, constraints: constraintsMapped) {
                throw CouldNotConcretiseTypesError.couldNotConcretiseTypesError // We cannot unify this graph, as these constraints *have* to hold
            }
        }
    }
    
    
    guard let result: [UUID: JelloConcreteDataType] = concretiseTypesInGraphImpl(remainingPorts: ArraySlice(ports), domains: domains, assignments: assignments, constraints: constraintsMapped) else {
        throw CouldNotConcretiseTypesError.couldNotConcretiseTypesError
    }
    
    for port in inputPorts {
        port.concreteDataType = result[port.id]
    }
    for port in outputPorts {
        port.concreteDataType = result[port.id]
    }
}



public func decomposeGraph(input: JelloCompilerInput) {
    for node in input.graph.nodes.filter({$0 is BranchCompilerNode}) {
        var branchNode = node as! BranchCompilerNode
        for branch in branchNode.branches {
            let start = input.graph.nodes.stablePartition(by:({$0.branchTags.count == 1 && $0.branchTags.contains(branch)}))
            var branchNodes: [CompilerNode] = []
            for i in (start..<input.graph.nodes.count).reversed() {
                let node = input.graph.nodes[i]
                input.graph.nodes.remove(at: i)
                branchNodes.append(node)
            }
            branchNodes.reverse()
            branchNode.subNodes[branch] = branchNodes
        }
    }
}


func prepareInput(input: JelloCompilerInput) throws {
    labelBranches(input: input)
    pruneGraph(input: input)
    topologicallyOrderGraph(input: input)
    try concretiseTypesInGraph(input: input)
    decomposeGraph(input: input)
}



public func compileToSpirv(input: JelloCompilerInput) throws -> (vertex: [UInt32]?, fragment: [UInt32]?) {
    labelBranches(input: input)
    pruneGraph(input: input)
    topologicallyOrderGraph(input: input)
    try concretiseTypesInGraph(input: input)
    let nodes = input.graph.nodes
    decomposeGraph(input: input)
    
    let vertex: [UInt32]? = defaultVertexShader
    
    for outputPort in nodes.flatMap({$0.outputPorts}) {
        outputPort.clearReservation()
    }
    
    let fragment = #document({
        let fragmentEntryPoint = #id
        JelloCompilerBlackboard.fragOutputColorId = #id
        #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
        let glsl450Id = #id
        #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
        JelloCompilerBlackboard.glsl450ExtId = glsl450Id
        
        #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
        #executionMode(opCode: SpirvOpExecutionMode, [fragmentEntryPoint, SpirvExecutionModeOriginUpperLeft.rawValue])
     
        let frameDataTypeId = FrameData.register()
        let (_, createFrameDataVariable) = FrameData.registerPointerType(storageClass: SpirvStorageClassUniformConstant)
        
        let frameDataId = createFrameDataVariable()
        #debugNames(opCode: SpirvOpName, [frameDataId], #stringLiteral("frameData"))
        #annotation(opCode: SpirvOpDecorate, [frameDataTypeId, SpirvDecorationBlock.rawValue])
        var frameDataOffset: UInt32 = 0
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 4, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 16
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 5, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 16
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 48
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 64
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 9, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 16
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 10, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 16
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 11, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 16
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 12, SpirvDecorationOffset.rawValue, frameDataOffset])
        frameDataOffset += 4
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 13, SpirvDecorationOffset.rawValue, frameDataOffset])
        // Matrix strides for Frame Data
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationMatrixStride.rawValue, 16])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationMatrixStride.rawValue, 16])
        // Matrix Layout for Frame Data
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationRowMajor.rawValue])
        #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationRowMajor.rawValue])
        
        #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationDescriptorSet.rawValue, 0])
        #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationBinding.rawValue, 2])
        #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationNonWritable.rawValue])

        JelloCompilerBlackboard.frameDataId = frameDataId

        let float4TypeId = declareType(dataType: .float4)
        let float3TypeId = declareType(dataType: .float3)
        let float2TypeId = declareType(dataType: .float2)
        
        let float4InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float4TypeId])
        let float3InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float3TypeId])
        let float2InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float2TypeId])
        
        
        // World Pos In
        let worldPosInId = #id
        JelloCompilerBlackboard.worldPosInId = worldPosInId
        #globalDeclaration(opCode: SpirvOpVariable, [float4InputPointerTypeId, worldPosInId, SpirvStorageClassInput.rawValue])
        #debugNames(opCode: SpirvOpName, [worldPosInId], #stringLiteral("worldPos"))
        #annotation(opCode: SpirvOpDecorate, [worldPosInId, SpirvDecorationLocation.rawValue, 0])

        // TexCoord In
        let texCoordInId = #id
        JelloCompilerBlackboard.texCoordInId = texCoordInId
        #globalDeclaration(opCode: SpirvOpVariable, [float2InputPointerTypeId, texCoordInId, SpirvStorageClassInput.rawValue])
        #debugNames(opCode: SpirvOpName, [texCoordInId], #stringLiteral("texCoord"))
        #annotation(opCode: SpirvOpDecorate, [texCoordInId, SpirvDecorationLocation.rawValue, 1])
        // Tangent In
        let tangentInId = #id
        JelloCompilerBlackboard.tangentInId = tangentInId
        #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, tangentInId, SpirvStorageClassInput.rawValue])
        #debugNames(opCode: SpirvOpName, [tangentInId], #stringLiteral("tangent"))
        #annotation(opCode: SpirvOpDecorate, [tangentInId, SpirvDecorationLocation.rawValue, 2])
        
        // Bitangent In
        let bitangentInId = #id
        JelloCompilerBlackboard.bitangentInId = bitangentInId
        #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, bitangentInId, SpirvStorageClassInput.rawValue])
        #debugNames(opCode: SpirvOpName, [bitangentInId], #stringLiteral("bitangent"))
        #annotation(opCode: SpirvOpDecorate, [bitangentInId, SpirvDecorationLocation.rawValue, 3])
        
        // Normal In
        let normalInId = #id
        JelloCompilerBlackboard.normalInId = normalInId
        #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, normalInId, SpirvStorageClassInput.rawValue])
        #debugNames(opCode: SpirvOpName, [normalInId], #stringLiteral("normal"))
        #annotation(opCode: SpirvOpDecorate, [normalInId, SpirvDecorationLocation.rawValue, 4])
        
        for node in nodes {
            node.install()
        }
        let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
        #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelFragment.rawValue], [fragmentEntryPoint], #stringLiteral("fragmentMain"), [JelloCompilerBlackboard.fragOutputColorId, JelloCompilerBlackboard.frameDataId, worldPosInId, texCoordInId, tangentInId, bitangentInId, normalInId])
        let typeFragmentFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
        #functionHead(opCode: SpirvOpFunction, [typeVoid, fragmentEntryPoint, 0, typeFragmentFunction])
        #functionHead(opCode: SpirvOpLabel, [#id])
        for node in input.graph.nodes {
            node.write()
        }
        #functionBody(opCode: SpirvOpReturn)
        #functionBody(opCode: SpirvOpFunctionEnd)
        SpirvFunction.instance.writeFunction()
        JelloCompilerBlackboard.clear()
    })
   
    
    return (vertex: vertex, fragment: fragment)
}



