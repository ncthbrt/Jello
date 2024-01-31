//
//  SplineEditor.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/29.
//

import Foundation
import SwiftUI


struct SplineTangent: Codable, Equatable {
    let gradient: Float
    let weight: Float?
    
    init(gradient: Float, weight: Float?) {
        self.gradient = min(50, max(-50, gradient))
        self.weight = if let weight = weight {
            abs(weight - 1.0/3.0) < 2 * Float.ulpOfOne ? nil : max(0, min(1, weight))
        } else {
            nil
        }
    }
}

struct SplinePoint: Codable, Equatable {
    let x: Float
    let y: Float
}


struct SplineControlPoint: Codable, Equatable {
    let position: SplinePoint
    let startTangent: SplineTangent?
    let endTangent: SplineTangent?
}

@Observable
class Spline {
    var controlPoints: [SplineControlPoint]
    
    init(controlPoints: [SplineControlPoint]) {
        self.controlPoints = controlPoints
    }
    
    convenience init() {
        self.init(controlPoints: [SplineControlPoint(position: .init(x: 0, y: 0), startTangent: nil, endTangent: SplineTangent(gradient: 1, weight: nil)),  SplineControlPoint(position: .init(x: 1, y: 1), startTangent: SplineTangent(gradient: 1, weight: nil), endTangent: nil)])
    }
    
    
    func sortControlPoints() {
        controlPoints.sort(by: { a, b in a.position.x < b.position.x })
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
    
    func subdivideCurve(x: Float, t: Float) {
        for i in 0..<(controlPoints.count-1) {
            let thisControlPoint = controlPoints[i]
            let nextControlPoint = controlPoints[i+1]
            if x > thisControlPoint.position.x && x < nextControlPoint.position.x {
                let dx = (nextControlPoint.position.x - thisControlPoint.position.x)
                let endTangentOffset = dx * tangentToUnitOffset(tangent: thisControlPoint.endTangent!, startTangent: false)
                let startTangentOffset = dx * tangentToUnitOffset(tangent: nextControlPoint.startTangent!, startTangent: true)
                
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
                
                controlPoints[i] = SplineControlPoint(position: p0, startTangent: thisControlPoint.startTangent, endTangent: SplineTangent(gradient: gradientA, weight: weightA))
                controlPoints.insert(SplineControlPoint(position: p, startTangent: SplineTangent(gradient: gradientD, weight: weightD), endTangent: SplineTangent(gradient: gradientE, weight: weightE)), at: i+1)
                controlPoints[i+2] = SplineControlPoint(position: p3, startTangent: SplineTangent(gradient: gradientC, weight: weightC), endTangent: nextControlPoint.endTangent)
                break
            }
        }
    }
    
    func tangentToUnitOffset(tangent: SplineTangent, startTangent: Bool) -> SplinePoint {
        let sign: Float = startTangent ? -1 : 1
        if let weight = tangent.weight {
            return SplinePoint(x: sign * weight, y: sign * tangent.gradient * weight)
        }
        return SplinePoint(x: sign * 1/3.0, y: sign * tangent.gradient * 1.0/3.0)
    }
    
    func unitOffsetToTangent(controlPointPosition: SplinePoint, offset: SplinePoint, dx: Float, clamp: Bool = false) -> SplineTangent {
        var gradient = offset.y / offset.x
        let globalOffset = offset * dx
        let pos = controlPointPosition + globalOffset
        
        if clamp, pos.y > 1 {
            let yHeight = (1 - controlPointPosition.y)
            let weight = yHeight / gradient / dx
            return SplineTangent(gradient: gradient, weight: weight)
        } else if clamp, pos.y < 0 {
            let yHeight = (0 - controlPointPosition.y)
            let weight = yHeight / gradient / dx
            return SplineTangent(gradient: gradient, weight: weight)
        } else {
            let weight: Float = offset.x
            return SplineTangent(gradient: gradient, weight: weight)
        }
    }
    
    func clampTangents(prevControlPoint: SplineControlPoint?, controlPoint: SplineControlPoint, nextControlPoint: SplineControlPoint?) -> SplineControlPoint {
        var startTangent: SplineTangent? = nil
        var endTangent: SplineTangent? = nil
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
        return SplineControlPoint(position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
    }
    
    
    private func tFromX(thisControlPoint: SplineControlPoint, nextControlPoint: SplineControlPoint, x: Float) -> Float {
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
    
    func drawPath(path: inout Path, size: CGPoint) {
        path.move(to: CGPoint(x: 0, y: size.y * CGFloat(1 - controlPoints[0].position.y)))
        for i in 1..<controlPoints.count {
            let prevControlPoint = controlPoints[i-1]
            let nextControlPoint = i < controlPoints.count-1 ? controlPoints[i+1] : nil
            let thisControlPoint = clampTangents(prevControlPoint: prevControlPoint, controlPoint: controlPoints[i], nextControlPoint: nextControlPoint)
            let fromPos = size * CGPoint(x: CGFloat(prevControlPoint.position.x), y: 1 - CGFloat(prevControlPoint.position.y))
            let toPos = size * CGPoint(x: CGFloat(thisControlPoint.position.x), y: 1 - CGFloat(thisControlPoint.position.y))
            var endTangentOffset = tangentToUnitOffset(tangent: prevControlPoint.endTangent!, startTangent: false)
            endTangentOffset = SplinePoint(x: endTangentOffset.x, y: -endTangentOffset.y)
            var startTangentOffset = tangentToUnitOffset(tangent: thisControlPoint.startTangent!, startTangent: true)
            startTangentOffset = SplinePoint(x: startTangentOffset.x, y:  -startTangentOffset.y)
            let delta1 = CGFloat(thisControlPoint.position.x - prevControlPoint.position.x)
            let delta2 = CGFloat(thisControlPoint.position.x - prevControlPoint.position.x)
            path.addCurve(to: toPos, control1: fromPos + CGPoint(endTangentOffset) * size * delta1, control2: toPos + CGPoint(startTangentOffset) * size * delta2)
        }
    }
    
}

struct SplineEditorControlPoint : View {
    let i: Int
    let controlPoint: SplineControlPoint
    let selection: Int?
    var spline: Spline
    let size: CGSize
    let onSelected: (Bool) -> ()
    @State var dragStartLocation: SplinePoint? = nil

    var body: some View {
        ZStack {
            let prevControlPoint = i > 0 ? spline.controlPoints[i-1] : nil
            let nextControlPoint = i < spline.controlPoints.count - 1 ? spline.controlPoints[i+1] : nil
            let startPosition = CGPoint(x: CGFloat(controlPoint.position.x), y: CGFloat(1.0 - controlPoint.position.y)) * CGPoint(size)
            let controlPoint = spline.clampTangents(prevControlPoint: prevControlPoint, controlPoint: controlPoint, nextControlPoint: nextControlPoint)
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
                    }.stroke(lineWidth: 2).fill(.white)
                    Circle().fill(.white).frame(width: 10, height: 10).position(handleEndPosition).gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                        event in
                        if dragStartLocation == nil {
                            dragStartLocation = SplinePoint(x: Float(handleEndPosition.x), y: Float(size.height - handleEndPosition.y))
                        }
                        let dragEndPosition = dragStartLocation! + SplinePoint(x: Float(event.translation.width), y: Float(-event.translation.height))
                        let delta = dragEndPosition - SplinePoint(x: Float(startPosition.x), y: Float(size.height - startPosition.y))
                        let unitOffset = delta / SplinePoint(size) / dx
                        
                        let startTangent = spline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: -1 * unitOffset, dx: -dx)
                        var endTangent: SplineTangent? = nil
                        if let e = controlPoint.endTangent {
                            let nextControlPoint = spline.controlPoints[i + 1]
                            let prevOffset = spline.tangentToUnitOffset(tangent: e, startTangent: false)
                            let dx = nextControlPoint.position.x - controlPoint.position.x
                            let offset = SplinePoint(x: 1, y: startTangent.gradient).setMagnitude(factor: prevOffset.magnitude())
                            endTangent = spline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: offset, dx: dx)
                        }
                        spline.controlPoints[i] = SplineControlPoint(position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
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
                    }.stroke(lineWidth: 1).fill(.white)
                    ZStack {
                        Circle().fill(.white).frame(width: 10, height: 10)
                    }.frame(width: 20, height: 20).contentShape(Circle()).position(handleEndPosition).gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                        event in
                        if dragStartLocation == nil {
                            dragStartLocation = SplinePoint(x: Float(handleEndPosition.x), y: Float(size.height - handleEndPosition.y))
                        }
                        let dragEndPosition = dragStartLocation! + SplinePoint(x: Float(event.translation.width), y: Float(-event.translation.height))
                        let delta = dragEndPosition - SplinePoint(x: Float(startPosition.x), y: Float(size.height - startPosition.y))
                        let unitOffset = delta / SplinePoint(size) / dx
                        
                        let endTangent = spline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: unitOffset, dx: dx)
                        var startTangent: SplineTangent? = nil
                        if let s = controlPoint.startTangent {
                            let prevControlPoint = spline.controlPoints[i - 1]
                            let prevOffset = spline.tangentToUnitOffset(tangent: s, startTangent: true)
                            let dx = controlPoint.position.x - prevControlPoint.position.x
                            let offset = SplinePoint(x: 1, y: endTangent.gradient).setMagnitude(factor: prevOffset.magnitude())
                            startTangent = spline.unitOffsetToTangent(controlPointPosition: controlPoint.position, offset: offset, dx: -dx)
                        }
                        spline.controlPoints[i] = SplineControlPoint(position: controlPoint.position, startTangent: startTangent, endTangent: endTangent)
                    }).onEnded({ _ in
                        dragStartLocation = nil
                    }))
                }
            }
            Rectangle().fill(.white).frame(width: 12, height: 12).shadow(radius: 4).position(startPosition)
                .gesture(DragGesture()
                    .onChanged({ event in
                        if dragStartLocation == nil {
                            dragStartLocation = controlPoint.position
                        }
                        var position: SplinePoint = SplinePoint(event.translation) / SplinePoint(size)
                        position = SplinePoint(x: max(0, min(1, dragStartLocation!.x + position.x)), y: min(1, max(0, dragStartLocation!.y - position.y)))
                        if i == 0 {
                            position = SplinePoint(x: 0, y: position.y)
                        } else if i == spline.controlPoints.count - 1 {
                            position = SplinePoint(x: 1, y: position.y)
                        } else {
                            let prev = spline.controlPoints[i-1]
                            let next = spline.controlPoints[i+1]
                            position = SplinePoint(x: min(max(prev.position.x, position.x), next.position.x), y: position.y)
                        }
                        spline.controlPoints[i] = SplineControlPoint(position: position, startTangent: controlPoint.startTangent, endTangent: controlPoint.endTangent)
                    }).onEnded({ _ in
                        dragStartLocation = nil
                    })
                )
                .onTapGesture(count: 2, perform: {
                    spline.controlPoints.remove(at: i)
                })
                .onTapGesture {
                    onSelected(true)
                }
        }
    }
}



struct SplineEditor: View {
    @Bindable var spline: Spline
    @State var currentSelection: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path {
                    path in spline.drawPath(path: &path, size: CGPoint(geometry.size))
                }.stroke(lineWidth: 5).fill(Gradient(colors: [.red, .blue]))
                ForEach(spline.controlPoints.indices, id: \.self) { i in
                    SplineEditorControlPoint(i: i, controlPoint: spline.controlPoints[i], selection: currentSelection, spline: spline, size: geometry.size, onSelected: { selected in
                        currentSelection = selected ? i : (i == currentSelection ? nil: currentSelection)
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
        }.padding(12).clipped()
    }
    
}

struct SplineEditorPreview: View {
    @State var spline: Spline = Spline()
    
    var body: some View {
        VStack {
            SplineEditor(spline: spline).frame(width: 500, height: 500)
        }
    }
}


#Preview {
    SplineEditorPreview()
}
