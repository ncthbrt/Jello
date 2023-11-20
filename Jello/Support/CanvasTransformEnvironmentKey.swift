//
//  CanvasTransformEnvironmentKey.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/18.
//

import Foundation
import SwiftUI

struct CanvasTransform {
    let scale: CGFloat
    let position: CGPoint
    
    
    func transform(viewPosition: CGPoint) -> CGPoint {
        viewPosition / scale - position
    }
    
    func transform(worldPosition: CGPoint) -> CGPoint {
        (worldPosition - position) * scale
    }
}


private struct CanvasTransformEnvironmentKey: EnvironmentKey {
    static let defaultValue: CanvasTransform = CanvasTransform(scale: 1, position: .zero)
}


extension EnvironmentValues {
    var canvasTransform: CanvasTransform {
        get { self[CanvasTransformEnvironmentKey.self] }
        set { self[CanvasTransformEnvironmentKey.self] = newValue }
    }
}


extension View {
    func canvasTransform(_ value: CanvasTransform) -> some View {
        environment(\.canvasTransform, value)
    }
}
