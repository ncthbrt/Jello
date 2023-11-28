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
    
    @State private var showNodeMenu : Bool = false
    @State private var tapLocation: CGPoint = .zero
    @State private var scale : CGFloat = 1
    @State private var newEdge : JelloEdge? = nil
    @State private var simulationRunner: SimulationRunner = SimulationRunner()
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
        _nodes = Query(filter: #Predicate<JelloNode> { node in node.graph?.uuid == graphId && (minX <= node.maxX && node.minX <= maxX) && (minY <= node.maxY && node.minY <= maxY) })
        _edges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.uuid == graphId })
        _freeEdges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.uuid == graphId && edge.inputPort == nil })
    }
    
    func updateViewBounds(){
        let transformedSize = canvasTransform.transform(viewSize: CGPoint(x: canvasTransform.viewPortSize.width, y: canvasTransform.viewPortSize.height))
        let transformedPosition = canvasTransform.position
        viewBounds = CGRect(origin: transformedPosition, size: CGSize(width: transformedSize.x, height: transformedSize.y))
    }


    var body: some View {
        GeometryReader { geometry in
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
                                NodeView(node: node)
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
        }
    }
        
}


//struct GraphWrapperView<Menu: View> : View {
//    let graphId: UUID
//
//    var onOpenAddNodeMenu: (CGPoint) -> Menu
//    
//    init(graphId: UUID, onOpenAddNodeMenu:  @escaping (CGPoint) -> Menu) {
//        self.graphId = graphId
//        self.onOpenAddNodeMenu = onOpenAddNodeMenu
//    }
//    
//    
//    var body: some View {
//        GraphView<Menu>(graphId: graphId, onOpenAddNodeMenu: onOpenAddNodeMenu, viewBounds: $viewBounds)
//    }
//    
//}
