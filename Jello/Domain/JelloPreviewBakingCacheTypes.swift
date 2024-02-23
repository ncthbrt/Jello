//
//  JelloPersistedComputeTexture.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/19.
//

import Foundation
import SwiftData
import JelloCompilerStatic


@Model
public class JelloPersistedTextureResource {
    @Attribute(.unique) var uuid: UUID
    @Attribute(.externalStorage) var texture: Data?
    var originatingStage: UUID
    var originatingPass: UInt32
    var wedgeSha256: Data

    init(uuid: UUID, texture: Data? = nil, originatingStage: UUID, originatingPass: UInt32, wedgeSha256: Data) {
        self.texture = texture
        self.uuid = uuid
        self.originatingStage = originatingStage
        self.originatingPass = originatingPass
        self.wedgeSha256 = wedgeSha256
    }
}


// TODO: Clean this and associated texture up when node is deleted
@Model
public class JelloPersistedStageShader {
    // Constants
    var graphId: UUID
    var stageId: UUID
    var index: UInt32
    var wedgeSha256: Data
    
    // Varying
    var shaderSha256: Data
    var argsSha256: Data
    var resources: [UUID]
    var output: JelloPersistedTextureResource?
    
    init(graphId: UUID, stageId: UUID, index: UInt32, wedgeSha256: Data, shaderSha256: Data, argsSha256: Data, resources: [UUID] = [], output: JelloPersistedTextureResource? = nil) {
        self.graphId = graphId
        self.stageId = stageId
        self.index = index
        self.wedgeSha256 = wedgeSha256
        self.shaderSha256 = shaderSha256
        self.argsSha256 = argsSha256
        self.resources = resources
        self.output = output
    }
}



