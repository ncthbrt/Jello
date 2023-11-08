//
//  NodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import SwiftUI
import OrderedCollections

struct NodeRendererView: View {
    let name: String
//    let node: Node
//    @ObservedObject var graph: Graph
    let selected: Bool
    
    @State var lastTranslation: CGSize = .zero
    @State var dragStarted: Bool = false
    @Binding var position: CGPoint
    @State var dragPosition: CGPoint = .zero
    @ObservedObject var sim: JellyBoxVertletSimulation

 
    var body: some View {
            ZStack {
                if (sim.renderVertlets.count > 0) {
                    Path {
                        path in
                        path.move(to: sim.renderVertlets[0].position - position)
                        for i in 1..<sim.renderVertlets.count {
                            path.addLine(to: sim.renderVertlets[i].position - position)
                        }
                    }
                    .fill(Gradient(colors: [.green, .blue]))

                    Path {
                        path in
                        path.move(to: sim.renderVertlets[0].position - position)
                        for i in 1..<sim.renderVertlets.count {
                            path.addLine(to: sim.renderVertlets[i].position - position)
                        }
                    }
                     .fill(.ultraThickMaterial)
                     .stroke(Gradient(colors: [.green, .blue]), lineWidth: 4, antialiased: true)
                }
                VStack {
                    Text(name).font(.title2)
                        .bold()
                        .monospaced()
                    Spacer()
                }
                .padding(.all, 20)
            }
            .animation(.interactiveSpring(), value: position)
            .frame(width: 200, height:  200, alignment: .center)
            .contextMenu {
                Button {
                    // Add this item to a list of favorites.
                } label: {
                    Label("Pin Preview", systemImage: "eye")
                }
                Button(role: .destructive) {
                    // Add this item to a list of favorites.
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                Button(role: .destructive) {
                    // Open Maps and center it on this item.
                } label: {
                    Label("Dissolve", systemImage: "wand.and.rays")
                }
            }
            .position(position)
            .onAppear {
                self.sim.setup(dimensions: CGPoint(x: 200, y: 200), topLeft: position, particleDensity: 50, constraintIterations: 4, updateIterations: 4)
                self.sim.startUpdate()
            }
            .onDisappear {
                self.sim.stopUpdate()
            }
            .onChange(of: position, { _, next in
                sim.topLeft = next
            })
//            .shadow(color: .orange.opacity(0.6), radius: 5)
//            .animation(.spring(response: 0.15, dampingFraction: 0.4), value: position)
            .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
                return newValue ? .start : .stop
            }
             .gesture(DragGesture()
                               .onChanged { dragGesture in
                                       sim.dragging = true
                                       dragStarted = true
                                       let delta = CGPoint(x: dragGesture.translation.width - lastTranslation.width, y: dragGesture.translation.height - lastTranslation.height)
                                       position = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                                       sim.topLeft = position
                                       sim.dragPosition = dragGesture.location
                                       lastTranslation = dragGesture.translation
                                   }.onEnded {_ in
                                       lastTranslation = .zero
                                       dragStarted = false
                                       sim.dragPosition = position
                                       sim.dragging = false
                                   }
                           )
            
        }
}

struct NodeView : View {
    @State var position: CGPoint = CGPoint(x: 500, y: 500)
    @State var sim : JellyBoxVertletSimulation = JellyBoxVertletSimulation()
    
    var body: some View {
        NodeRendererView(name: "Frog", selected: false, position: $position, sim: sim)
    }
}

#Preview {
    ZStack {
        NodeView()
    }.frame(width: 1000, height: 1000)
}
