//
//  ProjectNavigation.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/10/30.
//

import Foundation
import SwiftUI
import SwiftData

enum JelloDocumentSearchTag: String, Identifiable, Hashable, CaseIterable, Codable {
    case all
    case material
    case function
    case texture
    case model
    var id: Self { self }
}

@Observable class ProjectNavigation {    
    var searchText: String = ""
    var searchTag: JelloDocumentSearchTag = JelloDocumentSearchTag.all
    var navPath: [JelloDocumentReference] = []
    var selectedItem: JelloDocumentReference? = nil
}
