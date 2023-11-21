//
//  GraphView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/10.
//

import SwiftUI
import SwiftData

struct GraphView<AddNodeMenu: View> : View {
    let graphId : UUID
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var freeEdges: [JelloEdge]

    @Environment(\.modelContext) var modelContext
    
    @ViewBuilder var onOpenAddNodeMenu: (CGPoint) -> AddNodeMenu
    
    @State private var showNodeMenu : Bool = false
    @State private var tapLocation: CGPoint = .zero
    @State var scale : CGFloat = 1
    @State var newEdge : JelloEdge? = nil
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    @State private var position: CGPoint = .zero
    @State private var offset: CGPoint = .zero
    @State private var isDragging = false
    @State private var selection: BoxSelection = BoxSelection()
    let maxZoom: CGFloat = CGFloat(4)
    let minZoom: CGFloat = CGFloat(0.1)
    
    
    init(graphId: UUID, onOpenAddNodeMenu: @escaping (CGPoint) -> AddNodeMenu) {
        self.graphId = graphId
        _nodes = Query(filter: #Predicate<JelloNode> { node in node.graph?.id == graphId })
        _edges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.id == graphId })
        _freeEdges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph?.id == graphId && edge.inputPort == nil })
        self.onOpenAddNodeMenu = onOpenAddNodeMenu
    }

    

    var body: some View {
        GeometryReader { geometry in
            let canvasTransform = CanvasTransform(scale: currentZoom+totalZoom, position: position + offset)
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
                        .freeEdges(freeEdges.map({ return (edge: $0, $0.getDependencies()) }))
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
            }
        }
    }
        
}
