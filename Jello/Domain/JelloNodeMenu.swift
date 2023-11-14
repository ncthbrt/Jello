//
//  JelloNodeMenu.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation


struct JelloBuiltInNodeMenuDefinition : Hashable, Identifiable, Equatable {
    var id: JelloNodeType {.builtIn(type)}
    let description: String
    let previewImage: String
    let category: JelloNodeCategory
    let type: JelloBuiltInNodeSubtype
    
    var name: String {
        return type.name
    }
    
    init(description: String, previewImage: String, category: JelloNodeCategory, type: JelloBuiltInNodeSubtype) {
        self.description = description
        self.previewImage = previewImage
        self.category = category
        self.type = type
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
    
    
    static func == (lhs: JelloBuiltInNodeMenuDefinition, rhs: JelloBuiltInNodeMenuDefinition) -> Bool {
        return lhs.type == rhs.type
    }
}
