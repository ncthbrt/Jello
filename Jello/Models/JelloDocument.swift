//
//  JelloDocument.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/01.
//

import Foundation



enum JelloDocumentReference: Hashable, Identifiable {
    case material(UUID)
    case function(UUID)
    
    var id: UUID {
        switch(self) {
        case .material(let id):
            return id
        case .function(let id):
            return id
        }
    }
    
}


enum JelloDocument: Hashable, Identifiable {
    case material(JelloMaterial)
    case function(JelloFunction)
    
    var id: UUID {
        switch(self) {
        case .material(let mat):
            return mat.id
        case .function(let function):
            return function.id
        }
    }
    
    
    var name : String {
        switch(self) {
        case .material(let mat):
            return mat.name
        case .function(let function):
            return function.name
        }
    }
    
    var reference: JelloDocumentReference {
        switch(self) {
        case .material(let mat):
            return JelloDocumentReference.material(mat.id)
        case .function(let function):
            return JelloDocumentReference.function(function.id)
        }
    }
}
