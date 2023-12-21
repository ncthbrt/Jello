//
//  JelloFunctions.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/21.
//

import Foundation
import Collections
import Algorithms

func labelBranches(input: JelloCompilerInput){
    let startNode = input.output.node
    var queue = Deque(startNode.inputPorts.filter({$0.incomingEdge != nil}).map({(branchId: $0.newBranchId!, port: $0)}))
    while !queue.isEmpty {
        let (branchId: branchId, port: port) = queue.popFirst()!
        let node = port.incomingEdge!.outputPort.node
        port.incomingEdge!.outputPort.node.branchTags.insert(branchId)
        for port in node.inputPorts {
            if port.incomingEdge != nil {
                let newBranchId = port.newBranchId ?? branchId
                queue.append((branchId: newBranchId, port: port))
            }
        }
    }
}

func pruneGraph(input: JelloCompilerInput){
    let graph = input.graph
    graph.nodes = graph.nodes.filter({!$0.branchTags.isEmpty})
}


func getInputEdgeCount(node: Node) -> UInt {
    UInt(node.inputPorts.filter({$0.incomingEdge != nil}).count)
}

func topologicallyOrderGraph(input: JelloCompilerInput){
    var visitedNodes: Set<UUID> = []
    func hasNoDependencies(node: Node) -> Bool {
        return node.inputPorts.filter({ port in
            if let incomingEdge = port.incomingEdge {
                return !visitedNodes.contains(incomingEdge.outputPort.node.id)
            }
            return false
        }).isEmpty
    }

    var results: [Node] = input.graph.nodes.filter({hasNoDependencies(node: $0)})
    var i = 0
    while i < results.count {
        let item = results[i]
        visitedNodes.insert(item.id)
        for successorNode in item.outputPorts.flatMap({$0.outgoingEdges}).map({$0.inputPort.node}) {
            if hasNoDependencies(node: successorNode){
                results.append(successorNode)
            }
        }
        i += 1
    }
    input.graph.nodes = results
}


func decomposeGraph(input: JelloCompilerInput) {
    for node in input.graph.nodes.filter({$0 is BranchNode}) {
        var branchNode = node as! BranchNode
        for branch in branchNode.branches {
            let start = input.graph.nodes.stablePartition(by:({$0.branchTags.count == 1 && $0.branchTags.contains(branch)}))
            var branchNodes: [Node] = []
            branchNode.subNodes[branch] = branchNodes
            for i in (start..<input.graph.nodes.count).reversed() {
                let node = input.graph.nodes[i]
                input.graph.nodes.remove(at: i)
                branchNodes.append(node)
            }
            branchNodes.reverse()
        }
    }
}


