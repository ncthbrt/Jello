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

    var id: JelloNodeType { .userFunction(uuid) }
    
    
    @Relationship(deleteRule: .cascade, inverse: \JelloNode.function)
    var dependants: [JelloNode]
    
    var name: String

    var userDescription: String


    @Relationship(deleteRule: .cascade)
    var graph: JelloGraph
    

    init(uuid: UUID, name: String, userDescription: String, graph: JelloGraph, dependants: [JelloNode]) {
        self.uuid = uuid
        self.name = name
        self.graph = graph
        self.userDescription = userDescription
        self.dependants = dependants
    }
    
    convenience init(){
        self.init(uuid: UUID(), name: "Untitled Function", userDescription: "", graph: JelloGraph(), dependants: [])
    }
}
