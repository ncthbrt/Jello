//
//  RectAnimatedShape.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation
import SwiftUI


struct RectAnimatedShape : Shape {
    var frac: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let radius = min(rect.size.width, rect.size.height)
        let frac = min(1, max(0, frac))
        p.addRect(CGRect(x: 0, y: (1 - frac) * radius, width: radius, height: frac * radius))
        return p
    }
    
    var animatableData: CGFloat {
        get { frac }
        set {
            frac = newValue
        }
    }
}
