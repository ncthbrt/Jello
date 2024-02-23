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
            self.getBytes($0.baseAddress!, bytesPerRow: self.bufferBytesPerRow, from: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: self.width, height: self.height, depth: self.depth)), mipmapLevel: 0)
        }
        return Data(pixelData)
    }
}
