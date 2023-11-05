//
//  JelloProjectPicker.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/02.
//

import Foundation
import SwiftData

@Model
class JelloProjectReference {
    @Attribute(.unique) var fullPath: URL
    var subPath: String?
    var bookmark : String
    var name: String
    
    var hydratedBasePath : URL? {
        var isStale = false
        let bookmarkData = Data(base64Encoded: self.bookmark)
        
        guard let updatedBasePath = try? URL(resolvingBookmarkData: bookmarkData!, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        if isStale {
            if !self.updateBookmark(basePath: updatedBasePath) {
                return nil
            }
        }
        return updatedBasePath
    }
    
    init(bookmark: String, fullPath: URL, subPath: String?, name: String) {
        self.subPath = subPath
        self.bookmark = bookmark
        self.name = name
        self.fullPath = fullPath
    }
    

    convenience init?(basePath: URL, subPath: String) {
        guard let bookmarkData = try? basePath.bookmarkData() else {
            return nil
        }
        
        var path = basePath.appendingPathComponent(subPath, conformingTo: .jelloProject)
        
        self.init(bookmark: bookmarkData.base64EncodedString(), fullPath: path, subPath: subPath, name: path.lastPathComponent)
    }
    
    convenience init?(path: URL) {
        guard path.startAccessingSecurityScopedResource() else {
            return nil
        }
        
        defer { path.stopAccessingSecurityScopedResource() }

        guard let bookmarkData = try? path.bookmarkData() else {
            return nil
        }
        
        self.init(bookmark: bookmarkData.base64EncodedString(), fullPath: path, subPath: nil, name: path.lastPathComponent)
    }
    
    func updateBookmark(basePath: URL) -> Bool {
        guard basePath.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return false
        }
        
        defer { basePath.stopAccessingSecurityScopedResource() }
        
        guard let bookmarkData = try? basePath.bookmarkData() else {
            return false
        }
        
        self.bookmark = bookmarkData.base64EncodedString()
        
        return true
    }
    
}
