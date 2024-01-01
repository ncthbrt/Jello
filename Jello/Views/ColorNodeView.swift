//
//  ColorNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/01.
//

import Foundation
import SwiftUI
import SwiftData

struct ColorNodeView : View {
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
        guard let nodeData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .float4(let x, let y, let z, let w) = nodeData.value else {
            return AnyView(EmptyView())
        }
        let backgroundColor = Color(red: Double(x), green: Double(y), blue: Double(z), opacity: Double(w))
        return AnyView(ZStack {
            Path(self.drawBounds).background(backgroundColor)
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
