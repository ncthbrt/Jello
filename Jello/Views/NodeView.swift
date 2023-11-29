//
//  NodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import SwiftUI
import OrderedCollections
import SwiftData
import simd

fileprivate struct NodeRendererView: View {
    @Environment(\.modelContext) var modelContext
    @State var lastTranslation: CGSize = .zero
    @State var dragPosition: CGPoint = .zero
    @State var dragStarted: Bool = false
    @Environment(\.canvasTransform) var canvasTransform
    @Environment(\.boxSelection) var boxSelection
    @EnvironmentObject var simulationRunner: SimulationRunner
    @State var uuid: UUID = UUID()
    
    var node : JelloNode
    @ObservedObject var sim: JellyBoxVertletSimulation
    @ViewBuilder let innerBody: (@escaping (inout Path) -> ()) -> AnyView

    var body: some View {
        ZStack {
            Path(sim.doDraw)
                .fill(Gradient(colors: [.green, .blue]))
            Path(sim.doDraw)
                .fill(.ultraThickMaterial)
            innerBody(sim.doDraw)
            Path(sim.doDraw)
                    .stroke(Gradient(colors: [.green, .blue]), lineWidth: 3)
            NodeInputPortsView(nodeId: node.uuid)
            NodeOutputPortsView(nodeId: node.uuid)
        }
        .shadow(color: boxSelection.selectedNodes.contains(node.uuid) ? Color.white : Color.clear, radius: 10)
        .contextMenu {
            Button {
                // Add this item to a list of favorites.
            } label: {
                Label("Pin Preview", systemImage: "eye")
            }
            Button(role: .destructive) {
                let nodeId = node.uuid
                try! modelContext.transaction {
                    let inputPorts = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.uuid == nodeId }))
                    for inputPort in inputPorts {
                        if let edge = inputPort.edge {
                            modelContext.delete(edge)
                        }
                    }
                    let outputPorts = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.uuid == nodeId }))
                    for outputPort in outputPorts {
                        let outputPortId = outputPort.uuid
                        let edges = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge>{ $0.outputPort?.uuid == outputPortId }))
                        for edge in edges {
                            modelContext.delete(edge)
                        }
                    }
                }
                modelContext.delete(node)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            Button(role: .destructive) {
            } label: {
                Label("Dissolve", systemImage: "wand.and.rays")
            }
        }
        .frame(width: CGFloat(node.width), height: CGFloat(node.height), alignment: .center)
        .contentShape(Rectangle())
        .position(node.position + CGPoint(x: CGFloat(node.width/2), y: CGFloat(node.height/2)))
        .gesture(DragGesture()
            .onChanged { dragGesture in
                sim.dragging = true
                dragStarted = true
                let delta = CGPoint(x: dragGesture.translation.width - lastTranslation.width, y: dragGesture.translation.height - lastTranslation.height)
                node.position = node.position + delta
                sim.position =  vector_float2(x: Float(node.position.x), y: Float(node.position.y))
                sim.dragPosition = vector_float2(x: Float(dragGesture.location.x), y: Float(dragGesture.location.y))
                lastTranslation = dragGesture.translation
            }.onEnded {_ in
                lastTranslation = .zero
                dragStarted = false
                sim.dragging = false
            }
        )
        .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
        .onAppear() {
            self.sim.setup(dimensions: vector_float2(x: Float(node.width), y: Float(node.height)), topLeft: vector_float2(node.position), constraintIterations: 4, updateIterations: 2, radius: Float(JelloNode.cornerRadius))
        }
        .onDisappear() {
            self.simulationRunner.removeSimulation(id: uuid)
        }
        .task {
            await self.simulationRunner.addSimulation(id: uuid, sim: sim)
            sim.position = vector_float2(node.position)
        }
        .onChange(of: node.width) {
            self.sim.dimensions = vector_float2(x: Float(node.width), y: Float(node.height))
        }
        .onChange(of: node.height) {
            self.sim.dimensions = vector_float2(x: Float(node.width), y: Float(node.height))
        }
        .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
            return newValue ? .start : .stop
        }
        .setSelection(node.uuid, select: (!boxSelection.selecting && boxSelection.selectedNodes.contains(node.uuid)) || boxSelection.intersects(position: node.position, width: CGFloat(node.width), height: CGFloat(node.height)))
        
    }
}

struct NodeView: View {
    let node: JelloNode
    @ViewBuilder let innerBody: (@escaping (inout Path) -> ()) -> AnyView
    
    @State var sim : JellyBoxVertletSimulation = JellyBoxVertletSimulation()
    var body: some View {
        NodeRendererView(node: node, sim: sim, innerBody: innerBody)
    }
}

struct NodeControllerView : View {
    let node: JelloNode
    let controller: any JelloNodeController
    
    init(node: JelloNode) {
        self.node = node
        self.controller = JelloNodeControllerFactory.getController(node)
    }
    
    
    var body: some View {
        if !node.isDeleted {
            NodeView(node: node, innerBody: { path in controller.body(node: node, drawBounds: path) })
        }
    }
}
