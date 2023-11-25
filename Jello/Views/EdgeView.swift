//
//  EdgeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/15.
//

import SwiftUI
import SwiftData
import simd


fileprivate struct RopeRendererView: View {
    @ObservedObject var ropeSim: RopeVertletSimulation
    let fill: Gradient

    var body: some View {
        Path {
            path in
            self.ropeSim.draw?(&path)
        }
        .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, miterLimit: 10))
        .fill(fill)
    }
}

fileprivate struct RopeEndView: View {
    let fill: Gradient
    let endPosition: CGPoint
    let onEndUnhook: ((DragGesture.Value) -> ())
    let onEndUnhookEnd: ((DragGesture.Value) -> ())

    var body: some View {
        Circle()
            .fill(fill)
            .shadow(radius: 10)
            .frame(width: 20, height: 20)
            .padding(.all)
            .contentShape(Rectangle())
            .position(endPosition)
            .gesture(DragGesture()
                .onChanged { change in
                    self.onEndUnhook(change)
                }
                .onEnded { change in
                    self.onEndUnhookEnd(change)
                }
            )
    }
}

fileprivate struct RopeStartView: View {
    let fill: Gradient
    let startPosition: CGPoint
    
    var body: some View {
        Circle()
            .fill(fill)
            .shadow(radius: 10)
            .frame(width: 20, height: 20)
            .position(startPosition)
            .allowsHitTesting(false)
    }
}

fileprivate struct RopeView: View {
    let edge: JelloEdge
    let id: UUID
    let onEndUnhook: ((DragGesture.Value) -> ())
    let onEndUnhookEnd: ((DragGesture.Value) -> ())
    let fill: Gradient
    var ropeSim: RopeVertletSimulation
    @EnvironmentObject var simulationRunner: SimulationRunner
    @Environment(\.canvasTransform) var canvasTransform
    
    var body: some View {
        if !edge.isDeleted {
            let size = (edge.startPosition - edge.endPosition)
            
            let thisRect = CGRect(origin: canvasTransform.transform(worldPosition: CGPoint(x: min(edge.startPosition.x, edge.endPosition.x), y: min(edge.startPosition.y, edge.endPosition.y))), size: CGSize(canvasTransform.transform(worldSize: CGPoint(x: abs(size.x), y: abs(size.y)))))
            let canvasRect = CGRect(origin: .zero, size: canvasTransform.viewPortSize)
            if canvasRect.intersects(thisRect) {
                ZStack {
                    RopeRendererView(ropeSim: ropeSim, fill: fill)
                    RopeEndView(fill: fill, endPosition: edge.endPosition, onEndUnhook: onEndUnhook, onEndUnhookEnd: onEndUnhookEnd)
                    RopeStartView(fill: fill, startPosition: edge.startPosition)
                }
                .onAppear() {
                    self.ropeSim.setup(start: vector_float2(edge.startPosition), end: vector_float2(edge.endPosition))
                }
                .onChange(of: edge.startPosition, { _, curr in self.ropeSim.startPosition = vector_float2(curr) })
                .onChange(of: edge.endPosition, { _, curr in self.ropeSim.endPosition = vector_float2(curr) })
                .task {
                    await simulationRunner.addSimulation(id: edge.id, sim: ropeSim)
                    self.ropeSim.startPosition = vector_float2(edge.startPosition)
                    self.ropeSim.endPosition = vector_float2(edge.endPosition)
                }.onDisappear() {
                    simulationRunner.removeSimulation(id: id)
                }
                .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
            }
        }
    }
}


struct EdgeView: View {
    let edge: JelloEdge
    @Environment(\.modelContext) var modelContext
    @State var ropeSim: RopeVertletSimulation = RopeVertletSimulation()

    
    private func onEndUnhook(value: DragGesture.Value) {
        if !edge.isDeleted {
            edge.setEndPosition(value.location)
        }
    }
    
    private func onEndUnhookEnd(value: DragGesture.Value) {
        if !edge.isDeleted && edge.inputPort == nil {
            modelContext.delete(edge)
        }
    }
    
    var body: some View {
        if !edge.isDeleted {
            RopeView(edge: edge, id: edge.id, onEndUnhook: onEndUnhook, onEndUnhookEnd: onEndUnhookEnd, fill: edge.dataType.getTypeGradient(), ropeSim: ropeSim)
        }
    }
}





