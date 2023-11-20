//
//  NodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import SwiftUI
import OrderedCollections
import SwiftData


struct NodeRendererView: View {
    @Environment(\.modelContext) var modelContext
    @State var selected: Bool = false
    @State var lastTranslation: CGSize = .zero
    @State var dragPosition: CGPoint = .zero
    @ObservedObject var sim: JellyBoxVertletSimulation
    @State var dragStarted: Bool = false
    @State var nodeHeight: CGFloat = 50.0
    @Environment(\.canvasTransform) var canvasTransform
    
    var node : JelloNode
    let inputPorts: [JelloInputPort]
    let outputPorts: [JelloOutputPort]
    
    var body: some View {
        ZStack {
            Path(sim.draw)
                .fill(Gradient(colors: [.green, .blue]))
            Path(sim.draw)
                .fill(.ultraThickMaterial)
                .stroke(Gradient(colors: [.green, .blue]), lineWidth: 3, antialiased: true)
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                Spacer()
            }
            .padding(.all, JelloNode.padding)
            NodeInputPortsView(nodeId: node.id)
            NodeOutputPortsView(nodeId: node.id)
        }
        .animation(.interactiveSpring(), value: node.position)
        .contextMenu {
            Button {
                // Add this item to a list of favorites.
            } label: {
                Label("Pin Preview", systemImage: "eye")
            }
            Button(role: .destructive) {
                let nodeId = node.id
                try! modelContext.transaction {
                    let inputPorts = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloInputPort>{ $0.node?.id == nodeId }))
                    for inputPort in inputPorts {
                        if let edge = inputPort.edge {
                            modelContext.delete(edge)
                        }
                    }
                    let outputPorts = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloOutputPort>{ $0.node?.id == nodeId }))
                    for outputPort in outputPorts {
                        let outputPortId = outputPort.id
                        let edges = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge>{ $0.outputPort?.id == outputPortId }))
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
        .frame(width: JelloNode.nodeWidth, height: nodeHeight, alignment: .center)
        .contentShape(Rectangle())
        .position(node.position)
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
        .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
        .onAppear {
            self.nodeHeight = JelloNode.computeNodeHeight(inputPortsCount: inputPorts.count, outputPortsCount: outputPorts.count)
            self.sim.setup(dimensions: CGPoint(x: JelloNode.nodeWidth, y: nodeHeight), topLeft: node.position, constraintIterations: 4, updateIterations: 4, radius: JelloNode.cornerRadius)
            self.sim.startUpdate()
        }
        .onDisappear {
            self.sim.stopUpdate()
        }
        .onChange(of: inputPorts.count) { _, _ in
            self.nodeHeight = JelloNode.computeNodeHeight(inputPortsCount: inputPorts.count, outputPortsCount: outputPorts.count)
            self.sim.dimensions = CGPoint(x: self.sim.dimensions.x, y: nodeHeight)
        }
        .onChange(of: outputPorts.count) { _, _ in
            self.nodeHeight = JelloNode.computeNodeHeight(inputPortsCount: inputPorts.count, outputPortsCount: outputPorts.count)
            self.sim.dimensions = CGPoint(x: self.sim.dimensions.x, y: nodeHeight)
        }
        .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
            return newValue ? .start : .stop
        }
    }
}

struct NodeView : View {
    @State var sim : JellyBoxVertletSimulation = JellyBoxVertletSimulation()

    @Query var outputPorts: [JelloOutputPort]
    @Query var inputPorts: [JelloInputPort]

    let node: JelloNode
    let controller: JelloNodeController
    
    init(node: JelloNode) {
        self.node = node
        self.controller = JelloNodeControllerFactory.getController(node)
        _outputPorts = Query(FetchDescriptor(predicate: Self.outputPortPredicate(nodeId: node.id)))
        _inputPorts = Query(FetchDescriptor(predicate: Self.inputPortPredicate(nodeId:node.id)))
    }
    
    static func outputPortPredicate(nodeId: UUID) -> Predicate<JelloOutputPort> {
        return #Predicate { $0.node?.id == nodeId }
    }
    
    static func inputPortPredicate(nodeId: UUID) -> Predicate<JelloInputPort> {
        return #Predicate { $0.node?.id == nodeId }
    }
    
    var body: some View {
        NodeRendererView(sim: sim, node: node, inputPorts: inputPorts, outputPorts: outputPorts)
            .onAppear {
                controller.setup(node: node)
            }
    }
}
