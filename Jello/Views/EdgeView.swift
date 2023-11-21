//
//  EdgeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/15.
//

import SwiftUI
import SwiftData

fileprivate struct Rope: View {
    static let particleCount = 25
    static let constraintIterations = 70

    let start: CGPoint
    let end: CGPoint
    let onEndUnhook: ((DragGesture.Value) -> ())?
    let onEndUnhookEnd: ((DragGesture.Value) -> ())?
    let fill: Gradient

    @ObservedObject var ropeSim: RopeVertletSimulation
    
    var body: some View {
        ZStack {
            Path {
                path in
                self.ropeSim.startPosition = start
                self.ropeSim.endPosition = end
                self.ropeSim.draw(path: &path)
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, miterLimit: 10))
            .fill(fill)
            Circle()
                .fill(fill)
                .shadow(radius: 10)
                .frame(width: 20, height: 20)
                .padding(.all)
                .contentShape(Rectangle())
                .position(end)
                .gesture(DragGesture()
                    .onChanged { change in
                        self.onEndUnhook?(change)
                    }
                    .onEnded { change in
                        self.onEndUnhookEnd?(change)
                    }
                )
            Circle()
                .fill(fill)
                .shadow(radius: 10)
                .frame(width: 20, height: 20)
                .position(start)
                .allowsHitTesting(false)
        }
            .task {
                await self.ropeSim.setup(start: CGPoint(x: start.x, y: start.y), end: CGPoint(x: end.x,y: end.y), particleCount: Rope.particleCount, iterations: Rope.constraintIterations)
                try? await self.ropeSim.loop()
            }
    }
}


struct EdgeView: View {
    var edge: JelloEdge
    @Environment(\.modelContext) var modelContext
    @Environment(\.canvasTransform) var canvasTransform
    @State var ropeSim: RopeVertletSimulation = RopeVertletSimulation()

    
    var body: some View {
        if !edge.isDeleted {
            Rope(start: edge.startPosition, end: edge.endPosition, onEndUnhook: { value in
                edge.setEndPosition(value.location)
            }, onEndUnhookEnd:  { value in
                if edge.inputPort == nil {
                    modelContext.delete(edge)
                }
            }, fill: edge.dataType.getTypeGradient(), ropeSim: ropeSim)
            .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
        }
    }
}





