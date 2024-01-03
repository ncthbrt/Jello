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
        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                HStack {
                    ArcKnob("R", value: .init(get: {x}, set: { value in nodeData.value = .float4(value, y, z, w) }), range: 0...1.0, foreground: Gradient(colors: [.red]), background: .gray)
                    ArcKnob("G", value: .init(get: {y}, set: { value in nodeData.value = .float4(x, value, z, w) }), range: 0...1.0, foreground: Gradient(colors: [.green]), background: .gray)
                }.contentShape(Rectangle()).gesture(DragGesture())
                HStack {
                    ArcKnob("B", value: .init(get: {z}, set: { value in nodeData.value = .float4(x, y, value, w) }), range: 0...1, foreground: Gradient(colors: [.blue]), background: .gray)
                    ArcKnob("A", value: .init(get: {w}, set: { value in nodeData.value = .float4(x, y, z, value) }), range: 0...1, foreground: Gradient(colors: [.white]), background: .gray)
                }.contentShape(Rectangle()).gesture(DragGesture())
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
