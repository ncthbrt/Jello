//
//  JelloTypes.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation


enum JelloBuiltInNodeSubtype : Int, Codable, CaseIterable, Hashable {
    
    case add = 0
    case subtract = 1
    
    case materialOutput = 100
    case slabShader = 101
    case preview = 102

    
    var name : String {
        return String(describing: self).capitalized
    }
    
    static func == (lhs: JelloBuiltInNodeSubtype, rhs: JelloBuiltInNodeSubtype) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
    
    
    static func == (lhs: JelloNodeType, rhs: JelloNodeType) -> Bool {
        switch (lhs, rhs) {
        case (.builtIn(let a), .builtIn(let b)):
            return a == b
        case (.userFunction(let a), .userFunction(let b)):
            return a == b
        case (.material(let a), .material(let b)):
            return a == b
        default:
            return false
        }
    }
}


enum JelloNodeCategory: Int, Codable, CaseIterable, Identifiable {
    case math = 0
    case other = 1
    case material = 2
    case utility = 3
    var id: Int { self.rawValue }
}

enum JelloGraphDataType: Int, Codable, CaseIterable {
    case any = 0
    case anyFloat = 1
    case float4 = 2
    case float3 = 3
    case float2 = 4
    case float = 5
    case int = 6
    case bool = 7
    case anyTexture = 8
    case texture1d = 9
    case texture2d = 10
    case texture3d = 11
    case anyMaterial = 12
    case slabMaterial = 13
}
