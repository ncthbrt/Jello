//
//  JelloNodeBaker.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/19.
//

import Foundation
import SwiftUI
import SwiftData
import JelloCompilerStatic
import CryptoKit
import Metal
import MetalKit
import simd



// TODO: Support MIP Mapping for Vert-Frag inputs
@ModelActor
actor JelloPreviewBakerActor {
    private var device: MTLDevice?
    private var metalKitTextureLoader: MTKTextureLoader? = nil
    private var computeModelIOVertexDescriptor: MDLVertexDescriptor? = nil
    private var vertFragModelIOVertexDescriptor: MDLVertexDescriptor? = nil

    private var computeVertexDescriptor: MTLVertexDescriptor? = nil
    private var vertexFragVertexDescriptor: MTLVertexDescriptor? = nil
    private struct ShaderKey : Hashable {
        let stageId: UUID
        let index: UInt32
    }
    
    private var shaderLibs: [ShaderKey: MTLLibrary] = [:]
    private var compiledSpirv: [ShaderKey: MslSpirvShaderOutput] = [:]
    private var previewGeometry: [JelloPreviewGeometry: [JelloMesh]] = [:]
    

    
    private func calculateWedgeSha256(encoder: PropertyListEncoder, geometry: JelloPreviewGeometry?) -> Data {
        if let geo = geometry {
            return (try! encoder.encode(geo).sha256())
        }
        return Data()
    }
    
    private func initializeSharedResources() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        
        assert(defaultDevice.supportsFamily(.apple7),
               "Application requires MTLGPUFamilyApple7")
        
        device = defaultDevice
        
        metalKitTextureLoader = MTKTextureLoader(device: defaultDevice)
        
        vertexFragVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        vertexFragVertexDescriptor!.attributes[0].format = .float3
        vertexFragVertexDescriptor!.attributes[0].offset = 0
        vertexFragVertexDescriptor!.attributes[0].bufferIndex = 0

        // Texture coordinates.
        vertexFragVertexDescriptor!.attributes[1].format = .float2
        vertexFragVertexDescriptor!.attributes[1].offset = 12
        vertexFragVertexDescriptor!.attributes[1].bufferIndex = 0

        // Normals.
        vertexFragVertexDescriptor!.attributes[2].format = .float3
        vertexFragVertexDescriptor!.attributes[2].offset = 20
        vertexFragVertexDescriptor!.attributes[2].bufferIndex = 0

        // Tangents.
        vertexFragVertexDescriptor!.attributes[3].format = .float3
        vertexFragVertexDescriptor!.attributes[3].offset = 32
        vertexFragVertexDescriptor!.attributes[3].bufferIndex = 0

        // Bitangents.
        vertexFragVertexDescriptor!.attributes[4].format = .float3
        vertexFragVertexDescriptor!.attributes[4].offset = 44
        vertexFragVertexDescriptor!.attributes[4].bufferIndex = 0

        // Generic attribute buffer layout.
        vertexFragVertexDescriptor!.layouts[0].stride = 56
        
        self.computeVertexDescriptor = MTLVertexDescriptor()
        // Positions.
        computeVertexDescriptor!.attributes[0].format = .float3
        computeVertexDescriptor!.attributes[0].offset = 0
        computeVertexDescriptor!.attributes[0].bufferIndex = 0

        // Texture coordinates.
        computeVertexDescriptor!.attributes[1].format = .float2
        computeVertexDescriptor!.attributes[1].offset = 16
        computeVertexDescriptor!.attributes[1].bufferIndex = 0

        // Normals.
        computeVertexDescriptor!.attributes[2].format = .float3
        computeVertexDescriptor!.attributes[2].offset = 32
        computeVertexDescriptor!.attributes[2].bufferIndex = 0

        // Tangents.
        computeVertexDescriptor!.attributes[3].format = .float3
        computeVertexDescriptor!.attributes[3].offset = 48
        computeVertexDescriptor!.attributes[3].bufferIndex = 0

        // Bitangents.
        computeVertexDescriptor!.attributes[4].format = .float3
        computeVertexDescriptor!.attributes[4].offset = 64
        computeVertexDescriptor!.attributes[4].bufferIndex = 0

        // Generic attribute buffer layout.
        computeVertexDescriptor!.layouts[0].stride = 80

        computeModelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(computeVertexDescriptor!)
        vertFragModelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexFragVertexDescriptor!)
        
        (computeModelIOVertexDescriptor!.attributes[0] as! MDLVertexAttribute).name  = MDLVertexAttributePosition
        (computeModelIOVertexDescriptor!.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (computeModelIOVertexDescriptor!.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (computeModelIOVertexDescriptor!.attributes[3] as! MDLVertexAttribute).name  = MDLVertexAttributeTangent
        (computeModelIOVertexDescriptor!.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent
        
        (vertFragModelIOVertexDescriptor!.attributes[0] as! MDLVertexAttribute).name  = MDLVertexAttributePosition
        (vertFragModelIOVertexDescriptor!.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (vertFragModelIOVertexDescriptor!.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (vertFragModelIOVertexDescriptor!.attributes[3] as! MDLVertexAttribute).name  = MDLVertexAttributeTangent
        (vertFragModelIOVertexDescriptor!.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent

    }
    
    private func convertTextureToData(texture: MTLTexture) throws -> Data {
//        switch texture.textureType {
//        case .type2D:
//            switch texture.pixelFormat {
//            case .r32Sint, .r32Float:
//                return texture.data
//            default:
//                return texture.pngData
//            }
//        default:
            return texture.data
//        }
    }
    
    private func loadTexture(textureDefinition: JelloComputeIOTexture, texture: Data) throws -> MTLTexture {
        guard case .dimension(let x, let y, let z) = textureDefinition.size else {
            fatalError("No dimension")
        }
        
        // Load 2d images using metalKitTextureLoader, as these are saved as PNGs
//        if z == 1, y > 1, textureDefinition.format != .R32i, textureDefinition.format != .R32f {
//            let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
//                .textureUsage: MTLTextureUsage.shaderRead,
//                .textureStorageMode: MTLStorageMode.private,
//            ]
//
//            return try! self.metalKitTextureLoader!.newTexture(data: texture, options: textureLoaderOptions)
//        }
        
        
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = switch textureDefinition.format {
        case .R32f:
                .r32Float
        case .R32i:
                .r32Sint
        case .Rgba32f:
                .rgba32Float
        case .Rgba16f:
                .rgba16Float
        }
        
        descriptor.width = x
        descriptor.height = y
        descriptor.depth = z
        descriptor.textureType = z > 1 ? .type3D : (y > 1 ? .type2D : .type1D)
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        let result = device!.makeTexture(descriptor: descriptor)

        texture.withUnsafeBytes {
            let region: MTLRegion = .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: x, height: y, depth: z))
            switch textureDefinition.format {
            case .Rgba32f:
                result!.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: x * 16)
            case .Rgba16f:
                result!.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: x * 8)
            case .R32f:
                result!.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: x * 4)
            case .R32i:
                result!.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: x * 4)
            }
        }
        
        return result!
    }
    
    private func makeOutputTexture(texDefn: MslSpirvTextureBindingOutput) throws -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = switch texDefn.texture.format {
        case .R32f:
                .r32Float
        case .R32i:
                .r32Sint
        case .Rgba32f:
                .rgba32Float
        case .Rgba16f:
                .rgba16Float
        }
        
        guard case .dimension(let x, let y, let z) = texDefn.texture.size else {
            fatalError("No dimension")
        }
        textureDescriptor.width = x;
        textureDescriptor.height = y;
        textureDescriptor.depth = z
        
        textureDescriptor.textureType = z > 1 ? .type3D : (y > 1 ? .type2D : .type1D)
        
        // The image kernel only needs to read the incoming image data.
        
        textureDescriptor.usage = [.shaderWrite, .shaderRead];
        textureDescriptor.storageMode = .shared

        return device!.makeTexture(descriptor: textureDescriptor)!
    }

    private func bindGeometry(geometry: JelloPreviewGeometry, triangleCount: inout Int, resources: inout [(resource: any MTLResource, usage: MTLResourceUsage)], argumentEncoder: inout MTLArgumentEncoder,  indicesBinding: UInt32, verticesBinding: UInt32) throws  {
        let g = if let geo = self.previewGeometry[geometry] {
            geo
        } else {
            try loadPreviewGeometry(geometry, modelIOVertexDescriptor: computeModelIOVertexDescriptor!, device: device!)
        }
        previewGeometry[geometry] = g
        // We assume that preview geometry only has a single mesh and submesh
        let mesh0 = g[0]
        let subMesh0 = mesh0.submeshes[0]
        let indicesBuffer = subMesh0.metalKitSubmesh.indexBuffer
        let verticesBuffer = mesh0.metalKitMesh.vertexBuffers[0]
        triangleCount = subMesh0.metalKitSubmesh.indexCount / 3
        
        argumentEncoder.setBuffer(verticesBuffer.buffer, offset: verticesBuffer.offset, index:  Int(verticesBinding))
        argumentEncoder.setBuffer(indicesBuffer.buffer, offset: indicesBuffer.offset, index: Int(indicesBinding))
        resources.append((resource: verticesBuffer.buffer, usage: .read))
        resources.append((resource: indicesBuffer.buffer, usage: .read))
    }
    
    private func renderVertexFragment(stageId: UUID, vertexStageIndex: UInt32, fragmentStageIndex: UInt32, geometry: JelloPreviewGeometry, vertexShader: SpirvShader, fragmentShader: SpirvShader, computeTextureResources: Set<UUID>) throws -> Data {
        if device == nil {
            initializeSharedResources()
        }
        
        var mtlResources: [(resource: any MTLResource, usage: MTLResourceUsage, stages: MTLRenderStages)] = []

        // TODO: Cache textures if a dependency of timeVarying or transform dependant functions
        var textures: [(JelloPersistedTextureResource, MTLTexture)] = []
        for resource in computeTextureResources {
            let id = resource
            if let texture = (try modelContext.fetch(FetchDescriptor<JelloPersistedTextureResource>(predicate: #Predicate { $0.uuid == id }))).first {
                if let textureDefinition = vertexShader.inputComputeTextures.first(where: { $0.texture.originatingStage == texture.originatingStage && $0.texture.originatingPass == texture.originatingPass }) ??
                    fragmentShader.inputComputeTextures.first(where: { $0.texture.originatingStage == texture.originatingStage && $0.texture.originatingPass == texture.originatingPass }) {
                    textures.append(((texture,try loadTexture(textureDefinition: textureDefinition.texture, texture: texture.texture ?? Data()))))
                }
            }
        }
        
        let vertexKey = ShaderKey(stageId: stageId, index: vertexStageIndex)
        let fragmentKey = ShaderKey(stageId: stageId, index: fragmentStageIndex)
        
        let vertexMsl: MslSpirvShaderOutput = try compiledSpirv[vertexKey] ?? compileMSLShader(input: vertexShader)
        let fragmentMsl: MslSpirvShaderOutput = try compiledSpirv[fragmentKey] ?? compileMSLShader(input: fragmentShader)
        compiledSpirv[vertexKey] = vertexMsl
        compiledSpirv[fragmentKey] = fragmentMsl
        let maybeVertexShaderLib = shaderLibs[vertexKey]
        let maybeFragmentShaderLib = shaderLibs[fragmentKey]
        
        let vertexShaderLib = if let vertexShaderLib = maybeVertexShaderLib {
            vertexShaderLib
        } else {
            switch vertexMsl {
            case .vertex(let v):
                try device!.makeLibrary(source: v.shader, options: MTLCompileOptions())
            default:
                fatalError("Unexpected shader type")
            }
        }
        
        let fragmentShaderLib = if let fragmentShaderLib = maybeFragmentShaderLib {
            fragmentShaderLib
        } else {
            switch fragmentMsl {
            case .fragment(let f):
                try device!.makeLibrary(source: f.shader, options: MTLCompileOptions())
            default:
                fatalError("Unexpected shader type")
            }
        }
        
        shaderLibs[vertexKey] = vertexShaderLib
        shaderLibs[fragmentKey] = fragmentShaderLib
        
        let vertexMain = vertexShaderLib.makeFunction(name: "vertexMain")
        let fragmentMain = fragmentShaderLib.makeFunction(name: "fragmentMain")
    
        var frameDataBuffer = device!.makeBuffer(length: MemoryLayout<FrameDataC>.size, options: MTLResourceOptions.storageModeShared)!
        var frameData = frameDataBuffer.contents().load(as: FrameDataC.self)
        frameData.ambientLightColor = vector_float3(0.05, 0.05, 0.05)
        let fov: Float = 60.0 * (.pi / 180.0)
        let farPlane: Float = 4.0
        let nearPlane: Float = 1.0
        frameData.projectionMatrix = matrix_perspective_left_hand(fovyRadians: fov, aspectRatio: 1, nearZ: nearPlane, farZ: farPlane)
        frameData.projectionMatrixInv = frameData.projectionMatrix.inverse
        
        // Set screen dimensions.
        frameData.framebufferWidth = UInt32(256)
        frameData.framebufferHeight = UInt32(256)

        frameData.depthUnproject = vector2(farPlane / (farPlane - nearPlane), (-farPlane * nearPlane) / (farPlane - nearPlane))

        let directionalLightDirection = vector_float3(1.0, -1.0, 1.0)
        frameData.directionalLightDirection = directionalLightDirection

        // Update directional light color.
        let directionalLightColor = vector_float3(0.4, 0, 0.2)
        frameData.directionalLightColor = directionalLightColor
        
        let fovScale = tanf(0.5 * fov) * 2.0;
        let aspectRatio = Float(frameData.framebufferWidth) / Float(frameData.framebufferHeight)
        frameData.screenToViewSpace = vector_float3(fovScale / Float(frameData.framebufferHeight), -fovScale * 0.5 * aspectRatio, -fovScale * 0.5)

        // Calculate new view matrix and inverted view matrix.
        frameData.viewMatrix = matrix_multiply(matrix4x4_translation(-0, -0.3, 3),
                                               matrix_multiply(matrix4x4_rotation(radians: 0, axis: vector_float3(1,0,0)),
                                                               matrix4x4_rotation(radians: 0, axis:vector_float3(0,1,0))))
        frameData.viewMatrixInv = frameData.viewMatrix.inverse

        let rotationAxis = vector_float3(0, 1, 0);
        var modelMatrix = matrix4x4_rotation(radians:0, axis: rotationAxis)
        let translation = matrix4x4_translation(0.0, 0, 0)
        modelMatrix = matrix_multiply(modelMatrix, translation)

        frameData.modelViewMatrix = matrix_multiply(frameData.viewMatrix, modelMatrix)
        frameData.modelMatrix = modelMatrix

        frameData.normalMatrix = matrix3x3_upper_left(frameData.modelViewMatrix)
        frameData.normalMatrix = frameData.normalMatrix.transpose.inverse


        withUnsafePointer(to: frameData){
            frameDataBuffer.contents().copyMemory(from: $0, byteCount: MemoryLayout<FrameDataC>.size)
        }
        
        
        
        var vertexTextureArgumentBuffer: (any MTLBuffer)? = nil
        var fragmentTextureArgumentBuffer: (any MTLBuffer)? = nil
        var vertexFrameDataArgumentBuffer: (any MTLBuffer)? = nil
        var fragmentFrameDataArgumentBuffer: (any MTLBuffer)? = nil


        switch vertexMsl {
        case .vertex(let v):
            let computeTextureInputs = v.inputComputeTextures.filter({$0.bufferIndex == computeTextureInputOutputDescriptorSet })
            if computeTextureInputs.count > 0 {
                let vertexTextureInputOutputEncoder = vertexMain!.makeArgumentEncoder(bufferIndex: Int(computeTextureInputOutputDescriptorSet))
                vertexTextureArgumentBuffer = device!.makeBuffer(length: vertexTextureInputOutputEncoder.encodedLength)!
                vertexTextureInputOutputEncoder.setArgumentBuffer(vertexTextureArgumentBuffer!, offset: 0)
                mtlResources.append((resource: vertexTextureArgumentBuffer!, usage: [MTLResourceUsage.read, MTLResourceUsage.write], stages: .vertex))
                for computeTextureInput in computeTextureInputs {
                    let t = textures.first(where: {$0.0.originatingPass == computeTextureInput.texture.originatingPass && $0.0.originatingStage == computeTextureInput.texture.originatingStage })
                    vertexTextureInputOutputEncoder.setTexture(t!.1, index: Int(computeTextureInput.bufferBindingIndex))
                    mtlResources.append((resource: t!.1, usage: MTLResourceUsage.read, stages: .vertex))
                    if computeTextureInput.sampled {
                        let samplerDesc = MTLSamplerDescriptor();
                        samplerDesc.minFilter = .linear;
                        samplerDesc.magFilter = .linear;
                        samplerDesc.mipFilter = .notMipmapped;
                        samplerDesc.normalizedCoordinates = true;
                        samplerDesc.supportArgumentBuffers = true;
                        
                        let sampler = device!.makeSamplerState(descriptor: samplerDesc)
//                        mtlResources.append((resource: sampler!, usage: MTLResourceUsage.read, stages: [MTLRenderStages.vertex]))
                        // We assume that the sampler is bound to the next index as the texture
                        vertexTextureInputOutputEncoder.setSamplerState(sampler, index: Int(computeTextureInput.bufferBindingIndex) + 1)
                        
                    }
                }
            }
            if let idx = v.frameDataBindingIndex {
                let vertexFrameDataEncoder = vertexMain!.makeArgumentEncoder(bufferIndex: Int(frameDataDescriptorSet))
                vertexFrameDataArgumentBuffer = device!.makeBuffer(length: vertexFrameDataEncoder.encodedLength)!
                vertexFrameDataEncoder.setArgumentBuffer(vertexFrameDataArgumentBuffer, offset: 0)
                vertexFrameDataEncoder.setBuffer(frameDataBuffer, offset: 0, index: Int(idx))
                mtlResources.append((resource: frameDataBuffer, usage: [MTLResourceUsage.read], stages: [.fragment]))
            }
        default:
            fatalError("Unexpected shader type")
        }
        
        switch fragmentMsl {
        case .fragment(let f):
            let computeTextureInputs = f.inputComputeTextures.filter({UInt32($0.bufferIndex) == computeTextureInputOutputDescriptorSet })
            if computeTextureInputs.count > 0 {
                let fragmentTextureInputOutputEncoder = fragmentMain!.makeArgumentEncoder(bufferIndex: Int(computeTextureInputOutputDescriptorSet))
                fragmentTextureArgumentBuffer = device!.makeBuffer(length: fragmentTextureInputOutputEncoder.encodedLength)!
                mtlResources.append((resource: fragmentTextureArgumentBuffer!, usage: [MTLResourceUsage.read, MTLResourceUsage.write], stages: .fragment))
                fragmentTextureInputOutputEncoder.setArgumentBuffer(fragmentTextureArgumentBuffer, offset: 0)
                for computeTextureInput in computeTextureInputs {
                    let t = textures.first(where: {$0.0.originatingPass == computeTextureInput.texture.originatingPass && $0.0.originatingStage == computeTextureInput.texture.originatingStage })
                    fragmentTextureInputOutputEncoder.setTexture(t!.1, index: Int(computeTextureInput.bufferBindingIndex))
                    mtlResources.append((resource: t!.1, usage: [MTLResourceUsage.read], stages: .fragment))
                    
                    if computeTextureInput.sampled {
                        let samplerDesc = MTLSamplerDescriptor();
                        samplerDesc.minFilter = .linear;
                        samplerDesc.magFilter = .linear;
                        samplerDesc.mipFilter = .notMipmapped;
                        samplerDesc.normalizedCoordinates = true;
                        samplerDesc.supportArgumentBuffers = true;
                        
                        let sampler = device!.makeSamplerState(descriptor: samplerDesc)
//                        mtlResources.append((resource: sampler!, usage: [MTLResourceUsage.read], stages: .fragment))
                        // We assume that the sampler is bound to the next index as the texture
                        fragmentTextureInputOutputEncoder.setSamplerState(sampler, index: Int(computeTextureInput.bufferBindingIndex) + 1)
                    }
                }
            }
            if let idx = f.frameDataBindingIndex {
                let fragmentFrameDataEncoder = fragmentMain!.makeArgumentEncoder(bufferIndex: Int(frameDataDescriptorSet))
                fragmentFrameDataArgumentBuffer =  device!.makeBuffer(length: fragmentFrameDataEncoder.encodedLength)!
                mtlResources.append((resource: fragmentFrameDataArgumentBuffer!, usage: MTLResourceUsage.read, stages: [.fragment]))
                mtlResources.append((resource: frameDataBuffer, usage: MTLResourceUsage.read, stages: [.fragment]))

                fragmentFrameDataEncoder.setArgumentBuffer(fragmentFrameDataArgumentBuffer, offset: 0)
                fragmentFrameDataEncoder.setBuffer(frameDataBuffer, offset: 0, index: Int(idx))
            }
        default:
            fatalError("Unexpected shader type")
        }
        
        let texDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = .type2D
        texDescriptor.width = 256
        texDescriptor.height = 256
        texDescriptor.depth = 1
        texDescriptor.pixelFormat = .rgba32Float
        texDescriptor.storageMode = .shared
        texDescriptor.usage = [.renderTarget, .shaderRead]
        let tex = device!.makeTexture(descriptor: texDescriptor)!
        
        let depthTexDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
        depthTexDescriptor.textureType = .type2D
        depthTexDescriptor.width = 256
        depthTexDescriptor.height = 256
        depthTexDescriptor.depth = 1
        depthTexDescriptor.pixelFormat = .depth32Float
        depthTexDescriptor.usage = .renderTarget
        texDescriptor.storageMode = .memoryless
        let depthTex = device!.makeTexture(descriptor: depthTexDescriptor)!
        
        let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()

        renderPipelineStateDescriptor.vertexDescriptor = self.vertexFragVertexDescriptor!
        renderPipelineStateDescriptor.rasterSampleCount = Int(1)

        renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = texDescriptor.pixelFormat
        renderPipelineStateDescriptor.depthAttachmentPixelFormat = depthTexDescriptor.pixelFormat
        renderPipelineStateDescriptor.vertexFunction = vertexMain
        renderPipelineStateDescriptor.fragmentFunction = fragmentMain
        let pipelineState: MTLRenderPipelineState = try device!.makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)

        let renderToTextureRenderPassDescriptor = MTLRenderPassDescriptor()
        renderToTextureRenderPassDescriptor.colorAttachments[0].texture = tex
        renderToTextureRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderToTextureRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderToTextureRenderPassDescriptor.colorAttachments[0].storeAction = .store
        renderToTextureRenderPassDescriptor.depthAttachment.loadAction = .clear
        renderToTextureRenderPassDescriptor.depthAttachment.texture = depthTex
        renderToTextureRenderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderToTextureRenderPassDescriptor.stencilAttachment.loadAction = .clear
        renderToTextureRenderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderToTextureRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderToTextureRenderPassDescriptor.stencilAttachment.clearStencil = 0
        
        let queue = device!.makeCommandQueue()!
        let commandBuffer = queue.makeCommandBuffer()!
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        

        // Create a depth state with depth buffer write enabled.
                
        // Create a depth state with depth buffer write disabled and set the comparison function to
        //   `MTLCompareFunctionLess`.
        
        depthStateDesc.depthCompareFunction = .lessEqual
        depthStateDesc.isDepthWriteEnabled = true
        let depthState = device!.makeDepthStencilState(descriptor: depthStateDesc)!
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderToTextureRenderPassDescriptor)!
        renderEncoder.setCullMode(.back)
   
        for mtlResource in mtlResources {
            renderEncoder.useResource(mtlResource.resource, usage: mtlResource.usage, stages: mtlResource.stages)
        }
        // Render objects with lighting.
        renderEncoder.pushDebugGroup("Render Preview")
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        //                            renderEncoder.setFragmentBuffer(frameDataBuffers[currentBufferIndex], offset:0, index: 2)
        

        if let vertexTextureArgumentBuffer = vertexTextureArgumentBuffer {
            renderEncoder.setVertexBuffer(vertexTextureArgumentBuffer, offset: 0, index: Int(computeTextureInputOutputDescriptorSet))
        }
        if let fragmentTextureArgumentBuffer = fragmentTextureArgumentBuffer {
            renderEncoder.setFragmentBuffer(fragmentTextureArgumentBuffer, offset: 0, index: Int(computeTextureInputOutputDescriptorSet))
        }
        if let vertexFrameDataArgumentBuffer = vertexFrameDataArgumentBuffer {
            renderEncoder.setVertexBuffer(vertexFrameDataArgumentBuffer, offset: 0, index: Int(frameDataDescriptorSet))
        }
        if let fragmentFrameDataArgumentBuffer = fragmentFrameDataArgumentBuffer {
            renderEncoder.setFragmentBuffer(fragmentFrameDataArgumentBuffer, offset: 0, index: Int(frameDataDescriptorSet))
        }

//        let meshes = if let geo = self.previewGeometry[geometry] {
//            geo
//        } else {
//            try loadPreviewGeometry(geometry, modelIOVertexDescriptor: computeModelIOVertexDescriptor!, device: device!)
//        }
//        self.previewGeometry[geometry] = meshes
        
        let meshes = try loadPreviewGeometry(geometry, modelIOVertexDescriptor: vertFragModelIOVertexDescriptor!, device: device!)
        
        for msh in meshes {
            let metalKitMesh = msh.metalKitMesh
            
            // Set the mesh's vertex buffers.
            for bufferIndex in 0..<metalKitMesh.vertexBuffers.count {
                let vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
                if(vertexBuffer.length > 0){
                    renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset:vertexBuffer.offset, index:bufferIndex);
                }
            }
            
            // Draw each submesh of the mesh.
            for submesh in msh.submeshes
            {
                // Set any textures that you read or sample in the render pipeline.
                
                let metalKitSubmesh = submesh.metalKitSubmesh;
                
                renderEncoder.drawIndexedPrimitives(type: metalKitSubmesh.primitiveType,
                                                    indexCount:metalKitSubmesh.indexCount,
                                                    indexType:metalKitSubmesh.indexType,
                                                    indexBuffer:metalKitSubmesh.indexBuffer.buffer,
                                                    indexBufferOffset:metalKitSubmesh.indexBuffer.offset
                );
            }
        }
        
        renderEncoder.popDebugGroup();
        
        renderEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Update frame stage
        return tex.pngData
    }
    
    private func renderCompute(stageId: UUID, stageIndex: UInt32, geometry: JelloPreviewGeometry?, shader: SpirvShader, computeTextureResources: Set<UUID>) throws -> Data {
        if device == nil {
            initializeSharedResources()
        }
        
        var mtlResources: [(resource: any MTLResource, usage: MTLResourceUsage)] = []
        
        // TODO: Cache textures if a dependency of timeVarying or transform dependant functions
        var textures: [(JelloPersistedTextureResource, MTLTexture)] = []
        for resource in computeTextureResources {
            let id = resource
            if let texture = (try modelContext.fetch(FetchDescriptor<JelloPersistedTextureResource>(predicate: #Predicate { $0.uuid == id }))).first {
                if let textureDefinition = shader.inputComputeTextures.first(where: { $0.texture.originatingStage == texture.originatingStage && $0.texture.originatingPass == texture.originatingPass }) {
                    textures.append(((texture, try loadTexture(textureDefinition: textureDefinition.texture, texture: texture.texture ?? Data()))))
                }
            }
        }
        
        let key = ShaderKey(stageId: stageId, index: stageIndex)
        let msl: MslSpirvShaderOutput = try compiledSpirv[key] ?? compileMSLShader(input: shader)
        compiledSpirv[key] = msl
        let maybeShaderLib = shaderLibs[key]
        
        let shaderLib = if let shaderLib = maybeShaderLib {
            shaderLib
        } else {
            switch msl {
            case .compute(let c):
                try device!.makeLibrary(source: c.shader, options: MTLCompileOptions())
            case .computeRasterizer(let r):
                try device!.makeLibrary(source: r.shader, options: MTLCompileOptions())
            default:
                fatalError("Unexpected shader type")
            }
        }
        
        shaderLibs[key] = shaderLib
        let computeMain = shaderLib.makeFunction(name: "computeMain")
        var geometryArgumentBuffer: (any MTLBuffer)? = nil
        
        var triangleCount: Int = 0
        // Bind geometry and triangle index input texture
        switch msl {
        case .compute(let c):
            if let indicesBindingIndex = c.indicesBindingIndex,
               let verticesBindingIndex = c.verticesBindingIndex {
                var geometryArgumentEncoder = computeMain!.makeArgumentEncoder(bufferIndex: Int(geometryInputDescriptorSet))
                
                geometryArgumentBuffer = device!.makeBuffer(length: geometryArgumentEncoder.encodedLength)!
                geometryArgumentEncoder.setArgumentBuffer(geometryArgumentBuffer!, offset: 0)
                mtlResources.append((resource: geometryArgumentBuffer!, usage: [.read]))

                try bindGeometry(geometry: geometry!, triangleCount: &triangleCount, resources: &mtlResources, argumentEncoder: &geometryArgumentEncoder, indicesBinding: indicesBindingIndex, verticesBinding: verticesBindingIndex)
                
                let geometryTextures = c.inputComputeTextures.filter({$0.bufferIndex == geometryInputDescriptorSet })
                for geometryTexture in geometryTextures {
                    let t = textures.first(where: {$0.0.originatingPass == geometryTexture.texture.originatingPass && $0.0.originatingStage == geometryTexture.texture.originatingStage })
                    geometryArgumentEncoder.setTexture(t!.1, index: Int(geometryTexture.bufferBindingIndex))
                    assert(!geometryTexture.sampled, "Geometry Textures should never be sampled")
                    mtlResources.append((resource: t!.1, usage: [.read, .write]))
                }
            }
        case .computeRasterizer(let r):
            if let indicesBindingIndex = r.indicesBindingIndex,
               let verticesBindingIndex = r.verticesBindingIndex {
                var geometryArgumentEncoder = computeMain!.makeArgumentEncoder(bufferIndex: Int(geometryInputDescriptorSet))
                
                geometryArgumentBuffer = device!.makeBuffer(length: geometryArgumentEncoder.encodedLength)!
                geometryArgumentEncoder.setArgumentBuffer(geometryArgumentBuffer!, offset: 0)
                mtlResources.append((resource: geometryArgumentBuffer!, usage: .read))

                try bindGeometry(geometry: geometry!, triangleCount: &triangleCount, resources: &mtlResources, argumentEncoder: &geometryArgumentEncoder, indicesBinding: indicesBindingIndex, verticesBinding: verticesBindingIndex)
           
            }
        default:
            fatalError("Unexpected shader type")
        }
        
        
        let outputTexture: MTLTexture = switch msl {
        case .compute(let c):
            try makeOutputTexture(texDefn: c.outputComputeTexture)
        case .computeRasterizer(let r):
            try makeOutputTexture(texDefn: r.outputComputeTexture)
        default:
            fatalError("Unexpected shader type")
        }
        
        let computeTextureInputOutputEncoder = computeMain!.makeArgumentEncoder(bufferIndex: Int(computeTextureInputOutputDescriptorSet))
        let computeTextureInputOutputArgumentBuffer = device!.makeBuffer(length: computeTextureInputOutputEncoder.encodedLength)!
        computeTextureInputOutputEncoder.setArgumentBuffer(computeTextureInputOutputArgumentBuffer, offset: 0)
        mtlResources.append((resource: computeTextureInputOutputArgumentBuffer, usage: [MTLResourceUsage.read, MTLResourceUsage.write]))
        mtlResources.append((resource: outputTexture, usage: MTLResourceUsage.write))
        
        switch msl {
        case .compute(let c):
            let computeTextureInputs = c.inputComputeTextures.filter({$0.bufferIndex == computeTextureInputOutputDescriptorSet })
            for computeTextureInput in computeTextureInputs {
                let t = textures.first(where: {$0.0.originatingPass == computeTextureInput.texture.originatingPass && $0.0.originatingStage == computeTextureInput.texture.originatingStage })
                computeTextureInputOutputEncoder.setTexture(t!.1, index: Int(computeTextureInput.bufferBindingIndex))
                mtlResources.append((resource: t!.1, usage: MTLResourceUsage.read))
                if computeTextureInput.sampled {
                    let samplerDesc = MTLSamplerDescriptor();
                    samplerDesc.minFilter = .linear;
                    samplerDesc.magFilter = .linear;
                    samplerDesc.mipFilter = .notMipmapped;
                    samplerDesc.normalizedCoordinates = true;
                    samplerDesc.supportArgumentBuffers = true;
                    
                    let sampler = device!.makeSamplerState(descriptor: samplerDesc)
                    // We assume that the sampler is bound to the next index as the texture
                    computeTextureInputOutputEncoder.setSamplerState(sampler, index: Int(computeTextureInput.bufferBindingIndex) + 1)
                }
            }
            computeTextureInputOutputEncoder.setTexture(outputTexture, index: Int(c.outputComputeTexture.bufferBindingIndex))
        case .computeRasterizer(let r):
            computeTextureInputOutputEncoder.setTexture(outputTexture, index: Int(r.outputComputeTexture.bufferBindingIndex))
        default:
            break // Do nothing
        }
        
        let pipelineState: MTLComputePipelineState = try device!.makeComputePipelineState(function: computeMain!)
        
        
        let commandQueue: MTLCommandQueue = device!.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        
        var threadgroupSize: MTLSize = MTLSizeMake(128, 1, 1)
        var threads: MTLSize = MTLSizeMake(1, 1, 1)
        
        switch shader {
        case .compute(_):
            if outputTexture.width == 1 && outputTexture.depth == 1 {
                threads.width = outputTexture.width
            } else if outputTexture.depth == 1 {
                threadgroupSize.width = 16
                threadgroupSize.height = 8
                threads.width = outputTexture.width
                threads.height = outputTexture.height
            } else {
                threadgroupSize.width = 8
                threadgroupSize.height = 4
                threadgroupSize.depth = 4
                threads.width = outputTexture.width
                threads.height = outputTexture.height
                threads.depth = outputTexture.depth
            }
        case .computeRasterizer(_):
            threads.width = triangleCount
        default:
            fatalError("Unexpected Shader")
        }

        for mtlResource in mtlResources {
            computeEncoder.useResource(mtlResource.resource, usage: mtlResource.usage)
        }
        computeEncoder.setBuffer(computeTextureInputOutputArgumentBuffer, offset: 0, index: Int(computeTextureInputOutputDescriptorSet))
        if let geometryArgumentBuffer = geometryArgumentBuffer {
            computeEncoder.setBuffer(geometryArgumentBuffer, offset: 0, index: Int(geometryInputDescriptorSet))
        }
        
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return try convertTextureToData(texture: outputTexture)
    }
    
    
    func compileAndDispatchComputeShaders(_ modelContainer: ModelContainer,  graphId: UUID) async throws {
        let graph = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloGraph>{ $0.uuid == graphId })).first!
        let nodes = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.graph?.uuid == graphId }))
        let edges = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge>{ $0.graph?.uuid == graphId }))
        let data = try modelContext.fetch(FetchDescriptor<JelloNodeData>()).filter({$0.node?.graph?.uuid == graphId})
        let inputPorts = try modelContext.fetch(FetchDescriptor<JelloInputPort>(sortBy: [SortDescriptor(\JelloInputPort.index)])).filter({$0.node?.graph?.uuid == graphId})
        let outputPorts = try modelContext.fetch(FetchDescriptor<JelloOutputPort>(sortBy: [SortDescriptor(\JelloOutputPort.index)])).filter({$0.node?.graph?.uuid == graphId})
        let encoder = PropertyListEncoder()

        // TODO: Cater for material output node as well
        let previewNodes = nodes.filter({$0.nodeType == .builtIn(.preview)})
        var stages: Set<JelloCompilerOutputStage> = []
        var geometry: [UUID: Set<JelloPreviewGeometry>] = [:]
        for previewNode in previewNodes {
            let thisPreviewGeometry: JelloPreviewGeometry = .sphere
            let graphInput = JelloCompilerBridge.buildGraphInput(outputNode: previewNode, jelloGraph: graph, jelloNodes: nodes, jelloNodeData: data, jelloEdges: edges, jelloInputPorts: inputPorts, jelloOutputPorts: outputPorts)
            if let result = try? JelloCompilerStatic.compileToSpirv(input: graphInput) {
                stages.formUnion(result.stages)
                for stage in result.stages {
                    if stage.domain.contains(CompilerComputationDomain.modelDependant) || stage.domain.contains(CompilerComputationDomain.transformDependant)  {
                        if geometry[stage.id] == nil {
                            geometry[stage.id] = []
                        }
                        geometry[stage.id]!.insert(thisPreviewGeometry)
                    }
                }
            }
            try Task.checkCancellation()
        }
        
        
        var resourceIds: [UUID: [[Data: Set<UUID>]]] = [:]
        // Add JelloPersistedStageShader references to every stage
        for stage in stages {
            let stageId = stage.id
            resourceIds[stageId] = []
            for shaderIndex in stage.shaders.indices {
                let index = UInt32(shaderIndex)
                let persistedShaders = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId && $0.stageId == stageId && $0.index == index && $0.created != nil }, sortBy: [.init(\JelloPersistedStageShader.created)]))
                var wedges: [Data] = []
                if let geometries = geometry[stageId] {
                    wedges = geometries.map({ self.calculateWedgeSha256(encoder: encoder, geometry: $0)})
                } else {
                    wedges = [Data()]
                }
                for wedgeSha256 in wedges {
                    var persistedShader = persistedShaders.first(where: { $0.wedgeSha256 == wedgeSha256 })
                    if persistedShader == nil {
                        persistedShader = JelloPersistedStageShader(graphId: graphId, stageId: stageId, index: index, wedgeSha256: wedgeSha256, shaderSha256: Data(), argsSha256: Data(), created: Date.now)
                        modelContext.insert(persistedShader!)
                    }
                    resourceIds[stageId]?.append([wedgeSha256: Set(persistedShader!.resources)])
                }
            }
        }
        
        // Clean up unused stages & wedges
        var persistedStages = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId && $0.created != nil }, sortBy: [.init(\JelloPersistedStageShader.created)]))
        for persistedStageIndex in persistedStages.indices.reversed() {
            let persistedStage = persistedStages[persistedStageIndex]
            if resourceIds[persistedStage.stageId] == nil {
                modelContext.delete(persistedStage)
                persistedStages.remove(at: persistedStageIndex)
            } else if let geometry = geometry[persistedStage.stageId] {
                let wedgesSet =  Set<Data>(geometry.map({ self.calculateWedgeSha256(encoder: encoder, geometry: $0) }))
                if !wedgesSet.contains(persistedStage.wedgeSha256) {
                    modelContext.delete(persistedStage)
                    persistedStages.remove(at: persistedStageIndex)
                }
            } else if persistedStage.wedgeSha256 != Data() {
                modelContext.delete(persistedStage)
                persistedStages.remove(at: persistedStageIndex)
            }
        }

        
        let stagesDict: [UUID: JelloCompilerOutputStage] = stages.reduce(into: [:], { dict, stage in dict[stage.id] = stage })
    
        
        while true {
            var visitedStages: Set<UUID> = []
            func hasNoDependencies(stage: JelloCompilerOutputStage) -> Bool {
                return stage.dependencies.filter({ dependency in
                    return !visitedStages.contains(dependency) && dependency != stage.id
                }).isEmpty
            }
            var noDependencyStages: [JelloCompilerOutputStage] = stages.filter({ hasNoDependencies(stage: $0) })
            var i = 0
            // TODO: Execute these in parallel
            while i < noDependencyStages.count {
                let item = noDependencyStages[i]
                visitedStages.insert(item.id)
                let stageId = item.id
                var persistedShadersFetchDescriptor = FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId && $0.stageId == stageId && $0.created != nil }, sortBy: [.init(\JelloPersistedStageShader.created)])
                persistedShadersFetchDescriptor.includePendingChanges = true
                let persistedShaders = try modelContext.fetch(persistedShadersFetchDescriptor)
                let isVertexFragStage = item.shaders.contains(where: {
                    switch $0 {
                    case .fragment(_), .vertex(_):
                        return true
                    default:
                        return false
                    }
                })
                func updateDependantShaderStagesAndFreeResources(renderResult: Data, persistedShader: JelloPersistedStageShader, shaderSha256: Data, argsSha256: Data) throws {
                    try modelContext.transaction {
                        persistedShader.argsSha256 = argsSha256
                        persistedShader.shaderSha256 = shaderSha256
                        let maybeOldId = persistedShader.output?.uuid
                        let wedgeSha256 = persistedShader.wedgeSha256
                        let texture = JelloPersistedTextureResource(uuid: UUID(), texture: renderResult, originatingStage: stageId, originatingPass: persistedShader.index, wedgeSha256: wedgeSha256, created: Date.now)
                        modelContext.insert(texture)
                        persistedShader.output = texture
                        // Bind resource to successor stages
                        var possibleDependants = item.dependants
                        // Add self as a dependency for inter shader dependencies
                        possibleDependants.insert(stageId)
                        
                        for possibleDependant in possibleDependants {
                            if let stage = stagesDict[possibleDependant] {
                                for shaderIndex in stage.shaders.indices {
                                    let inputs = stage.shaders[shaderIndex].inputComputeTextures
                                    if inputs.contains(where: { $0.texture.originatingPass == persistedShader.index && $0.texture.originatingStage == stageId }) {
                                        let dependantIndex = UInt32(shaderIndex)
                                        let dependantStageId = possibleDependant
                                        let dependantShader = try modelContext.fetch(FetchDescriptor<JelloPersistedStageShader>(predicate: #Predicate { $0.index == dependantIndex && $0.stageId == dependantStageId && $0.created != nil })).first
                                        dependantShader!.resources.append(texture.uuid)
                                    }
                                }
                            }
                        }
                        // Unbind old resource from all stages
                        if let oldId = maybeOldId {
                            let oldOutput = try modelContext.fetch(FetchDescriptor<JelloPersistedTextureResource>(predicate: #Predicate { $0.uuid == oldId })).first
                            modelContext.delete(oldOutput!)
                            let dependantShaders = try modelContext.fetch(FetchDescriptor<JelloPersistedStageShader>(predicate: #Predicate { $0.graphId == graphId }))
                            for shader in dependantShaders {
                                shader.resources = shader.resources.filter({ $0 != oldId })
                            }
                        }
                    }
                }
                if isVertexFragStage {
                    if let geometries = geometry[item.id] {
                        for geometry in geometries {
                            let wedgeSha256 = calculateWedgeSha256(encoder: encoder, geometry: geometry)
                            let fragmentIndex = UInt32(item.shaders.firstIndex(where: {
                                switch $0 {
                                case .fragment(_):
                                    return true
                                default:
                                    return false
                                }
                            }) ?? 0)
                            let vertexIndex = UInt32(item.shaders.firstIndex(where: {
                                switch $0 {
                                case .vertex(_):
                                    return true
                                default:
                                    return false
                                }
                            }) ?? 0)
                            


                            if let persistedShader = persistedShaders.first(where: { $0.index == fragmentIndex && $0.wedgeSha256 == wedgeSha256 }) {
                                // TODO: Insert Variable Args here
                                let argsSha256 = Data()
                                let shaderSha256 = item.shaders[Int(fragmentIndex)].shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                                let currentResources = Set(persistedShader.resources)
                                let renderResult = try! renderVertexFragment(stageId: stageId, vertexStageIndex: vertexIndex, fragmentStageIndex: fragmentIndex, geometry: geometry, vertexShader: item.shaders[Int(vertexIndex)], fragmentShader: item.shaders[Int(fragmentIndex)], computeTextureResources: currentResources)
                                try updateDependantShaderStagesAndFreeResources(renderResult: renderResult, persistedShader: persistedShader, shaderSha256: shaderSha256, argsSha256: argsSha256)
                            }
                            
                            if let persistedShader = persistedShaders.first(where: {  $0.index == vertexIndex && $0.wedgeSha256 == wedgeSha256 }) {
                                // TODO: Insert Variable Args here
                                let argsSha256 = Data()
                                let shaderSha256 = item.shaders[Int(vertexIndex)].shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                                try modelContext.transaction {
                                    persistedShader.argsSha256 = argsSha256
                                    persistedShader.shaderSha256 = shaderSha256
                                }
                            }
                        }
                    } else {
                        fatalError("Expected vert frag stages to always have associated preview geometry")
                    }
                } else {
                    for shaderIndex in item.shaders.indices {
                        let index = UInt32(shaderIndex)
                        let shader = item.shaders[shaderIndex]
                        let shaderSha256 = shader.shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                        var argsSha256 = Data()
                        let domain = shader.domain
                        // TODO: Insert Variable Args here
                        switch shader {
                        case .compute(let c):
                            argsSha256 = try encoder.encode(c.outputComputeTexture).sha256()
                        case .computeRasterizer(let r):
                            argsSha256 = try encoder.encode(r.outputComputeTexture).sha256()
                        default:
                            fatalError("Unexpected shader type")
                        }
                        
                        let prevResources: [Data: Set<UUID>] = resourceIds[stageId]?[shaderIndex] ?? [:]
                        var wedges: [(Data, JelloPreviewGeometry?)] = []

                        if let previewGeometries = geometry[item.id] {
                            wedges = previewGeometries.map({ (calculateWedgeSha256(encoder: encoder, geometry: $0), $0) })
                        } else {
                            let wedgeSha256 = Data()
                            wedges.append((wedgeSha256, nil))
                        }
                        for wedgeAndGeometry in wedges {
                            let wedgeSha256 = wedgeAndGeometry.0
                            let geometry = wedgeAndGeometry.1
                            
                            if let persistedShader = persistedShaders.first(where: { $0.index == index && $0.wedgeSha256 == wedgeSha256 }) {
                                let currentResources = Set(persistedShader.resources)
                                func isDirty() -> Bool {
                                    let isTimeVaryingOrTransformDependant: Bool = !(domain.intersection([.timeVarying, .transformDependant]).isEmpty)
                                    let differentArgsOrShader: Bool = persistedShader.argsSha256 != argsSha256 || persistedShader.shaderSha256 != shaderSha256
                                    let differentResources: Bool = prevResources[wedgeSha256] != currentResources
                                    let dirty: Bool = isTimeVaryingOrTransformDependant || differentArgsOrShader || differentResources || true
                                    return dirty
                                }
                                if isDirty() {
                                    // TODO: Look at how binding inter-stage dependencies should work
                                    let renderResult = try! renderCompute(stageId: stageId, stageIndex: index, geometry: geometry, shader: shader, computeTextureResources: currentResources)
                                    try updateDependantShaderStagesAndFreeResources(renderResult: renderResult, persistedShader: persistedShader, shaderSha256: shaderSha256, argsSha256: argsSha256)
                                }
                            }
                        }
                    }
                }
                
                for successorStage in item.dependants {
                    if successorStage != item.id, let stage = stagesDict[successorStage], stage.id != item.id, hasNoDependencies(stage: stage) {
                        noDependencyStages.append(stage)
                    }
                }
                
                i += 1
                try Task.checkCancellation()
                await Task.yield()
            }
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 16666666)
        }
    }
}


struct JelloPreviewBaker<Child : View> : View {
    @ViewBuilder let child: Child
    let graphId: UUID
    @Environment(\.modelContext) var modelContext

    @Query var graphs: [JelloGraph]
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var data: [JelloNodeData]
    @State var generation: Int = 0
    @Query(sort: \JelloInputPort.index) var inputPorts: [JelloInputPort]
    @Query(sort: \JelloOutputPort.index) var outputPorts: [JelloOutputPort]
    
    init(graphId: UUID, child: @escaping () -> Child) {
        self.child = child()
        self.graphId = graphId
        self._graphs = Query(FetchDescriptor(predicate: #Predicate { $0.uuid == graphId }))
        self._nodes = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
        self._edges = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
    }
    
    private func dataChanged(){
        generation = generation + 1
    }
    
    var body: some View {
        child
            .onChange(of: graphs, initial: true, { _, _ in dataChanged() })
            .onChange(of: nodes, initial: false, { _, _ in dataChanged() })
            .onChange(of: edges, initial: false, { _, _ in dataChanged() })
            .onChange(of: data, initial: false, { _, _ in dataChanged() })
            .onChange(of: inputPorts, initial: false, { _, _ in dataChanged() })
            .onChange(of: outputPorts, initial: false, { _, _ in dataChanged() })
            .task(id: generation, priority: .medium, {
                let container = modelContext.container
                let previewBakerActor = JelloPreviewBakerActor(modelContainer: container)
                try? await previewBakerActor.compileAndDispatchComputeShaders(container, graphId: graphId)
            })
    }
}
