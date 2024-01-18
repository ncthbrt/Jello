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
    
    func compileMSL(input: JelloCompilerInput) throws -> (vertex: String?, fragment: String?) {
        let result = try JelloCompilerStatic.compileToSpirv(input: input)
        
        var vertex : String? = nil
        var fragment : String? = nil
        if let vertexSpirv = result.vertex {
            vertex = try JelloCompilerStatic.compileMSLShader(spirv: vertexSpirv)
        }
        if let fragmentSpirv = result.fragment {
            fragment = try JelloCompilerStatic.compileMSLShader(spirv: fragmentSpirv)
        }
        
        return (vertex: vertex, fragment: fragment)
    }
    
    func buildGraph(outputNode: JelloNode, jelloGraph: JelloGraph, jelloNodes: [JelloNode], jelloNodeData: [JelloNodeData], jelloEdges: [JelloEdge], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort]) -> JelloCompilerInput {
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
                if let inputEdge = edgesDictionary[port.id], let outputPort = compilerOutputPorts[inputEdge.outputPort?.uuid ?? UUID()] {
                    let _ = CompilerEdge(inputPort: port, outputPort: outputPort)
                }
            }
        }
        
        if outputNode.type == .builtIn(.preview) {
            return JelloCompilerInput(output: .previewOutput(compilerNodes.first(where: {$0.id == outputNode.uuid})! as! PreviewOutputCompilerNode), graph: graph)
        } else if outputNode.type == .builtIn(.materialOutput) {
            return JelloCompilerInput(output: .materialOutput(compilerNodes.first(where: {$0.id == outputNode.uuid})! as! MaterialOutputCompilerNode), graph: graph)
        } else {
            fatalError("Unexpected output node type")
        }
        
    }
    
    private func buildCompilerNode(jelloNode: JelloNode, jelloNodeData: [String: JelloNodeDataValue], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort]) -> CompilerNode? {
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
        case .builtIn(.worldPosition):
            return LoadCompilerNode(outputPort: compilerOutputPorts.first!, type: .float4, getPointerId: { JelloCompilerBlackboard.worldPosInId }, normalize: false)
        case .builtIn(.texCoord):
            return LoadCompilerNode(outputPort: compilerOutputPorts.first!, type: .float2, getPointerId: { JelloCompilerBlackboard.texCoordInId }, normalize: false)
        case .builtIn(.normal):
            return LoadCompilerNode(outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.normalInId }, normalize: true)
        case .builtIn(.tangent):
            return LoadCompilerNode(outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.tangentInId }, normalize: true)
        case .builtIn(.bitangent):
            return LoadCompilerNode(outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.bitangentInId }, normalize: true)
        case .material:
            // TODO: Add support for nested materials
            return nil
        case .userFunction:
            // TODO: Add support for user functions
            return nil
        }
    }
    
}
