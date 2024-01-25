//
//  Item.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData

@Model
final class JelloFunction {
    
    @Attribute(.unique) var uuid: UUID
    
    var name: String

    var userDescription: String


    @Relationship(deleteRule: .cascade, inverse: \JelloGraph.function)
    var graph: JelloGraph? = nil
    

    init(uuid: UUID, name: String, userDescription: String) {
        self.uuid = uuid
        self.name = name
        self.userDescription = userDescription
    }
    
    convenience init(){
        self.init(uuid: UUID(), name: "Untitled Function", userDescription: "")
    }
}
