//
//  RadialMenu.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/25.
//
import Foundation
import SwiftUI


struct RadialLayout: Layout {
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let containerHeight = proposal.replacingUnspecifiedDimensions().height
        return .init(width: containerWidth, height: containerHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let containerHeight = proposal.replacingUnspecifiedDimensions().height
        let minDimension = min(containerWidth, containerHeight)
        let radius: Double = minDimension / 2.0
        let deltaAngle: Double = (2.0 * .pi) / Double(subviews.count)
        for (index, subview) in subviews.enumerated() {
            // Find a vector with an appropriate size and rotation.
            var point = CGPoint(x: radius, y: 0)
                .applying(CGAffineTransform(
                    rotationAngle: deltaAngle * (Double(index))))


            // Shift the vector to the middle of the region.
            point.x += bounds.midX
            point.y += bounds.midY


            // Place the subview.
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
    
}



struct RadialOption: View {
    let count: Int
    let index: Int
    var body: some View {
        let deltaAngle = 2 * .pi / Double(count)
        let halfDeltaAngle = deltaAngle / 2
        let offset: Angle = .radians(deltaAngle * Double(index))
        let startAngle  = offset - .radians(halfDeltaAngle)
        let endAngle = offset + .radians(halfDeltaAngle)
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            Path({ p in
                let mid: CGPoint = .init(x: frame.midX, y: frame.midY)
                p.addArc(center: mid, radius: 50, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                p.addArc(center: mid, radius: 100, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                
            }).fill(.white.opacity(0.4))
        }
    }
}



struct RadialMenu<Label, Entry, EntryView>: View where Label : View, Entry: Hashable, EntryView: View {
    @ViewBuilder let label: () -> Label
    let entries: [Entry]
    @ViewBuilder let entryBuilder: (Entry) -> EntryView
    let onSelection: (Entry) -> ()
    let onOpen: () -> ()
    let onClose: () -> ()
    @State var isMenuVisible: Bool = false
    @State var selection: Int? = nil
    
    
    
    var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: .infinity).fill(.thickMaterial).shadow(radius: -4).allowsHitTesting(false)
                label()
                    .foregroundStyle(.white)
            }.frame(width: 50, height: 50)
                .overlay(alignment: .center) {
                        if isMenuVisible {
                            ZStack {
                                Circle().fill(.black).frame(width: 50, height: 50)
                                Circle().fill(.ultraThinMaterial)
                                if let i = selection {
                                    RadialOption(count: entries.count, index: i).allowsHitTesting(false).transition(.opacity.animation(.interactiveSpring))
                                }
                                RadialLayout {
                                    ForEach(entries, id: \.self, content: entryBuilder)
                                }.padding(30).allowsHitTesting(false)
                            }.padding(0).frame(width: 200, height: 200).transition(
                                .scale.animation(.interactiveSpring).combined(with: .opacity.animation(.easeOut))
                            )
                        }
                        if isMenuVisible {
                            label()
                                .foregroundStyle(.white)
                        }
                }.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged({ event in
                        if isMenuVisible == false {
                            withAnimation(.spring) {
                                isMenuVisible = true
                                onOpen()
                            }
                        }
                        updateSelection(location: event.location)
                        
                    })
                        .onEnded({ event in
                            withAnimation(.spring) {
                                isMenuVisible = false
                                onClose()
                            }
                            updateSelection(location: event.location)
                            endSelection()
                        })
                )
        }
    
    func updateSelection(location: CGPoint){
        let mag = location.magnitude()
        let dir = location / mag
        let angle = atan2(dir.x, -dir.y) - .pi / 2
        if mag > 40 {
            selection = (Int(round(angle / (2 * .pi) * Double(entries.count))) + entries.count) % entries.count
        } else {
            selection = nil
        }
    }
    
    func endSelection(){
        if let selection = self.selection {
            print(selection)
            onSelection(entries[selection])
        }
    }
}
