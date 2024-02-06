//
//  Splines.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation
import SwiftData

struct ClampedSplineTangent: Codable, Equatable {
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
    
    init(gradient: Float) {
        self.init(gradient: gradient, weight: nil)
    }
}

enum ClampedSplineControlPointType: Int, Codable, Equatable, Identifiable, CaseIterable {
    case aligned = 0
    case broken = 2
    case flat = 1

    

    var id: Int {
        return self.rawValue
    }
}

struct ClampedSplinePoint: Codable, Equatable {
    let x: Float
    let y: Float
}


struct ClampedSplineControlPoint: Codable, Equatable {
    let type: ClampedSplineControlPointType
    let position: ClampedSplinePoint
    let startTangent: ClampedSplineTangent?
    let endTangent: ClampedSplineTangent?
    
    init(type: ClampedSplineControlPointType, position: ClampedSplinePoint, startTangent: ClampedSplineTangent?, endTangent: ClampedSplineTangent?) {
        self.position = position
        self.startTangent = startTangent
        self.endTangent = endTangent
        self.type = type
    }
}


@Model
class ClampedSpline {
    @Attribute(.unique) var uuid: UUID
    var controlPoints: [ClampedSplineControlPoint]

    init(uuid: UUID, controlPoints: [ClampedSplineControlPoint]) {
        self.uuid = uuid
        self.controlPoints = controlPoints
    }
    
    convenience init() {
        self.init(uuid: UUID(), controlPoints: [ClampedSplineControlPoint(type: .broken, position: .init(x: 0, y: 0), startTangent: nil, endTangent: ClampedSplineTangent(gradient: 1, weight: nil)),  ClampedSplineControlPoint(type: .broken, position: .init(x: 1, y: 1), startTangent: ClampedSplineTangent(gradient: 1, weight: nil), endTangent: nil)])
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
