//
//  GraphView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/10.
//

import SwiftUI
import SwiftData

struct GraphView<AddNodeMenu: View> : View {
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var freeEdges: [JelloEdge]

    @Environment(\.modelContext) var modelContext
    @ViewBuilder var onOpenAddNodeMenu: (CGPoint) -> AddNodeMenu
    
    @State private var showNodeInspector : Bool = false
    @State private var showNodeMenu : Bool = false
    @State private var tapLocation: CGPoint = .zero
    @State private var scale : CGFloat = 1
    @State private var newEdge : JelloEdge? = nil
    @StateObject private var simulationRunner: SimulationRunner = SimulationRunner()
    @State private var freeEdgesEnvironmentValue: [(edge: JelloEdge, dependencies: Set<UUID>)] = []
    @State private var canvasTransform = CanvasTransform(scale: 1, position: .zero, viewPortSize: .zero)
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    @State private var position: CGPoint = .zero
    @State private var offset: CGPoint = .zero
    @State private var isDragging = false
    @State private var selection: BoxSelection = BoxSelection()
    @Binding private var viewBounds: CGRect
    let maxZoom: CGFloat = CGFloat(4)
    let minZoom: CGFloat = CGFloat(0.1)
    let graphId : UUID

    
    init(graphId: UUID, onOpenAddNodeMenu: @escaping (CGPoint) -> AddNodeMenu, bounds: Binding<CGRect>) {
        self.graphId = graphId
        self.onOpenAddNodeMenu = onOpenAddNodeMenu
        self._viewBounds = bounds
        let minX = Float(viewBounds.minX)
        let maxX = Float(viewBounds.maxX)
        let minY = Float(viewBounds.minY)
        let maxY = Float(viewBounds.maxY)
        _nodes = Query(filter: #Predicate<JelloNode> { node in node.graph?.uuid == graphId && (node.minX <= maxX && minX <= node.maxX) && (node.minY <= maxY && minY <= node.maxY) })
        _edges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.uuid == graphId && (edge.minX <= maxX && minX <= edge.maxX) && (edge.minY <= maxY && minY <= edge.maxY) })
        _freeEdges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.uuid == graphId && edge.inputPort == nil })
    }
    
    private func updateViewBounds(){
        let transformedSize = canvasTransform.transform(viewSize: CGPoint(canvasTransform.viewPortSize))
        viewBounds = CGRect(origin: canvasTransform.transform(viewPosition: .zero), size: CGSize(transformedSize)).insetBy(dx: -0.5 * transformedSize.x, dy: -0.5 * transformedSize.y)
    }


    var body: some View {
        GeometryReader { geometry in
            JelloPreviewBaker(graphId: graphId) {
                JelloCanvasRepresentable(onPanZoomGesture: { gesture in
                    withAnimation(.easeInOut) {
                        let magnification = gesture.currentDistance / gesture.startDistance
                        currentZoom = magnification - 1
                        currentZoom = max(min(maxZoom, totalZoom + currentZoom), minZoom) - totalZoom
                        let panOffset = gesture.currentCentroid / (totalZoom + currentZoom) - (gesture.startCentroid / totalZoom)
                        let zoomOffset = (-1 * (gesture.startCentroid / (totalZoom+currentZoom)) * currentZoom)
                        offset = panOffset + zoomOffset
                    }
                }, onPanZoomGestureEnd: {
                    totalZoom += currentZoom
                    currentZoom = 0
                    position = position + offset
                    offset = .zero
                })
                {
                    ZStack {
                        ZStack {
                            ForEach(nodes) { node in
                                if !node.isDeleted {
                                    NodeControllerView(node: node, showInspector: $showNodeInspector)
                                }
                            }
                            .freeEdges(freeEdgesEnvironmentValue)
                            .boxSelection(selection)
                            ForEach(edges) { edge in
                                if !edge.isDeleted {
                                    EdgeView(edge: edge)
                                }
                            }
                            if (isDragging) {
                                BoxSelectionView(start: selection.startPosition, end: selection.endPosition)
                            }
                        }
                        .environmentObject(simulationRunner)
                        .frame(width: geometry.size.width / (currentZoom + totalZoom), height: geometry.size.height / (currentZoom + totalZoom))
                        .scaleEffect(currentZoom + totalZoom)
                        .canvasTransform(canvasTransform)
                    }
                    .onBoxSelectionChange({items in selection.selectedNodes = items })
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        tapLocation = location
                        showNodeMenu = true
                    }
                    .onTapGesture(count: 1) { location in
                        selection.selectedNodes.removeAll()
                        showNodeInspector = false
                    }
                    .gesture(DragGesture()
                        .onChanged { event in
                            if !isDragging {
                                isDragging = true
                                selection.startPosition = canvasTransform.transform(viewPosition: event.startLocation)
                                selection.selecting = true
                            }
                            selection.endPosition = canvasTransform.transform(viewPosition: event.location)
                        }
                        .onEnded {_ in
                            isDragging = false
                            selection.selecting = false
                        }
                    )
                    .popover(isPresented: $showNodeMenu, attachmentAnchor: .point(UnitPoint(x: tapLocation.x / geometry.size.width, y: tapLocation.y / geometry.size.height)), content: { onOpenAddNodeMenu(canvasTransform.transform(viewPosition: tapLocation)).frame(minWidth: 400, maxWidth: 400, idealHeight: 600) })
                    .onAppear() {  simulationRunner.start() }
                    .onDisappear() {  simulationRunner.stop() }
                    .onChange(of: freeEdges, initial: true, {
                        freeEdgesEnvironmentValue = freeEdges.map({ return (edge: $0, $0.getDependencies()) })
                    })
                    .onChange(of: totalZoom, initial: true, {
                        canvasTransform.scale = totalZoom + currentZoom
                        self.updateViewBounds()
                    })
                    .onChange(of: currentZoom, initial: true, {
                        canvasTransform.scale = totalZoom + currentZoom
                        self.updateViewBounds()
                    })
                    .onChange(of: offset, initial: true, {
                        canvasTransform.position = position + offset
                        self.updateViewBounds()
                    })
                    .onChange(of: position, initial: true, {
                        canvasTransform.position = position + offset
                        self.updateViewBounds()
                    })
                    .onChange(of: geometry.size, initial: true, {
                        canvasTransform.viewPortSize = geometry.size
                        self.updateViewBounds()
                    })
                }
            }.inspector(isPresented: $showNodeInspector, content: {
                if selection.selectedNodes.count == 1 {
                    let nodeId  = selection.selectedNodes.first!
                    let node = nodes.first(where: {$0.uuid == nodeId})!
                    let controller = JelloNodeControllerFactory.getController(node)
                    if controller.hasSettings {
                        controller.settingsView(node: node)
                            .background(.ultraThinMaterial)
                            .inspectorColumnWidth(ideal: 500)
                            .toolbar {
                                Spacer()
                                Button {
                                    showNodeInspector.toggle()
                                } label: {
                                    Label("Toggle Inspector", systemImage: "info.circle")
                                }
                            }
                    }
                }
            })
        }
    }
        
}
