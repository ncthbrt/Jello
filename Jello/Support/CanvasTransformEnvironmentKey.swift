//
//  CanvasTransformEnvironmentKey.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/18.
//

import Foundation
import SwiftUI

@Observable class CanvasTransform {
    var scale: CGFloat
    var position: CGPoint
    var viewPortSize: CGSize
    
    init(scale: CGFloat, position: CGPoint, viewPortSize: CGSize) {
        self.scale = scale
        self.position = position
        self.viewPortSize = viewPortSize
    }
    
    func transform(viewPosition: CGPoint) -> CGPoint {
        viewPosition / scale - position
    }
    
    func transform(worldPosition: CGPoint) -> CGPoint {
        (worldPosition + position) * scale
    }
    
    func transform(viewSize: CGPoint) -> CGPoint {
        viewSize / scale
    }
    
    func transform(worldSize: CGPoint) -> CGPoint {
        worldSize * scale
    }
}


private struct CanvasTransformEnvironmentKey: EnvironmentKey {
    static let defaultValue: CanvasTransform = CanvasTransform(scale: 1, position: .zero,  viewPortSize: CGSize(width: 0, height: 0))
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
