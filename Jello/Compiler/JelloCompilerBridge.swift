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
import SPIRV_Headers_Swift

class JelloCompilerBridge {
    static func buildGraph(jelloGraph: JelloGraph, jelloNodes: [JelloNode], jelloNodeData: [JelloNodeData], jelloEdges: [JelloEdge], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort], useBaseDataTypes: Bool) -> CompilerGraph {
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
        let compilerNodes = jelloNodes.map({ Self.buildCompilerNode(jelloNode: $0, jelloNodeData: jelloNodeData[$0.uuid] ?? [String:JelloNodeDataValue](), jelloInputPorts: inputPortsDict[$0.uuid] ?? [], jelloOutputPorts: outputPortsDict[$0.uuid] ?? [], useBaseDataTypes: useBaseDataTypes)}).filter({$0 != nil}).map({$0!})
        
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
        
        return graph
    }
    
    static func buildGraphInput(outputNode: JelloNode, jelloGraph: JelloGraph, jelloNodes: [JelloNode], jelloNodeData: [JelloNodeData], jelloEdges: [JelloEdge], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort]) -> JelloCompilerInput {
        let graph = buildGraph(jelloGraph: jelloGraph, jelloNodes: jelloNodes, jelloNodeData: jelloNodeData, jelloEdges: jelloEdges, jelloInputPorts: jelloInputPorts, jelloOutputPorts: jelloOutputPorts, useBaseDataTypes: false)
        if outputNode.nodeType == .builtIn(.preview) {
            return JelloCompilerInput(id: outputNode.uuid, output: .previewOutput(graph.nodes.first(where: {$0.id == outputNode.uuid})! as! PreviewOutputCompilerNode), graph: graph)
        } else if outputNode.nodeType == .builtIn(.materialOutput) {
            return JelloCompilerInput(id: outputNode.uuid, output: .materialOutput(graph.nodes.first(where: {$0.id == outputNode.uuid})! as! MaterialOutputCompilerNode), graph: graph)
        } else {
            fatalError("Unexpected output node type")
        }
    }
    
    private static func buildCompilerNode(jelloNode: JelloNode, jelloNodeData: [String: JelloNodeDataValue], jelloInputPorts: [JelloInputPort], jelloOutputPorts: [JelloOutputPort], useBaseDataTypes: Bool) -> CompilerNode? {
        let compilerInputPorts = jelloInputPorts.map({ InputCompilerPort(id: $0.uuid, dataType: useBaseDataTypes ? $0.baseDataType :  $0.currentDataType) })
        let compilerOutputPorts = jelloOutputPorts.map({ OutputCompilerPort(id: $0.uuid, dataType: useBaseDataTypes ? $0.baseDataType :  $0.currentDataType) })
        switch(jelloNode.nodeType) {
        case .builtIn(.add):
            return AddCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.subtract):
            return SubtractCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.divide):
            return DivideCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.multiply):
            return MultiplyCompilerNode(id: jelloNode.uuid, inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.fract):
            return UnaryGLSL450OperatorCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!, outputPort: compilerOutputPorts.first!, glsl450Operator: GLSLstd450Fract, uniformIO: true)
        case .builtIn(.normalize):
            return UnaryGLSL450OperatorCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!, outputPort: compilerOutputPorts.first!, glsl450Operator: GLSLstd450Normalize, uniformIO: true)
        case .builtIn(.length):
            return UnaryGLSL450OperatorCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!, outputPort: compilerOutputPorts.first!, glsl450Operator: GLSLstd450Length, uniformIO: false)
        case .builtIn(.preview):
            return PreviewOutputCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!)
        case .builtIn(.slabShader):
            return nil
        case .builtIn(.materialOutput):
            let node = MaterialOutputCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!)
            return node
        case .builtIn(.compute):
            if case .int3(let x, let y, let z) = jelloNodeData[JelloNodeDataKey.value.rawValue] ?? .null {
                return ComputeCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!, outputPort: compilerOutputPorts.first!, computationDimension: .dimension(x, y, z))
            }
            return nil
        case .builtIn(.sample):
            return SampleCompilerNode(id: jelloNode.uuid, fieldInputPort: compilerInputPorts[0], positionInputPort: compilerInputPorts[1], lodInputPort: compilerInputPorts.count > 2 ? compilerInputPorts[2] : nil, outputPort: compilerOutputPorts[0])
        case .builtIn(.color):
            let value = jelloNodeData[JelloNodeDataKey.value.rawValue] ?? .null
            if case JelloNodeDataValue.float4(let h, let s, let b, let a) = value {
                let rgb = hsb2rgb(hsb: .init(h, s, b))
                let node = ConstantCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, value: .float4(vector_float4(rgb.x, rgb.y, rgb.z, a)))
                return node
            }
            return nil
        case .builtIn(.worldPosition):
            return LoadCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, type: .float4, getPointerId: { JelloCompilerBlackboard.worldPosInId }, normalize: false)
        case .builtIn(.texCoord):
            return LoadCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, type: .float2, getPointerId: { JelloCompilerBlackboard.texCoordInId }, normalize: false)
        case .builtIn(.normal):
            return LoadCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.normalInId }, normalize: true)
        case .builtIn(.tangent):
            return LoadCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.tangentInId }, normalize: true)
        case .builtIn(.bitangent):
            return LoadCompilerNode(id: jelloNode.uuid, outputPort: compilerOutputPorts.first!, type: .float3, getPointerId: { JelloCompilerBlackboard.bitangentInId }, normalize: true)
        case .builtIn(.swizzle):
            let componentCount = jelloNodeData[JelloNodeDataKey.componentCount.rawValue] ?? .null
            let value = jelloNodeData[JelloNodeDataKey.value.rawValue] ?? .null
            if case JelloNodeDataValue.float4(let x, let y, let z, let w) = value, case .int(let componentCount) = componentCount {
                return SwizzleCompilerNode(id: jelloNode.uuid, inputPort: compilerInputPorts.first!, outputPort: compilerOutputPorts.first!, selectors: SwizzleCompilerNode.buildSelectors(componentCount: componentCount, components: [x, y, z, w]))
            }
            return nil
        case .builtIn(.calculator):
            let value = jelloNodeData[JelloNodeDataKey.value.rawValue] ?? .null
            if case JelloNodeDataValue.stringArray(let array) = value {
                return MathExpressionCompilerNode(inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!, expression: try? parseMathExpression(array.value.joined(separator: "")))
            }
            return nil

        case .builtIn(.spline):
            return nil
        case .builtIn(.combine):
            return CombineCompilerNode(inputPorts: compilerInputPorts, outputPort: compilerOutputPorts.first!)
        case .builtIn(.separate):
            return SeparateCompilerNode(inputPort: compilerInputPorts.first!, outputPorts: compilerOutputPorts)
        case .material:
            // TODO: Add support for nested materials
            return nil
        case .userFunction:
            // TODO: Add support for user functions
            return nil
        }
    }
    
}
