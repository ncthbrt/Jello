//
//  JelloTypes.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation


enum JelloBuiltInNodeSubtype : Int, Codable, CaseIterable, Hashable, Equatable {
    // Functions
    case add = 0
    case subtract = 1
    case swizzle = 2
    case divide = 3
    case multiply = 4
    case fract = 5
    case normalize = 6
    case length = 7
    case calculator = 8
    case combine = 9
    case separate = 10
    
    // Texture
    case sample = 20
    
    // Shaders and Outputs
    case materialOutput = 100
    case slabShader = 101
    case preview = 102
    case compute = 103

    // Constants
    case color = 300
    
    // Inputs
    case worldPosition = 401
    case texCoord = 402
    case normal = 403
    case tangent = 404
    case bitangent = 405
    
    
    // Procedural
    case spline = 501
    
    var name : String {
        return String(describing: self).capitalized
    }

}

enum JelloNodeType: Equatable, Hashable, Codable {
    case builtIn(JelloBuiltInNodeSubtype)
    case userFunction(UUID)
    case material(UUID)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .builtIn(let t):
            hasher.combine(t.hashValue)
        case .userFunction(let id):
            hasher.combine(id)
        case .material(let id):
            hasher.combine(id)
        }
    }
}


enum JelloNodeCategory: Int, Codable, CaseIterable, Identifiable {
    case math = 0
    case other = 1
    case material = 2
    case utility = 3
    case value = 4
    var id: Int { self.rawValue }
}




enum JelloPreviewGeometry: Codable, Equatable {
    case sphere
    case cube
}
