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

    @Environment(\.modelContext) var modelContext
    
    @ViewBuilder var onOpenAddNodeMenu: (CGPoint) -> AddNodeMenu
    
    @State private var showNodeMenu : Bool = false
    @State private var tapLocation: CGPoint = .zero
    @State var scale : CGFloat = 1
    @State var newEdge : JelloEdge? = nil
    
    
    init(graphId: UUID, onOpenAddNodeMenu: @escaping (CGPoint) -> AddNodeMenu) {
        self.graphId = graphId
        _nodes = Query(filter: #Predicate<JelloNode> { node in node.graph.id == graphId })
        _edges = Query(filter: #Predicate<JelloEdge> { edge in edge.graph.id == graphId })
        self.onOpenAddNodeMenu = onOpenAddNodeMenu
    }

    

    var body: some View {
        GeometryReader { geometry  in
            JelloCanvas(scale: $scale){
                ZStack {
                    ForEach(nodes) {
                        node in NodeView(node: node)
                    }
                    ForEach(edges) {
                        edge in EdgeView(edge: edge)
                    }
                }.frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        tapLocation = location
                        showNodeMenu = true
                    }
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .popover(isPresented: $showNodeMenu, attachmentAnchor: .point(UnitPoint(x: tapLocation.x / geometry.size.width, y: tapLocation.y / geometry.size.height)), content: { onOpenAddNodeMenu(tapLocation).frame(minWidth: 400, maxWidth: 400, idealHeight: 600) })
        }
    }
        
}
