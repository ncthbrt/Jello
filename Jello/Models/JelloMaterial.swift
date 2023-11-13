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
    var id: JelloNodeType { .material(uuid) }
    
    @Attribute(.unique) var uuid: UUID
    
    var name: String

    var userDescription: String

    @Relationship(deleteRule: .cascade)
    var graph: JelloGraph
    

    init(uuid: UUID, name: String, userDescription: String, graph: JelloGraph) {
        self.name = name
        self.uuid = uuid
        self.graph = graph
        self.userDescription = userDescription
    }
    
    convenience init(){
        self.init(uuid: UUID(), name: "Untitled Material", userDescription: "", graph: JelloGraph())
    }
}
