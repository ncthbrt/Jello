//
//  VertletShared.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/17.
//

import Foundation


class PositionCell: ObservableObject {
    var position: CGPoint = .zero
}

class OnOffCell: ObservableObject {
    var on: Bool = false
}

class DistanceCell: ObservableObject {
    var distance: CGFloat
    
    init(distance: CGFloat) {
        self.distance = distance
    }
    
}


protocol Constraint {
    mutating func relaxConstraint()
}

