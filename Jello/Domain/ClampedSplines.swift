//
//  Splines.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation

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
