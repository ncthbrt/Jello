//
//  VertletShared.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/17.
//

import Foundation
import simd

class PositionCell: ObservableObject {
    var position: vector_float2 = .zero
}

class OnOffCell: ObservableObject {
    var on: Bool = false
}

class DistanceCell: ObservableObject {
    var distance: Float
    
    init(distance: Float) {
        self.distance = distance
    }
    
}


protocol Constraint {
    mutating func relaxConstraint()
}

