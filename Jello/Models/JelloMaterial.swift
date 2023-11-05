//
//  Item.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftData

@Model
final class JelloMaterial {
   
    @Attribute(.unique) var id: UUID
    var name: String

    @Relationship(deleteRule: .cascade)
    var graph: JelloGraph
    

    init(id: ID, name: String, graph: JelloGraph) {
        self.name = name
        self.id = id
        self.graph = graph
    }
    
    convenience init(){
        self.init(id: UUID(), name: "Untitled Material", graph: JelloGraph())
    }
}
