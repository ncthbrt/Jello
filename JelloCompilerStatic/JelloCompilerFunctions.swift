//
//  JelloFunctions.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/21.
//

import Foundation
import Collections
import Algorithms
import SwiftCSP

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


public class SameTypeConstraint: BinaryConstraint<UUID, JelloConcreteDataType>  {
    public override func isSatisfied(assignment: Dictionary<UUID, JelloConcreteDataType>) -> Bool {
        assignment[variable1] == assignment[variable2]
    }
}

public class SameTypesConstraint: ListConstraint<UUID, JelloConcreteDataType> {
    public override func isSatisfied(assignment: Dictionary<UUID, JelloConcreteDataType>) -> Bool {
        var fst = assignment.first?.value
        return assignment.values.allSatisfy({ $0 == fst })
    }
}

public func concretiseTypesInGraph(input: JelloCompilerInput) -> [UUID: JelloConcreteDataType]? {
    var outputPorts = input.graph.nodes.flatMap({$0.outputPorts})
    var inputPorts = input.graph.nodes.flatMap({$0.inputPorts})
    var variables: [UUID] = outputPorts.map({$0.id})
    variables.append(contentsOf: inputPorts.map({$0.id}))
    var domains: [UUID: [JelloConcreteDataType]] = [:]
    
    for port in inputPorts {
        domains[port.id] = getDomain(input: port.dataType)
    }
    for port in outputPorts {
        domains[port.id] = getDomain(input: port.dataType)
    }
    
    var csp = CSP<UUID, JelloConcreteDataType>(variables: variables, domains: domains)
    
    var edges = inputPorts.filter({$0.incomingEdge != nil}).map({$0.incomingEdge!})
    for edge in edges {
        csp.addConstraint(constraint: SameTypeConstraint(variable1: edge.inputPort.id, variable2: edge.outputPort.id))
    }
    for node in input.graph.nodes {
        for constraint in node.constraints {
            csp.addConstraint(constraint: constraint)
        }
    }
    return backtrackingSearch(csp: csp, mrv: true)
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


