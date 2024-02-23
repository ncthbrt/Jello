//
//  PreviewNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/03.
//

import SwiftUI
import MetalKit
import ModelIO
import SwiftData
import JelloCompilerStatic

fileprivate struct PreviewNodeViewImpl: View {
    let node: JelloNode
    var graphs: [JelloGraph]
    let nodes: [JelloNode]
    let edges: [JelloEdge]
    let nodeData: [JelloNodeData]
    let inputPorts: [JelloInputPort]
    let outputPorts: [JelloOutputPort]
    

    var body: some View {
        if let graph = graphs.first, !graph.isDeleted {
            let graphInput = JelloCompilerBridge.buildGraphInput(outputNode: node, jelloGraph: graph, jelloNodes: nodes, jelloNodeData: nodeData.filter({$0.node?.graph?.uuid == node.graph?.uuid}), jelloEdges: edges, jelloInputPorts: inputPorts.filter({$0.node?.graph?.uuid == graph.uuid}), jelloOutputPorts: outputPorts.filter({$0.node?.graph?.uuid == graph.uuid}))
            if let result = try? JelloCompilerStatic.compileToSpirv(input: graphInput), let lastStage = result.stages.last {
                
                let maybeVertex = lastStage.shaders.filter({shader in
                    switch shader {
                    case .vertex(_):
                        return true
                    default:
                        return true
                    }
                }).first
                
                
                let maybeFragment = lastStage.shaders.filter({shader in
                    switch shader {
                    case .fragment(_):
                        return true
                    default:
                        return false
                    }
                }).first
                
                let maybeRaster = result.stages.flatMap({$0.shaders}).filter({shader in
                    switch shader {
                    case .computeRasterizer(_):
                        return true
                    default:
                        return false
                    }
                }).first

                let maybeCompute = result.stages.flatMap({$0.shaders}).filter({shader in
                    switch shader {
                    case .compute(_):
                        return true
                    default:
                        return false
                    }
                }).first
                
                if case .compute(let computeSpirv) = maybeCompute {
                    let _ = print("Compute:\n\(computeSpirv.shader)")
                    let _ = try? JelloCompilerStatic.compileMSLShader(input: maybeCompute!)
                }
                
                if case .computeRasterizer(let computeSpirv) = maybeRaster {
                    let _ = print("Raster:\n\(computeSpirv.shader)")
                    let _ = try? JelloCompilerStatic.compileMSLShader(input: maybeRaster!)
                }

                if case .vertex(_) = maybeVertex,
                   case .fragment(_) = maybeFragment,
                   case .vertex(let vertexMSL) = try? JelloCompilerStatic.compileMSLShader(input: maybeVertex!),
                   case .fragment(let fragmentMSL) = try? JelloCompilerStatic.compileMSLShader(input: maybeFragment!) {
                    ShaderPreviewView(vertexShader: vertexMSL, fragmentShader: fragmentMSL, previewGeometry: .sphere)
                }
            }
        }
    }
}

struct PreviewNodeView: View {
    @Query var graphs: [JelloGraph]
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var nodeData: [JelloNodeData]
    @Query(sort: \JelloInputPort.index) var inputPorts: [JelloInputPort]
    @Query(sort: \JelloOutputPort.index) var outputPorts: [JelloOutputPort]
    let node: JelloNode
    let drawBounds: (inout Path) -> ()
    
    init(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let graphId: UUID = node.graph?.uuid ?? UUID()
        self._graphs = Query(FetchDescriptor(predicate: #Predicate { $0.uuid == graphId }))
        self._nodes = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
        self._edges = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
    }

    var body: some View {
        // TODO: Make compilation asynchronous
        ZStack {
            PreviewNodeViewImpl(node: node, graphs: graphs, nodes: nodes, edges: edges, nodeData: nodeData, inputPorts: inputPorts, outputPorts: outputPorts) .clipShape(Path(drawBounds)).clipped(antialiased: true)
            Path(drawBounds).fill(Gradient(colors: [.black.opacity(0.3), .clear]))
            VStack {
                Text("Preview").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                Spacer()
            }.padding(.all, JelloNode.padding)
        }
    }
}
