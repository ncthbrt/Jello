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

struct PreviewNodeViewImpl: View {
    let node: JelloNode
    var graphs: [JelloGraph]
    let nodes: [JelloNode]
    let edges: [JelloEdge]
    let nodeData: [JelloNodeData]
    let inputPorts: [JelloInputPort]
    let outputPorts: [JelloOutputPort]
    @Environment(JelloCompilerService.self) var compiler

    var body: some View {
        let graphInput = compiler.buildGraph(outputNode: node, jelloGraph: graphs.first!, jelloNodes: nodes, jelloNodeData: nodeData.filter({$0.node?.graph?.uuid == node.graph?.uuid}), jelloEdges: edges, jelloInputPorts: inputPorts.filter({$0.node?.graph?.uuid == node.graph?.uuid}), jelloOutputPorts: outputPorts.filter({$0.node?.graph?.uuid == node.graph?.uuid}))
        let result = try! compiler.compileMSL(input: graphInput)
        
        ShaderPreviewView(vertexShader: result.vertex!, fragmentShader: result.fragment!, previewGeometry: .sphere)
    }
}

struct PreviewNodeView: View {
    @Query var graphs: [JelloGraph]
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var nodeData: [JelloNodeData]
    @Query var inputPorts: [JelloInputPort]
    @Query var outputPorts: [JelloOutputPort]
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
