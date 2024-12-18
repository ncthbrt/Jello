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
        TimelineView(.animation) { context in
            Path {
                path in
                self.ropeSim.doDraw(path: &path)
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, miterLimit: 10))
            .fill(fill)
        }
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
                .onChanged(onEndUnhook)
                .onEnded(onEndUnhookEnd)
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
    let fill: Gradient
    var ropeSim: RopeVertletSimulation
    @EnvironmentObject var simulationRunner: SimulationRunner
    @Environment(\.canvasTransform) var canvasTransform
    @Environment(\.modelContext) var modelContext
    @State var uuid: UUID = UUID()
    
    private func onEndUnhook(value: DragGesture.Value) {
        if !edge.isDeleted {
            edge.endPosition = value.location
        }
    }
    
    private func onEndUnhookEnd(value: DragGesture.Value) {
        if !edge.isDeleted && edge.inputPort == nil {
            modelContext.delete(edge)
        }
    }
    
    var body: some View {
        if !edge.isDeleted {
            let startPosition = edge.startPosition
            let endPosition = edge.endPosition
            ZStack {
                RopeRendererView(ropeSim: ropeSim, fill: fill)
                RopeEndView(fill: fill, endPosition: endPosition, onEndUnhook: onEndUnhook, onEndUnhookEnd: onEndUnhookEnd)
                RopeStartView(fill: fill, startPosition: startPosition)
            }
            .onAppear() {
                self.ropeSim.setup(start: vector_float2(startPosition), end: vector_float2(endPosition))
            }
            .onChange(of: startPosition, initial: true, { _, curr in self.ropeSim.startPosition = vector_float2(curr) })
            .onChange(of: endPosition, initial: true, { _, curr in self.ropeSim.endPosition = vector_float2(curr) })
            .task {
                await simulationRunner.addSimulation(id: uuid, sim: ropeSim)
                self.ropeSim.startPosition = vector_float2(startPosition)
                self.ropeSim.endPosition = vector_float2(endPosition)
            }.onDisappear() {
                simulationRunner.removeSimulation(id: uuid)
            }
            .offset(CGSize(width: canvasTransform.position.x, height: canvasTransform.position.y))
        }
    }
}


struct EdgeView: View {
    let edge: JelloEdge
    @StateObject var ropeSim: RopeVertletSimulation = RopeVertletSimulation()

    var body: some View {
        if !edge.isDeleted {
            RopeView(edge: edge, fill: edge.dataType.getTypeGradient(), ropeSim: ropeSim)
        }
    }
}





