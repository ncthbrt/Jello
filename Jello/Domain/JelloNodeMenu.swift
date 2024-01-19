//
//  JelloNodeMenu.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation
import OrderedCollections

struct JelloBuiltInNodeMenuDefinition : Hashable, Identifiable, Equatable {
    var id: JelloNodeType {.builtIn(type)}
    let description: String
    let previewImage: String
    let category: JelloNodeCategory
    let type: JelloBuiltInNodeSubtype
    
    var name: String {
        return type.name
    }
    
    private init(description: String, previewImage: String, category: JelloNodeCategory, type: JelloBuiltInNodeSubtype) {
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
    
    public static let builtInFunctions:  OrderedDictionary<JelloNodeCategory, [JelloBuiltInNodeMenuDefinition]> = [
        .math: [
            JelloBuiltInNodeMenuDefinition(description: "Adds values together", previewImage: "", category: .math, type: .add),
            JelloBuiltInNodeMenuDefinition(description: "Subtracts values from one another", previewImage: "", category: .math, type: .subtract)
        ],
        .material: [
            JelloBuiltInNodeMenuDefinition(description: "Primary BSDF used to shade surfaces", previewImage: "", category: .material, type: .slabShader),
        ],
        .utility: [
            JelloBuiltInNodeMenuDefinition(description: "Preview arbitrary values", previewImage: "", category: .utility, type: .preview),
            JelloBuiltInNodeMenuDefinition(description: "Select a set of values from a vector", previewImage: "", category: .utility, type: .swizzle),
        ],
        .value: [
            JelloBuiltInNodeMenuDefinition(description: "Outputs the world position", previewImage: "", category: .value, type: .worldPosition),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the texture coordinates", previewImage: "", category: .value, type: .texCoord),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the normal in model view space", previewImage: "", category: .value, type: .normal),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the tangent in model view space", previewImage: "", category: .value, type: .tangent),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the bitangent in model view space", previewImage: "", category: .value, type: .bitangent)
        ]
    ]
}


