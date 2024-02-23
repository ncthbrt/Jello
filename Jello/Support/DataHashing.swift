//
//  DataHashing.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/19.
//

import Foundation
import CryptoKit

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}


extension Data {
    public func sha256() -> Data {
        return SHA256.hash(data: self).data
    }
}

