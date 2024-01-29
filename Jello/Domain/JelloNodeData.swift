//
//  JelloNodeData.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/01.
//

import Foundation
import simd
import SwiftUI
import SwiftData


struct StringArray: Codable, Equatable {
    let value: [String]
}

enum JelloNodeDataValue: Codable, Equatable {
    case null
    case string(String)
    case stringArray(StringArray)
    case bool(Bool)
    case int(Int)
    case float(Float)
    case float2(Float, Float)
    case float3(Float, Float, Float)
    case float4(Float, Float, Float, Float)
    case previewGeometry(JelloPreviewGeometry)
}


enum JelloNodeDataKey: String {
    case value
    case position
    case componentCount
    case typeSliderDisabled
}


@Model
final class JelloNodeData {
    public var key: String
    public var value: JelloNodeDataValue
    public var node: JelloNode? = nil
    
    init(key: String, value: JelloNodeDataValue, node: JelloNode) {
        self.key = key
        self.value = value
        self.node = node
    }
}
