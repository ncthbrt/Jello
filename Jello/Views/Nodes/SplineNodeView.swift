//
//  SplineNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation
import SwiftData
import SwiftUI

struct SplineNodeViewImpl : View {
    @Query let splines: [ClampedSpline]
    
    init(splineId: UUID) {
        _splines = Query(FetchDescriptor(predicate: #Predicate<ClampedSpline>{ spline in spline.uuid == splineId }))
    }
    
    var body: some View {
        let spline = splines.first!
        SplineEditor(spline: spline)
    }
}

struct SplineNodeView : View {
    private var node: JelloNode
    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    
    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
    }
    
    var body: some View {
        guard let splineData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .id(let uuid) = splineData.value else {
            return AnyView(EmptyView())
        }
        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                VStack {
                    SplineNodeViewImpl(splineId: uuid)
                }.padding(.horizontal, JelloNode.padding).padding(.bottom, JelloNode.padding)
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
