//
//  CGPointExtensions.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import Foundation
import SwiftUI
import simd

extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint  {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint  {
        return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint  {
        return CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
    }
    
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint  {
        return CGPoint(x: lhs.x / CGFloat(rhs), y: lhs.y / CGFloat(rhs))
    }
    
    static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint  {
        return CGPoint(x: CGFloat(lhs) * rhs.x, y: CGFloat(lhs) * rhs.y)
    }
    
    func magnitude() -> CGFloat {
        return CGFloat(sqrtf(Float(x*x+y*y)))
    }

    func magnitudeSquared() -> CGFloat {
        return x*x+y*y
    }

    func normal() -> CGPoint {
        let mag = self.magnitude()
        if abs(mag) < 0.00001 {
            return CGPoint(x: 1, y: 0)
        }
        return CGPoint(x: x / mag, y:  y / mag)
    }
    
    static func lerp(a: CGPoint, b: CGPoint, t: Float) -> CGPoint {
        return a * CGFloat(1 - t) + CGFloat(t) * b
    }
    
    init(_ point: vector_float2) {
        self.init(x: CGFloat(point.x), y: CGFloat(point.y))
    }
}


extension vector_float2 {
    
    func magnitude() -> Float {
        return sqrtf(magnitudeSquared())
    }

    func magnitudeSquared() -> Float {
        return x*x+y*y
    }

    func normal() -> vector_float2 {
        let mag = self.magnitude()
        if abs(mag) < 0.00001 {
            return vector_float2(x: 1, y: 0)
        }
        return vector_float2(x: x, y:  y) * (1/mag)
    }
    
    static func lerp(a: vector_float2, b: vector_float2, t: Float) -> vector_float2 {
        return a * (1 - t) + t * b
    }
    
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}
