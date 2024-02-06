//
//  ClampedSplineEditor.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/29.
//

import SwiftUI
import SwiftData
import Foundation


struct SplineEditorControlPoint : View {
    let i: Int
    let controlPoint: ClampedSplineControlPoint
    let selection: Int?
    var spline: ClampedSpline
    let size: CGSize
    let onSelected: (Bool) -> ()
    @State var dragStartLocation: ClampedSplinePoint? = nil

    func getColor() -> Color {
        switch controlPoint.type {
        case .aligned:
            .green
        case .flat:
            .orange
        case .broken:
            .teal
        }
    }
    
    var body: some View {
        if spline.controlPoints.count > 0, i < spline.controlPoints.count {
            ZStack {
                let prevControlPoint = i > 0 ? spline.controlPoints[i-1] : nil
                let nextControlPoint = i < spline.controlPoints.count - 1 ? spline.controlPoints[i+1] : nil
                let startPosition = CGPoint(x: CGFloat(controlPoint.position.x), y: CGFloat(1.0 - controlPoint.position.y)) * CGPoint(size)
                let controlPoint = ClampedSpline.clampTangents(prevControlPoint: prevControlPoint, controlPoint: controlPoint, nextControlPoint: nextControlPoint)
                let fill = getColor()
                if controlPoint.type == .aligned || controlPoint.type == .broken {
                    if selection == i {
                        if let startTangent = controlPoint.startTangent  {
                            let dx = (controlPoint.position.x - spline.controlPoints[i - 1].position.x)
                            let handleEndPosition = if let weight = startTangent.weight {
                                startPosition - (((CGPoint(size) * CGFloat(dx * weight))) * CGPoint(x: 1.0, y: -CGFloat(startTangent.gradient)))
                            } else {
                                startPosition - CGPoint(x: 1, y: size.height / size.width) * 50 * CGPoint(x: 1.0, y: -CGFloat(startTangent.gradient))
                            }
                            Path { p
                                in p.move(to: startPosition)
                                p.addLine(to: handleEndPosition)
                            }.stroke(lineWidth: 2).fill(fill)
                            Circle().fill(fill).frame(width: 10, height: 10).position(handleEndPosition).gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                                event in
                                if dragStartLocation == nil {
                                    dragStartLocation = ClampedSplinePoint(x: Float(handleEndPosition.x), y: Float(size.height - handleEndPosition.y))
                                }
                                let dragEndPosition = dragStartLocation! + ClampedSplinePoint(x: Float(event.translation.width), y: Float(-event.translation.height))
                                var delta = dragEndPosition - ClampedSplinePoint(x: Float(startPosition.x), y: Float(size.height - startPosition.y))
                                delta = ClampedSplinePoint(x: min(-0.001, delta.x), y: delta.y)
                                let unitOffset = delta / ClampedSplinePoint(size) / dx
                                
                                let startTangent = ClampedSpline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: -1 * unitOffset, dx: -dx, clamp: true)
                                var endTangent: ClampedSplineTangent? = controlPoint.endTangent
                                if controlPoint.type == .aligned, let e = controlPoint.endTangent {
                                    let nextControlPoint = spline.controlPoints[i + 1]
                                    let prevOffset = ClampedSpline.tangentToUnitOffset(tangent: e, startTangent: false)
                                    let dx = nextControlPoint.position.x - controlPoint.position.x
                                    let offset = ClampedSplinePoint(x: 1, y: startTangent.gradient).setMagnitude(factor: prevOffset.magnitude())
                                    endTangent = ClampedSpline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: offset, dx: dx, clamp: true)
                                }
                                let next = ClampedSplineControlPoint(type: controlPoint.type, position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
                                let type = spline.getType(controlPoint: next)
                                if type == .flat {
                                    dragStartLocation = nil
                                }
                                spline.controlPoints[i] = ClampedSplineControlPoint(type: type, position: next.position, startTangent: next.startTangent, endTangent: next.endTangent)
                            }).onEnded({ _ in
                                dragStartLocation = nil
                            }))
                        }
                        if let endTangent = controlPoint.endTangent  {
                            let dx = (spline.controlPoints[i + 1].position.x - controlPoint.position.x)
                            let handleEndPosition = if let weight = endTangent.weight {
                                startPosition + ((CGPoint(size) * CGFloat(dx * weight)) * CGPoint(x: 1.0, y: -CGFloat(endTangent.gradient)))
                            } else {
                                startPosition + CGPoint(x: 1, y: size.height / size.width) * 50 * CGPoint(x: 1.0, y: -CGFloat(endTangent.gradient))
                            }
                            Path { p
                                in p.move(to: startPosition)
                                p.addLine(to: handleEndPosition)
                            }.stroke(lineWidth: 1).fill(fill)
                            ZStack {
                                Circle().fill(fill).frame(width: 10, height: 10)
                            }.frame(width: 20, height: 20).contentShape(Circle()).position(handleEndPosition).gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                                event in
                                if dragStartLocation == nil {
                                    dragStartLocation = ClampedSplinePoint(x: Float(handleEndPosition.x), y: Float(size.height - handleEndPosition.y))
                                }
                                let dragEndPosition = dragStartLocation! + ClampedSplinePoint(x: Float(event.translation.width), y: Float(-event.translation.height))
                                var delta = dragEndPosition - ClampedSplinePoint(x: Float(startPosition.x), y: Float(size.height - startPosition.y))
                                delta = ClampedSplinePoint(x: max(0.001, delta.x), y: delta.y)
                                let unitOffset = delta / ClampedSplinePoint(size) / dx
                                
                                let endTangent = ClampedSpline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: unitOffset, dx: dx, clamp: true)
                                var startTangent: ClampedSplineTangent? = controlPoint.startTangent
                                
                                if controlPoint.type == .aligned, let s = controlPoint.startTangent {
                                    let prevControlPoint = spline.controlPoints[i - 1]
                                    let prevOffset = ClampedSpline.tangentToUnitOffset(tangent: s, startTangent: true)
                                    let dx = controlPoint.position.x - prevControlPoint.position.x
                                    let offset = ClampedSplinePoint(x: 1, y: endTangent.gradient).setMagnitude(factor: prevOffset.magnitude())
                                    startTangent = ClampedSpline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: offset, dx: -dx, clamp: true)
                                }
                                
                                let next = ClampedSplineControlPoint(type: controlPoint.type, position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
                                let type = spline.getType(controlPoint: next)
                                if type == .flat {
                                    dragStartLocation = nil
                                }
                                spline.controlPoints[i] = ClampedSplineControlPoint(type: type, position: next.position, startTangent: next.startTangent, endTangent: next.endTangent)
                            }).onEnded({ _ in
                                dragStartLocation = nil
                            }))
                        }
                    }
                }
                Rectangle().fill(fill).frame(width: 12, height: 12).shadow(color: selection == i ? .white: .black, radius: 4).contentShape(Rectangle()).position(startPosition)
                    .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .local)
                        .onChanged({ event in
                            if dragStartLocation == nil {
                                dragStartLocation = controlPoint.position
                            }
                            var position: ClampedSplinePoint = ClampedSplinePoint(event.translation) / ClampedSplinePoint(size)
                            position = ClampedSplinePoint(x: max(0, min(1, dragStartLocation!.x + position.x)), y: min(1, max(0, dragStartLocation!.y - position.y)))
                            if i == 0 {
                                position = ClampedSplinePoint(x: 0, y: position.y)
                            } else if i == spline.controlPoints.count - 1 {
                                position = ClampedSplinePoint(x: 1, y: position.y)
                            } else {
                                let prev = spline.controlPoints[i-1]
                                let next = spline.controlPoints[i+1]
                                position = ClampedSplinePoint(x: min(max(prev.position.x, position.x), next.position.x), y: position.y)
                            }
                            var type = controlPoint.type
                            let next = ClampedSpline.clampTangents(prevControlPoint: prevControlPoint, controlPoint: ClampedSplineControlPoint(type: controlPoint.type, position: position, startTangent: controlPoint.startTangent, endTangent: controlPoint.endTangent), nextControlPoint: nextControlPoint)
                            type = spline.getType(controlPoint: next)
                            spline.controlPoints[i] =  ClampedSplineControlPoint(type: type, position: next.position, startTangent: next.startTangent, endTangent: next.endTangent)
                        }).onEnded({ _ in
                            dragStartLocation = nil
                        })
                    )
                    .onTapGesture(count: 2, perform: {
                        if i != 0 && i != spline.controlPoints.count - 1 {
                            onSelected(false)
                            spline.controlPoints.remove(at: i)
                        }
                    })
                    .onTapGesture {
                        onSelected(true)
                    }.animation(.easeIn.speed(3), value: selection == i)
            }
        }
    }
}

struct SplineAxis : View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            Path({ path in
                path.move(to: .init(x: 0, y: size.height))
                path.addLine(to: .init(x: 0, y: 0))
            }).stroke(lineWidth: 3)
            Rectangle().fill(.white).frame(width: 12, height: 12).position(.init(x: 0, y: 0))
            Rectangle().fill(.white).frame(width: 12, height: 12).position(.init(x: size.width, y: size.height))
            Text("value").italic().monospaced().rotationEffect(.degrees(-90)).position(.init(x: -20, y: size.height / 2))
            Text("time").italic().monospaced().position(.init(x: size.width / 2, y: size.height + 20))
            Path({ path in
                path.move(to: .init(x: 0, y: size.height))
                path.addLine(to: .init(x: size.width, y: size.height))
            }).stroke(lineWidth: 3)
        }.allowsHitTesting(false)
        
    }
}



struct SplineControlPointTypeRadioGroup: View {
    @Binding var selection: ClampedSplineControlPointType
    var body: some View {
        HStack {
            JelloRadioButtonHGroup(entries: ClampedSplineControlPointType.allCases, currentSelection: $selection, label: { entry in
                let str = "\(entry)"
                Text(str).monospaced().font(.caption)
            },
                                   fill: { entry in
                switch entry {
                case ClampedSplineControlPointType.aligned:
                    return Gradient(colors: [.green, .cyan])
                case ClampedSplineControlPointType.broken:
                    return Gradient(colors: [.teal, .blue])
                case ClampedSplineControlPointType.flat:
                    return Gradient(colors: [.orange, .red])
                }
            })
        }.frame(height: 25)
    }
}


struct SplineFavouriteButton: View {
    let selected: Bool
    let controlPoints: [ClampedSplineControlPoint]
    let action: () -> ()
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().stroke(lineWidth: 1).fill(.gray)
            Path({ path in drawPath(path: &path, size: CGPoint(geometry.size), controlPoints: controlPoints) }).stroke(lineWidth: 2).fill(selected ? .green : .red)
        }.contentShape(Rectangle()).onTapGesture {
            action()
        }
    }
}

struct SplineOptionsView: View {
    var spline: ClampedSpline
    let currentSelection: Int?
    @Environment(\.modelContext) var modelContext
    @Query(sort: \FavouriteClampedSpline.dateAdded, order: .reverse, animation: .spring) var favourites: [FavouriteClampedSpline]
    

    var body: some View {
        let favourites = favourites[0..<min(4, favourites.count)]
        ZStack {
            if let currentSelection = self.currentSelection, currentSelection < spline.controlPoints.count {
                HStack {
                    let controlPoint =  spline.controlPoints[currentSelection]
                    Text("p\(currentSelection): (\(String(format: "%1.3f" , controlPoint.position.x)), \(String(format: "%1.3f" , controlPoint.position.y)))").monospaced().italic().lineLimit(1).minimumScaleFactor(0.2).padding(.bottom, 4)
                    Spacer(minLength: 30)
                    SplineControlPointTypeRadioGroup(selection: .init(get: { controlPoint.type }, set: { value in
                        spline.setType(type: value, i: currentSelection)
                    }))
                }.transition(.asymmetric(insertion: .push(from: .top).animation(.spring), removal: .push(from: .bottom).animation(.spring))).frame(height: 35)
            } else {
                HStack {
                    ForEach(favourites) { item in
                        SplineFavouriteButton(selected: item.controlPoints == spline.controlPoints, controlPoints: item.controlPoints, action: {
                            spline.controlPoints = item.controlPoints
                        }).frame(width: 75, height: 50)
                    }
                    Spacer(minLength: 200)
                    FavouriteButton(isFavourite: .init(get: { favourites.contains(where: { $0.controlPoints == spline.controlPoints }) }, set: { value in
                        if !value {
                            if let favourite = favourites.first(where: { $0.controlPoints == spline.controlPoints }) {
                                modelContext.delete(favourite)
                            }
                        } else {
                            modelContext.insert(FavouriteClampedSpline(uuid: UUID(), controlPoints: spline.controlPoints, dateAdded: .now))
                        }
                    })).frame(width: 50, height: 50)
                }.transition(.opacity)
            }
        }.frame(height: 50).padding(.vertical, 6).offset(y: 20).animation(.spring, value: currentSelection)
    }
}


func drawPath(path: inout Path, size: CGPoint, controlPoints: [ClampedSplineControlPoint]) {
    path.move(to: CGPoint(x: 0, y: size.y * CGFloat(1 - controlPoints[0].position.y)))
    for i in 1..<controlPoints.count {
        let prevControlPoint = controlPoints[i-1]
        let thisControlPoint = controlPoints[i]
        let fromPos = size * CGPoint(x: CGFloat(prevControlPoint.position.x), y: 1 - CGFloat(prevControlPoint.position.y))
        let toPos = size * CGPoint(x: CGFloat(thisControlPoint.position.x), y: 1 - CGFloat(thisControlPoint.position.y))
        var endTangentOffset = ClampedSpline.tangentToUnitOffset(tangent: prevControlPoint.endTangent!, startTangent: false)
        endTangentOffset = ClampedSplinePoint(x: endTangentOffset.x, y: -endTangentOffset.y)
        var startTangentOffset = ClampedSpline.tangentToUnitOffset(tangent: thisControlPoint.startTangent!, startTangent: true)
        startTangentOffset = ClampedSplinePoint(x: startTangentOffset.x, y:  -startTangentOffset.y)
        let delta = CGFloat(thisControlPoint.position.x - prevControlPoint.position.x)
        var startCGOffset = CGPoint(startTangentOffset) * size * delta
        var endCGOffset = CGPoint(endTangentOffset) * size * delta
        if startCGOffset.magnitude() < 1 {
            startCGOffset = .zero
        }
        if endCGOffset.magnitude() < 1 {
            endCGOffset = .zero
        }
        path.addCurve(to: toPos, control1: fromPos + endCGOffset, control2: toPos + startCGOffset)
    }
}



struct SplineEditor: View {
    @Bindable var spline: ClampedSpline
    @State var currentSelection: Int? = nil
    
    var body: some View {
        HStack {
            VStack {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle().fill(.black).frame(width: geometry.size.width, height: geometry.size.height).padding(0).colorEffect(ShaderLibrary.gridEffect(.color(.gray.opacity(0.4)), .float(1.0/25.0), .float(1.0/25.0), .float(0.05), .float(0.05))).allowsHitTesting(false)
                        SplineAxis(size: geometry.size)
                        Path {
                            path in drawPath(path: &path, size: CGPoint(geometry.size), controlPoints: spline.controlPoints)
                        }.stroke(Gradient(colors: [.red, .blue]), style: StrokeStyle(lineWidth: 5, lineCap: .butt, lineJoin: .bevel))
                        ForEach(spline.controlPoints.indices, id: \.self) { i in
                            SplineEditorControlPoint(i: i, controlPoint: spline.controlPoints[i], selection: currentSelection, spline: spline, size: geometry.size, onSelected: { selected in
                                currentSelection = selected ? i : ((i == currentSelection || currentSelection == nil) ? nil: min(currentSelection!, spline.controlPoints.count - 1))
                            })
                        }
                    }.contentShape(Rectangle()).gesture(SpatialTapGesture(count: 2).onEnded({ event in
                        let x = Float(event.location.x / geometry.size.width)
                        let (t, dist) = spline.distanceFromCurve(x: x, y: Float(1 - event.location.y / geometry.size.height))
                        if t < 1.0 && dist * Float(geometry.size.height) < 25 {
                            spline.subdivideCurve(x: x, t: t)
                        }
                        currentSelection = nil
                    })).onTapGesture {
                        currentSelection = nil
                    }
                }.padding(12)
                SplineOptionsView(spline: spline, currentSelection: currentSelection).modelContainer(for: FavouriteClampedSpline.self)
            }
        }
    }
    
}

struct SplineEditorPreview: View {
    @State var spline: ClampedSpline = ClampedSpline()
    
    var body: some View {
        VStack {
            SplineEditor(spline: spline).frame(width: 500, height: 350)
        }
    }
}


#Preview {
    SplineEditorPreview().modelContainer(for: FavouriteClampedSpline.self, inMemory: true)
}
