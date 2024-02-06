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
            JelloBuiltInNodeMenuDefinition(description: "Subtracts values from one another", previewImage: "", category: .math, type: .subtract),
            JelloBuiltInNodeMenuDefinition(description: "Multiplies values together", previewImage: "", category: .math, type: .multiply),
            JelloBuiltInNodeMenuDefinition(description: "Divides values", previewImage: "", category: .math, type: .divide),
            JelloBuiltInNodeMenuDefinition(description: "The length of a vector", previewImage: "", category: .math, type: .length),
            JelloBuiltInNodeMenuDefinition(description: "Sets the length of a vector to 1", previewImage: "", category: .math, type: .normalize),
            JelloBuiltInNodeMenuDefinition(description: "Returns the fractional part of a number", previewImage: "", category: .math, type: .fract),
            JelloBuiltInNodeMenuDefinition(description: "Evaluates math expressions of up to 4 inputs", previewImage: "", category: .math, type: .calculator),
        ],
        .material: [
            JelloBuiltInNodeMenuDefinition(description: "Primary BSDF used to shade surfaces", previewImage: "", category: .material, type: .slabShader),
        ],
        .utility: [
            JelloBuiltInNodeMenuDefinition(description: "Preview arbitrary values", previewImage: "", category: .utility, type: .preview),
            JelloBuiltInNodeMenuDefinition(description: "Select a set of values from a vector", previewImage: "", category: .utility, type: .swizzle),
            JelloBuiltInNodeMenuDefinition(description: "Combines floats into a vector", previewImage: "", category: .utility, type: .combine),
            JelloBuiltInNodeMenuDefinition(description: "Separate a vector into a set of floats", previewImage: "", category: .utility, type: .separate),
            JelloBuiltInNodeMenuDefinition(description: "Writes values to an intermediate texture", previewImage: "", category: .utility, type: .compute),
            JelloBuiltInNodeMenuDefinition(description: "Samples a value from an n-dimensional field", previewImage: "", category: .utility, type: .sample),
        ],
        .value: [
            JelloBuiltInNodeMenuDefinition(description: "Specify a constant color", previewImage: "", category: .value, type: .color),
            JelloBuiltInNodeMenuDefinition(description: "Outputs a spline", previewImage: "", category: .value, type: .spline),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the world position", previewImage: "", category: .value, type: .worldPosition),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the texture coordinates", previewImage: "", category: .value, type: .texCoord),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the normal in model view space", previewImage: "", category: .value, type: .normal),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the tangent in model view space", previewImage: "", category: .value, type: .tangent),
            JelloBuiltInNodeMenuDefinition(description: "Outputs the bitangent in model view space", previewImage: "", category: .value, type: .bitangent)
        ]
    ]
}


