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

// Commented out code for deleting a node!
//Button(role: .destructive) {
//    let nodeId = node.uuid
//    try! modelContext.transaction {
//        let inputPorts = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.uuid == nodeId }))
//        for inputPort in inputPorts {
//            if let edge = inputPort.edge {
//                modelContext.delete(edge)
//            }
//        }
//        let outputPorts = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.uuid == nodeId }))
//        for outputPort in outputPorts {
//            let outputPortId = outputPort.uuid
//            let edges = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge>{ $0.outputPort?.uuid == outputPortId }))
//            for edge in edges {
//                modelContext.delete(edge)
//            }
//        }
//        modelContext.delete(node)
//        if let graphId = node.graph?.uuid {
//            try updateTypesInGraph(modelContext: modelContext, graphId: graphId)
//        }
//    }
//} label: {
//    Label("Delete", systemImage: "trash.fill")
//}


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
    let gradient: Gradient
    @Binding var showInspector: Bool
    let hasSettings: Bool

    var body: some View {
        let doDraw: (inout Path) -> () = { path in
            path.addRoundedRect(in: CGRect(origin: .init(x: 1.5, y: 1.5), size: CGSize(width: CGFloat(node.width - 3), height: CGFloat(node.height - 3))), cornerSize: CGSize(width: CGFloat(5), height: CGFloat(5)))
        }
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: sqrt(5*5*2))
                    .fill(gradient)
                RoundedRectangle(cornerRadius: sqrt(5*5*2))
                    .fill(.ultraThickMaterial)
                RoundedRectangle(cornerRadius: sqrt(5*5*2))
                    .stroke(gradient, lineWidth: 3)
                innerBody(doDraw)
            }
            NodeInputPortsView(nodeId: node.uuid)
            NodeOutputPortsView(nodeId: node.uuid)
        }
        .shadow(color: boxSelection.selectedNodes.contains(node.uuid) ? Color.white : Color.clear, radius: 10)
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
        .onTapGesture(count: 1) {
            if hasSettings {
                boxSelection.selectedNodes.removeAll()
                boxSelection.selectedNodes.insert(node.uuid)
                showInspector = true
            }
        }
        .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
        .onAppear() {
//            self.sim.setup(dimensions: vector_float2(x: Float(node.width), y: Float(node.height)), topLeft: vector_float2(node.position), constraintIterations: 4, updateIterations: 2, radius: Float(JelloNode.cornerRadius))
        }
        .onDisappear() {
//            self.simulationRunner.removeSimulation(id: uuid)
        }
        .task {
//            await self.simulationRunner.addSimulation(id: uuid, sim: sim)
//            sim.position = vector_float2(node.position)
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
    let gradient: Gradient
    
    @ViewBuilder let innerBody: (@escaping (inout Path) -> ()) -> AnyView
    @Binding var showInspector: Bool
    let hasSettings: Bool

    
    @StateObject var sim : JellyBoxVertletSimulation = JellyBoxVertletSimulation()
    var body: some View {
        NodeRendererView(node: node, sim: sim, innerBody: innerBody, gradient: gradient, showInspector: $showInspector, hasSettings: hasSettings)
    }
}

struct NodeControllerView : View {
    let node: JelloNode
    let controller: any JelloNodeController
    @Binding var showInspector: Bool
    
    init(node: JelloNode, showInspector: Binding<Bool>) {
        self.node = node
        self._showInspector = showInspector
        self.controller = JelloNodeControllerFactory.getController(node)
    }
    
    
    var body: some View {
        if !node.isDeleted {
            NodeView(node: node, gradient: controller.category.getCategoryGradient(), innerBody: { path in controller.body(node: node, drawBounds: path) }, showInspector: $showInspector, hasSettings: controller.hasSettings)
        }
    }
}


