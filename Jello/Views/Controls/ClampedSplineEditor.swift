//
//  ClampedSplineEditor.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/29.
//

import SwiftUI
import SwiftData

@Observable
class ClampedSpline {
    var controlPoints: [ClampedSplineControlPoint]
    
    init(controlPoints: [ClampedSplineControlPoint]) {
        self.controlPoints = controlPoints
    }
    
    convenience init() {
        self.init(controlPoints: [ClampedSplineControlPoint(type: .broken, position: .init(x: 0, y: 0), startTangent: nil, endTangent: ClampedSplineTangent(gradient: 1, weight: nil)),  ClampedSplineControlPoint(type: .broken, position: .init(x: 1, y: 1), startTangent: ClampedSplineTangent(gradient: 1, weight: nil), endTangent: nil)])
    }
    
    func distanceFromCurve(x: Float, y: Float) -> (t: Float, distance: Float){
        for i in 0..<(controlPoints.count-1) {
            let thisControlPoint = controlPoints[i]
            let nextControlPoint = controlPoints[i+1]
            if x > thisControlPoint.position.x && x < nextControlPoint.position.x {
                let t = tFromX(thisControlPoint: thisControlPoint, nextControlPoint: nextControlPoint, x: x)
                let t2 = 1.0 - t
                
                let thisY = 3 * t2 * t2 * t * (thisControlPoint.endTangent!.weight ?? 1/3.0) * thisControlPoint.endTangent!.gradient + 3 * t2 * t * t * (1 - (nextControlPoint.startTangent!.weight ?? 1/3.0) * nextControlPoint.startTangent!.gradient) + t * t * t
                let dy = nextControlPoint.position.y - thisControlPoint.position.y;

                return (t: t, distance: abs(y - (thisY * dy + thisControlPoint.position.y)))
            }
        }
        return (t: 1, abs(1 - y))
    }
    
    func getType(controlPoint: ClampedSplineControlPoint) -> ClampedSplineControlPointType {
        let type = controlPoint.type
        let sWeight = controlPoint.startTangent == nil ? 0 : (controlPoint.startTangent?.weight ?? 1/3)
        let eWeight = controlPoint.endTangent == nil ? 0 : (controlPoint.endTangent?.weight ?? 1/3)
        if sWeight < 0.01 && eWeight < 0.01 {
            return .flat
        } else if sWeight < 0.01 || eWeight < 0.01 {
            return .broken
        }
        return type
    }
    
    func subdivideCurve(x: Float, t: Float) {
        for i in 0..<(controlPoints.count-1) {
            let thisControlPoint = controlPoints[i]
            let nextControlPoint = controlPoints[i+1]
            if x > thisControlPoint.position.x && x < nextControlPoint.position.x {
                let dx = (nextControlPoint.position.x - thisControlPoint.position.x)
                let endTangentOffset = dx * ClampedSpline.tangentToUnitOffset(tangent: thisControlPoint.endTangent!, startTangent: false)
                let startTangentOffset = dx * ClampedSpline.tangentToUnitOffset(tangent: nextControlPoint.startTangent!, startTangent: true)
                
                let p0 = thisControlPoint.position
                let p1 = thisControlPoint.position + endTangentOffset
                let p2 = nextControlPoint.position + startTangentOffset
                let p3 = nextControlPoint.position
                
                let a = p0 + (p1 - p0) * t
                let b = p1 + (p2 - p1) * t
                let c = p2 + (p3 - p2) * t
                let d = a + (b - a) * t
                let e = b + (c - b) * t
                let p = d + (e - d) * t
                
                let gradientA = (a.y - p0.y) / (a.x - p0.x)
                let gradientD = (p.y - d.y) / (p.x - d.x)
                let gradientE = (e.y - p.y) / (e.x - p.x)
                let gradientC = (c.y - p3.y) / (c.x - p3.x)
                
                let weightA: Float = max(0, min(1, abs((a.x - p0.x) / (p.x - p0.x))))
                let weightD: Float = max(0, min(1, abs((d.x - p.x) / (p.x - p0.x))))
                let weightE: Float = max(0, min(1, abs((e.x - p.x) / (p3.x - p.x))))
                let weightC: Float = max(0, min(1, abs((c.x - p3.x) / (p3.x - p.x))))
                
                controlPoints[i] = ClampedSplineControlPoint(type: thisControlPoint.type, position: p0, startTangent: thisControlPoint.startTangent, endTangent: ClampedSplineTangent(gradient: gradientA, weight: weightA))
                let midType: ClampedSplineControlPointType = weightE < 2 * Float.ulpOfOne && weightD < 2 * Float.ulpOfOne ? .flat : .aligned
                controlPoints.insert(ClampedSplineControlPoint(type: midType, position: p, startTangent: ClampedSplineTangent(gradient: gradientD, weight: weightD), endTangent: ClampedSplineTangent(gradient: gradientE, weight: weightE)), at: i+1)
                controlPoints[i+2] = ClampedSplineControlPoint(type: nextControlPoint.type, position: p3, startTangent: ClampedSplineTangent(gradient: gradientC, weight: weightC), endTangent: nextControlPoint.endTangent)
                break
            }
        }
    }
    
    static func tangentToUnitOffset(tangent: ClampedSplineTangent, startTangent: Bool) -> ClampedSplinePoint {
        let sign: Float = startTangent ? -1 : 1
        if let weight = tangent.weight {
            return ClampedSplinePoint(x: sign * weight, y: sign * tangent.gradient * weight)
        }
        return ClampedSplinePoint(x: sign * 1/3.0, y: sign * tangent.gradient * 1.0/3.0)
    }
    
    static func unitOffsetToTangent(controlPointPosition: ClampedSplinePoint, offset: ClampedSplinePoint, dx: Float, clamp: Bool = false) -> ClampedSplineTangent {
        let gradient = offset.y / offset.x
        let globalOffset = offset * dx
        let pos = controlPointPosition + globalOffset
        
        if clamp, pos.y > 1 {
            let yHeight = (1 - controlPointPosition.y)
            let weight = yHeight / gradient / dx
            return ClampedSplineTangent(gradient: gradient, weight: weight)
        } else if clamp, pos.y < 0 {
            let yHeight = (0 - controlPointPosition.y)
            let weight = yHeight / gradient / dx
            return ClampedSplineTangent(gradient: gradient, weight: weight)
        } else {
            let weight: Float = offset.x
            return ClampedSplineTangent(gradient: gradient, weight: weight)
        }
    }
    
    static func clampTangents(prevControlPoint: ClampedSplineControlPoint?, controlPoint: ClampedSplineControlPoint, nextControlPoint: ClampedSplineControlPoint?) -> ClampedSplineControlPoint {
        var startTangent: ClampedSplineTangent? = nil
        var endTangent: ClampedSplineTangent? = nil
        if let prev = prevControlPoint, let start = controlPoint.startTangent {
            let offset = tangentToUnitOffset(tangent: start, startTangent: true)
            let dx = controlPoint.position.x - prev.position.x
            startTangent = unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: -1 * offset, dx: -dx, clamp: true)
        }
        
        if let next = nextControlPoint, let end = controlPoint.endTangent {
            let offset = tangentToUnitOffset(tangent: end, startTangent: false)
            let dx = next.position.x - controlPoint.position.x
            endTangent = unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: offset, dx: dx, clamp: true)
        }
        
        
        return ClampedSplineControlPoint(type: controlPoint.type, position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
    }
    
    
    private func tFromX(thisControlPoint: ClampedSplineControlPoint, nextControlPoint: ClampedSplineControlPoint, x: Float) -> Float {
        let dx = nextControlPoint.position.x - thisControlPoint.position.x
        let x = (x - thisControlPoint.position.x) / dx

        if thisControlPoint.endTangent!.weight == nil && nextControlPoint.startTangent!.weight == nil {
            return x
        }
        
        let wt2s = 1 - (nextControlPoint.startTangent!.weight ?? 1/3)
        let wt1 = (thisControlPoint.endTangent!.weight ?? 1/3)
        
        var t: Float = 0.5
        var t2: Float = 0.5

        while (true)
        {
            t2 = (1 - t)
            let fg: Float = 3.0 * t2 * t2 * t * wt1 + 3.0 * t2 * t * t * wt2s + t * t * t - x
            if (abs(fg) < 2 * Float.ulpOfOne) {
                return t
            }

            // third order householder method
            let fpg : Float = 3.0 * t2 * t2 * wt1 + 6.0 * t2 * t * (wt2s - wt1) + 3.0 * t * t * (1.0 - wt2s)
            let fppg : Float = 6 * t2 * (wt2s - 2.0 * wt1) + 6.0 * t * (1.0 - 2.0 * wt2s + wt1)
            let fpppg : Float = 18.0 * wt1 - 18.0 * wt2s + 6.0
            
            t -= (6.0 * fg * fpg * fpg - 3.0 * fg * fg * fppg) / (6.0 * fpg * fpg * fpg - 6.0 * fg * fpg * fppg + fg * fg * fpppg)
        }
    }

    func setType(type: ClampedSplineControlPointType, i: Int){
        let thisControlPoint = controlPoints[i]
        var nextVersionOfControlPoint = thisControlPoint
        if type == thisControlPoint.type {
            return
        }
        
        if type == .flat {
            var startTangent = thisControlPoint.startTangent
            var endTangent = thisControlPoint.endTangent
            if startTangent != nil {
                startTangent = ClampedSplineTangent(gradient: 0, weight: 0)
            }
            if endTangent != nil {
                endTangent = ClampedSplineTangent(gradient: 0, weight: 0)
            }
            nextVersionOfControlPoint = ClampedSplineControlPoint(type: type, position: thisControlPoint.position, startTangent: startTangent, endTangent: endTangent)
        } else if type == .aligned {
            var startTangent = thisControlPoint.startTangent ?? thisControlPoint.endTangent
            if thisControlPoint.type == .flat {
                if startTangent != nil {
                    startTangent = ClampedSplineTangent(gradient: 0)
                }
            }
            nextVersionOfControlPoint = ClampedSplineControlPoint(type: type, position: thisControlPoint.position, startTangent: startTangent, endTangent: startTangent)
        } else if type == .broken {
            var startTangent = thisControlPoint.startTangent
            var endTangent = thisControlPoint.endTangent
            if thisControlPoint.type == .flat {
                if startTangent != nil {
                    startTangent = ClampedSplineTangent(gradient: 0)
                }
                if endTangent != nil {
                    endTangent = ClampedSplineTangent(gradient: 0)
                }
            }
            nextVersionOfControlPoint = ClampedSplineControlPoint(type: type, position: thisControlPoint.position, startTangent: startTangent, endTangent: endTangent)
        }
        
        let nextControlPoint = i < controlPoints.count - 1 ? controlPoints[i+1] : nil
        let prevControlPoint = i > 0 ? controlPoints[i-1] : nil
        controlPoints[i] = ClampedSpline.clampTangents(prevControlPoint: prevControlPoint, controlPoint: nextVersionOfControlPoint, nextControlPoint: nextControlPoint)
        return
        
        
    }
    
}

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
                SplineOptionsView(spline: spline, currentSelection: currentSelection)
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
