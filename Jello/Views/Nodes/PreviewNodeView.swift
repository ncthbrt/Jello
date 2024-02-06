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
                    case .vertex(_, _):
                        return true
                    default:
                        return true
                    }
                }).first
                
                
                let maybeFragment = lastStage.shaders.filter({shader in
                    switch shader {
                    case .fragment(_, _):
                        return true
                    default:
                        return false
                    }
                }).first
                
                if case .vertex(let vertexSpirv, let vertexInputTextures) = maybeVertex,
                   case .fragment(let fragmentSpirv, let fragmentInputTextures) = maybeFragment,
                   let vertexMSL = try? JelloCompilerStatic.compileMSLShader(spirv: vertexSpirv),
                   let fragmentMSL = try? JelloCompilerStatic.compileMSLShader(spirv: fragmentSpirv) {
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
