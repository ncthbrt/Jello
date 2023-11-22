//
//  EdgeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/15.
//

import SwiftUI
import SwiftData
import simd

fileprivate struct RopeView: View {
    let id: UUID
    let start: CGPoint
    let end: CGPoint
    let onEndUnhook: ((DragGesture.Value) -> ())?
    let onEndUnhookEnd: ((DragGesture.Value) -> ())?
    let fill: Gradient

    @ObservedObject var ropeSim: RopeVertletSimulation
    @EnvironmentObject var simulationRunner: SimulationRunner
    
    var body: some View {
        ZStack {
            Path {
                path in
                self.ropeSim.startPosition = vector_float2(start)
                self.ropeSim.endPosition = vector_float2(end)
                self.ropeSim.draw?(&path)
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
        .onAppear() {
            self.ropeSim.setup(start: vector_float2(start), end: vector_float2(end))
        }
        .task {
            await simulationRunner.addSimulation(id: id, sim: ropeSim)
        }.onDisappear() {
            simulationRunner.removeSimulation(id: id)
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
            RopeView(id: edge.id, start: edge.startPosition, end: edge.endPosition, onEndUnhook: { value in
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





