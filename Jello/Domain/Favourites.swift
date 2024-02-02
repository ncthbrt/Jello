//
//  Favourites.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation
import SwiftData

@Model
class FavouriteClampedSpline {
    var uuid: UUID
    var controlPoints: [ClampedSplineControlPoint]
    var dateAdded: Date
    
    init(uuid: UUID, controlPoints: [ClampedSplineControlPoint], dateAdded: Date){
        self.uuid = uuid
        self.controlPoints = controlPoints
        self.dateAdded = dateAdded
    }
}
