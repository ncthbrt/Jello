//
//  JelloCompiler.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/12/06.
//

import Foundation
import SwiftUI
import SwiftData
import JelloCompilerStatic
import simd

@Observable class JelloCompilerService {
    @ObservationIgnored private var modelContext: ModelContext?
    
    func initialize(modelContext: ModelContext){
        self.modelContext = modelContext
    }
    
    func compileOutputs(materialId: UUID) async throws {
        if let someModelContext = modelContext {
            try someModelContext.transaction {
                guard let someMaterial = try? someModelContext.fetch(FetchDescriptor<JelloMaterial>(predicate: #Predicate{ $0.uuid == materialId })).first  else {
                    return
                }
                let graphId = someMaterial.graph.uuid
                
                guard let someGraph = try? someModelContext.fetch(FetchDescriptor<JelloGraph>(predicate: #Predicate{ $0.uuid == graphId })).first else {
                    return
                }
                
                guard let nodes = try? someModelContext.fetch(FetchDescriptor<JelloNode>(predicate: #Predicate{ $0.graph?.uuid == graphId })) else {
                    return
                }
                
                guard let edges = try? someModelContext.fetch(FetchDescriptor<JelloEdge>(predicate: #Predicate{ $0.graph?.uuid == graphId })) else {
                    return
                }
                
                guard let inputPorts = try? someModelContext.fetch(FetchDescriptor<JelloInputPort>(predicate: #Predicate{ $0.node?.graph?.uuid == graphId })) else {
                    return
                }
                
                guard let outputPorts = try? someModelContext.fetch(FetchDescriptor<JelloOutputPort>(predicate: #Predicate{ $0.node?.graph?.uuid == graphId })) else {
                    return
                }
                
                guard let data = try? someModelContext.fetch(FetchDescriptor<JelloNodeData>(predicate: #Predicate{ $0.node?.graph?.uuid == graphId })) else {
                    return
                }
                
                let graph = buildGraph(jelloGraph: someGraph, jelloNodes: nodes, jelloNodeData: data, jelloEdges: edges, jelloInputPorts: inputPorts, jelloOutputPorts: outputPorts)
            }
        }
    }
    
    func buildGraph(jelloGraph: JelloGraph, jelloNodes: [JelloNode], jelloNodeData: [JelloNodeData], jelloEdges: [JelloEdge], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort]) -> CompilerGraph {
        let graph = CompilerGraph()
        let inputPortsDict: [UUID: [JelloInputPort]] = jelloInputPorts.reduce(into: [UUID:[JelloInputPort]](), { (result, port) in
            if let nodeUUID = port.node?.uuid {
                result[nodeUUID, default: []].append(port)
            }
        })
        
        let outputPortsDict: [UUID: [JelloOutputPort]] = jelloOutputPorts.reduce(into: [UUID:[JelloOutputPort]](), { (result, port) in
            if let nodeUUID = port.node?.uuid {
                result[nodeUUID, default: []].append(port)
            }
        })
        
        let jelloNodeData = jelloNodeData.grouped(by: { $0.node!.uuid }).reduce(into: [UUID: [String:JelloNodeDataValue]](), { result, kv in
            result[kv.key] = kv.value.reduce(into: [String: JelloNodeDataValue](), { dict, value in dict[value.key] = value.value })
        })
        let compilerNodes = jelloNodes.map({ buildCompilerNode(jelloNode: $0, jelloNodeData: jelloNodeData[$0.uuid] ?? [String:JelloNodeDataValue](), jelloInputPorts: inputPortsDict[$0.uuid] ?? [], jelloOutputPorts: outputPortsDict[$0.uuid] ?? [])}).filter({$0 != nil}).map({$0!})
        
        let compilerOutputPorts = compilerNodes.flatMap({$0.outputPorts}).reduce(into: [UUID:OutputCompilerPort](), {result, port in result[port.id] = port })
        let edgesDictionary = jelloEdges.reduce(into: [UUID: JelloEdge](), {result, edge in result[edge.inputPort?.uuid] = edge })
        graph.nodes = compilerNodes
        
        for node in compilerNodes {
            for port in node.inputPorts {
                if let inputEdge = edgesDictionary[port.id] {
                    let _ = CompilerEdge(inputPort: port, outputPort: compilerOutputPorts[inputEdge.outputPort!.uuid]!)
                }
            }
        }
        
        return graph
    }
    
    
    
    func buildCompilerNode(jelloNode: JelloNode, jelloNodeData: [String: JelloNodeDataValue], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort]) -> CompilerNode? {
        let compilerInputPorts = jelloInputPorts.map({ InputCompilerPort(id: $0.uuid, dataType: $0.dataType) })
        let compilerOutputPorts = jelloOutputPorts.map({ OutputCompilerPort(id: $0.uuid, dataType: $0.dataType) })
        switch(jelloNode.type) {
        case .builtIn(.add):
            return AddCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.subtract):
            return SubtractCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.preview):
            return PreviewOutputCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!)
        case .builtIn(.slabShader):
            return nil
        case .builtIn(.materialOutput):
            let node = MaterialOutputCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!)
            return node
        case .builtIn(.color):
            let value = jelloNodeData[JelloNodeDataKey.value.rawValue] ?? .null
            if case JelloNodeDataValue.float4(let x, let y, let z, let w) = value {
                let node = ConstantCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, value: .float4(vector_float4(x, y, z, w)))
                return node
            }
            return nil
        case .material:
            // TODO: Add support for nested materials
            return nil
        case .userFunction:
            // TODO: Add support for user functions
            return nil
        }
    }
}
