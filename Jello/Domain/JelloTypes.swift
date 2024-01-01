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

    case color
    
    
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
    case value = 4
    var id: Int { self.rawValue }
}




enum JelloGraphDomainType: Int, Codable, CaseIterable {
    case constant = 0
    case modelDependant = 1
    case variable = 2
    case timeVarying = 3
}
