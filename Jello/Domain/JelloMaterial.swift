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
    
    @Attribute(.unique) var uuid: UUID
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.material)
    private var dependants: [JelloNode]
    
    var name: String

    var userDescription: String

    @Relationship(deleteRule: .cascade)
    var graph: JelloGraph
    

    init(uuid: UUID, name: String, userDescription: String, graph: JelloGraph, dependants: [JelloNode]) {
        self.name = name
        self.uuid = uuid
        self.graph = graph
        self.userDescription = userDescription
        self.dependants = dependants
    }
    
    convenience init(){
        self.init(uuid: UUID(), name: "Untitled Material", userDescription: "", graph: JelloGraph(), dependants: [])
    }
}
