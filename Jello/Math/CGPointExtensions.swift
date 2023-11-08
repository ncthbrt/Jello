//
//  CGPointExtensions.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import Foundation
import SwiftUI

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
}
