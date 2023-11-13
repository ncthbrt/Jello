//
//  NodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import SwiftUI
import OrderedCollections

struct NodeRendererView: View {
    var node: JelloNode
    @Environment(\.modelContext) var modelContext
    @State var selected: Bool = false
    @State var lastTranslation: CGSize = .zero
    @State var dragStarted: Bool = false
    @State var dragPosition: CGPoint = .zero
    @ObservedObject var sim: JellyBoxVertletSimulation
    @Binding var newEdge : JelloEdge?

    @ViewBuilder var inputPorts: some View {
        ForEach(node.inputPorts) {
            input in InputPortView(port: input, highlightPort: false)
                .frame(height: JelloNode.portHeight, alignment: .topLeading)
                .position(node.getInputPortPositionOffset(portId: input.id, relativeTo: .nodeSpace))
        }
    }
    
    @ViewBuilder var outputPorts: some View {
        ForEach(node.outputPorts) {
            output in OutputPortView(port: output)
                .position(node.getOutputPortPositionOffset(portId: output.id, relativeTo: .nodeSpace))
                .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
                    return newValue ? .start : .stop
                }
                .gesture(DragGesture().onChanged({ drag in
//                    if newEdge == nil {
//                        dragStarted = true
////                        newEdge = JelloEdge(id: Edge.Id(rawValue: UUID()), dataType: output.dataType, outputNode: node, outputPort: output)
//                        graph.edges[newEdge!.id] = newEdge!
//                        node.addOutputEdge(edge: newEdge!)
//                    }
//                    newEdge!.setEndPosition(newEdge!.startPosition + CGPoint(x: drag.translation.width, y: drag.translation.height), graph: graph, dependencies: newEdgeDependencies)
                }).onEnded({ drag in
//                    newEdge!.setEndPosition(newEdge!.startPosition + CGPoint(x: drag.translation.width, y: drag.translation.height), graph: graph, dependencies: newEdgeDependencies)
//                    if let nEdge = newEdge, nEdge.inputNode == nil {
//                        graph.edges.removeValue(forKey: nEdge.id)
//                        nEdge.outputNode.removeOutputEdge(edge: nEdge)
//                    }
                    newEdge = nil
                    dragStarted = false
                }))
        }
    }
    
    var body: some View {
            let nodeHeight = node.computeNodeHeight()
            ZStack {
                Path(sim.draw)
                    .fill(Gradient(colors: [.green, .blue]))
                Path(sim.draw)
                     .fill(.ultraThickMaterial)
                     .stroke(Gradient(colors: [.green, .blue]), lineWidth: 3, antialiased: true)
                VStack {
                    Text("Unknown").font(.title2)
                        .bold()
                        .monospaced()
                    Spacer()
                }
                .padding(.all, JelloNode.padding)
            }
            .animation(.interactiveSpring(), value: node.position)
            .frame(width: JelloNode.nodeWidth, height: nodeHeight, alignment: .center)
            .contextMenu {
                Button {
                    // Add this item to a list of favorites.
                } label: {
                    Label("Pin Preview", systemImage: "eye")
                }
                Button(role: .destructive) {
                    // Add this item to a list of favorites.
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                Button(role: .destructive) {
                    // Open Maps and center it on this item.
                } label: {
                    Label("Dissolve", systemImage: "wand.and.rays")
                }
            }
            .position(node.position)
            .onAppear {
                self.sim.setup(dimensions: CGPoint(x: JelloNode.nodeWidth, y: nodeHeight), topLeft: node.position, particleDensity: 50, constraintIterations: 4, updateIterations: 4, radius: JelloNode.cornerRadius)
                self.sim.startUpdate()
            }
            .onDisappear {
                self.sim.stopUpdate()
            }
            .onChange(of: node.position, { _, next in
            })
            .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
                return newValue ? .start : .stop
            }
             .gesture(DragGesture()
                               .onChanged { dragGesture in
                                       sim.dragging = true
                                       dragStarted = true
                                       let delta = CGPoint(x: dragGesture.translation.width - lastTranslation.width, y: dragGesture.translation.height - lastTranslation.height)
                                       node.position = node.position + delta
                                       sim.position = node.position
                                       sim.dragPosition = dragGesture.location
                                       lastTranslation = dragGesture.translation
                                   }.onEnded {_ in
                                       lastTranslation = .zero
                                       dragStarted = false
                                       sim.dragging = false
                                   }
                           )
            
        }
}

struct NodeView : View {
    @State var sim : JellyBoxVertletSimulation = JellyBoxVertletSimulation()
    var node: JelloNode
    @Binding var newEdge: JelloEdge?
    
    var body: some View {
        NodeRendererView(node: node, sim: sim, newEdge: $newEdge)
    }
}
