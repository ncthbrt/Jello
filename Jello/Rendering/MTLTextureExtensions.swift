//
//  MTLTextureExtensions.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/23.
//

import Foundation
import Metal
import MetalKit

extension MTLTexture {
    var data : Data {
        var pixelData = Array(repeating: UInt8(), count: self.allocatedSize)
        pixelData.withUnsafeMutableBytes {
            if self.pixelFormat == .r32Float {
                self.getBytes($0.baseAddress!, bytesPerRow: self.width * 4, from: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: self.width, height: self.height, depth: self.depth)), mipmapLevel: 0)
            } else if self.pixelFormat == .rgba32Float {
                self.getBytes($0.baseAddress!, bytesPerRow: self.width * 4 * 4, from: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: self.width, height: self.height, depth: self.depth)), mipmapLevel: 0)
            }
        }
        return Data(pixelData)
    }
}
