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



public func compileToSpirv(input: JelloCompilerInput) throws -> [UInt32] {
    labelBranches(input: input)
    pruneGraph(input: input)
    topologicallyOrderGraph(input: input)
    try concretiseTypesInGraph(input: input)
    
    return #document({
        #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
        let glsl450Id = #id
        #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
        #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
        
        for node in input.graph.nodes {
            node.install()
        }
        decomposeGraph(input: input)
        
        // Write vertex
        let vertexEntryPoint = #id
        #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelFragment.rawValue], [vertexEntryPoint], #stringLiteral("vertexMain"), [])
        let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
        let typeVertexFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
        #functionHead(opCode: SpirvOpFunction, [typeVoid, vertexEntryPoint, 0, typeVertexFunction])
        #functionHead(opCode: SpirvOpLabel, [#id])
        for node in input.graph.nodes {
            node.writeVertex()
        }
        #functionBody(opCode: SpirvOpFunctionEnd)
        SpirvFunction.instance.writeFunction()
        
        
        // Write fragment
        let fragmentEntryPoint = #id
        #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelFragment.rawValue], [fragmentEntryPoint], #stringLiteral("fragmentMain"), [])
        let typeFragmentFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
        #functionHead(opCode: SpirvOpFunction, [typeVoid, fragmentEntryPoint, 0, typeFragmentFunction])
        #functionHead(opCode: SpirvOpLabel, [#id])
        for node in input.graph.nodes {
            node.writeFragment()
        }
        #functionBody(opCode: SpirvOpFunctionEnd)
        SpirvFunction.instance.writeFunction()
        return
    })
}



