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



enum JelloNodeDataValue: Codable {
    case null
    case string(String)
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
