//
//  SpirvGenerator.swift
//  JelloCompiler
//
//  Created by Natalie Cuthbert on 2023/12/07.
//

import Foundation
import SPIRV_Cross
import simd


enum SpirvCompilationError: Error {
    case compilationError(String)
}

class SpirvCompilationErrorContext {
    var errorValue: String? = nil
}

func makeMSLVersion(_ major: UInt32, _ minor: UInt32, _ patch: UInt32 = 0) -> UInt32 {
    (major * 10000) + (minor * 100) + patch;
}

public struct MslSpirvTextureBindingOutput : Codable, Equatable {
    public let texture: JelloComputeIOTexture
    public let bufferIndex: UInt32
    public let bufferBindingIndex: UInt32
    public let sampled: Bool
}

public struct MslSpirvComputeShaderOutput: Codable, Equatable {
    public let shader: String
    public let outputComputeTexture: MslSpirvTextureBindingOutput
    public let inputComputeTextures: [MslSpirvTextureBindingOutput]
    public let verticesBindingIndex: UInt32?
    public let indicesBindingIndex: UInt32?
}

public struct MslSpirvComputeRasterizerShaderOutput: Codable, Equatable {
    public let shader: String
    public let outputComputeTexture: MslSpirvTextureBindingOutput
    public let verticesBindingIndex: UInt32?
    public let indicesBindingIndex: UInt32?
}

public struct MslSpirvVertexShaderOutput: Codable, Equatable {
    public let shader: String
    public let inputComputeTextures: [MslSpirvTextureBindingOutput]
    public let frameDataBindingIndex: UInt32?
}

public struct MslSpirvFragmentShaderOutput: Codable, Equatable {
    public let shader: String
    public let inputComputeTextures: [MslSpirvTextureBindingOutput]
    public let frameDataBindingIndex: UInt32?
}


public enum MslSpirvShaderOutput: Codable, Equatable {
    case computeRasterizer(MslSpirvComputeRasterizerShaderOutput)
    case compute(MslSpirvComputeShaderOutput)
    case vertex(MslSpirvVertexShaderOutput)
    case fragment(MslSpirvFragmentShaderOutput)
    
    var shader: String {
        switch self {
        case .compute(let c):
            c.shader
        case .computeRasterizer(let r):
            r.shader
        case .fragment(let f):
            f.shader
        case .vertex(let v):
            v.shader
        }
    }
}

public func compileMSLShader(input: SpirvShader) throws -> MslSpirvShaderOutput {
    var context : spvc_context? = nil
    var ir: spvc_parsed_ir? = nil
    var compiler_msl : spvc_compiler? = nil
    var result: UnsafePointer<CChar>? = nil
    var options: spvc_compiler_options? = nil
    
    
    var spirvData = input.shader
    spvc_context_create(&context)
    defer {
        // Frees all memory we allocated so far.
        spvc_context_destroy(context);
    }
    
    let errorContext: SpirvCompilationErrorContext = .init()
    let errorContextPointer = Unmanaged.passRetained(errorContext).toOpaque()

    spvc_context_set_error_callback(context, { errorContext, message in
        if let errorContext = errorContext, let message = message {
            let ctx = Unmanaged<SpirvCompilationErrorContext>.fromOpaque(errorContext).takeRetainedValue()
            ctx.errorValue = String(cString: message)
        }
        }, errorContextPointer
    )
    
    spvc_context_parse_spirv(context, &spirvData, spirvData.count, &ir)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    
    spvc_context_create_compiler(context, SPVC_BACKEND_MSL, ir, SPVC_CAPTURE_MODE_TAKE_OWNERSHIP, &compiler_msl)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    
   
    // Modify options.
    spvc_compiler_create_compiler_options(compiler_msl, &options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_VERSION, makeMSLVersion(3, 1, 0))
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_MSL_ARGUMENT_BUFFERS, 1)
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_ARGUMENT_BUFFERS_TIER, 1)
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_PLATFORM, SPVC_MSL_PLATFORM_IOS.rawValue)
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_MSL_FORCE_ACTIVE_ARGUMENT_BUFFER_RESOURCES, 1)
    
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_install_compiler_options(compiler_msl, options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }

    spvc_compiler_compile(compiler_msl, &result)
    
    
    
    var resources: spvc_resources? = nil
    var storageBufferCount = 0
    var storageBufferList: UnsafePointer<spvc_reflected_resource>? = nil

    var imageCount = 0
    var imageList: UnsafePointer<spvc_reflected_resource>? = nil

    var sampledImageCount = 0
    var sampledImageList: UnsafePointer<spvc_reflected_resource>? = nil

//    var uniformCount = 0
//    var uniformList: UnsafePointer<spvc_reflected_resource>? = nil

    
//    var separateImageCount = 0
//    var separateImageList: UnsafePointer<spvc_reflected_resource>? = nil

    spvc_compiler_create_shader_resources(compiler_msl, &resources)
//    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STAGE_INPUT, &inputList, &inputCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STORAGE_BUFFER, &storageBufferList, &storageBufferCount)
//    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &uniformList, &uniformCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STORAGE_IMAGE, &imageList, &imageCount)
//    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_SEPARATE_IMAGE, &separateImageList, &separateImageCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_SAMPLED_IMAGE, &sampledImageList, &sampledImageCount)

    var frameDataBindingIndex: UInt32?

    var verticesBindingIndex: UInt32?
    var indicesBindingIndex: UInt32?
    var outputImageBindingIndex: (UInt32, UInt32, sampled: Bool) = (0, 0, false)
    
    for i in 0..<storageBufferCount {
        let bufferInfo = storageBufferList![i]
        let set = spvc_compiler_get_decoration(compiler_msl, bufferInfo.id, SpvDecorationDescriptorSet)
        let binding = spvc_compiler_get_decoration(compiler_msl, bufferInfo.id, SpvDecorationBinding)
        if set == geometryInputDescriptorSet {
            let resourceBinding = UInt32(Int32(bitPattern: spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, bufferInfo.id)))
            if binding == verticesBinding {
                // Vertex Data
                verticesBindingIndex = resourceBinding
            } else if binding == indicesBinding {
                // Indices
                indicesBindingIndex = resourceBinding
            } 
        } else if set == frameDataDescriptorSet {
            let resourceBinding = UInt32(Int32(bitPattern: spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, bufferInfo.id)))
            if binding == frameDataBinding {
                frameDataBindingIndex = resourceBinding
            }
        }
    }
    
//    for i in 0..<inputCount {
//            print("Inputs")
//            let name: String = inputList?[i] != nil ? String(cString: inputList![i].name) : ""
//            print("ID: \(inputList?[i].id), BaseTypeID: \(inputList?[i].base_type_id), TypeID: \(inputList?[i].type_id), Name: \(name)");
//            print("Set: \(spvc_compiler_get_decoration(compiler_msl, inputList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, inputList![i].id, SpvDecorationBinding))")
//            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, inputList![i].id)
//            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
//    }
    
    var imagesBindingIndices: [UInt32: (UInt32, UInt32, sampled: Bool)] = [:]

    for i in 0..<imageCount {
        let imageInfo = imageList![i]
        let set = spvc_compiler_get_decoration(compiler_msl, imageInfo.id, SpvDecorationDescriptorSet)
        let binding = spvc_compiler_get_decoration(compiler_msl, imageInfo.id, SpvDecorationBinding)
        let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, imageInfo.id)
        if set == computeTextureInputOutputDescriptorSet {
            if binding == computeTextureOutputBinding {
                outputImageBindingIndex = (computeTextureInputOutputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: false)
            } else {
                // Input images
                imagesBindingIndices[imageInfo.id] = (computeTextureInputOutputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: false)
            }
        } else if set == geometryInputDescriptorSet && binding == triangleIndexBinding {
            // Input images
            imagesBindingIndices[imageInfo.id] = (geometryInputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: false)
        }
    }
    
    for i in 0..<sampledImageCount {
        let imageInfo = sampledImageList![i]
        let set = spvc_compiler_get_decoration(compiler_msl, imageInfo.id, SpvDecorationDescriptorSet)
        let binding = spvc_compiler_get_decoration(compiler_msl, imageInfo.id, SpvDecorationBinding)
        let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, imageInfo.id)
        if set == computeTextureInputOutputDescriptorSet {
            if binding == computeTextureOutputBinding {
                outputImageBindingIndex = (computeTextureInputOutputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: true)
            } else {
                // Input images
                imagesBindingIndices[imageInfo.id] = (computeTextureInputOutputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: true)
            }
        } else if set == geometryInputDescriptorSet {
            imagesBindingIndices[imageInfo.id] = (geometryInputDescriptorSet, UInt32(Int32(bitPattern: resourceBinding)), sampled: true)
        }
    }
    
//    for i in 0..<uniformCount {
//            print("Uniform")
//            let name: String = uniformList?[i] != nil ? String(cString: uniformList![i].name) : ""
//            print("ID: \(uniformList?[i].id), BaseTypeID: \(uniformList?[i].base_type_id), TypeID: \(uniformList?[i].type_id), Name: \(name)");
//            print("Set: \(spvc_compiler_get_decoration(compiler_msl, uniformList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, uniformList![i].id, SpvDecorationBinding))")
//            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, uniformList![i].id)
//            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
//    }
    
//    for i in 0..<separateImageCount {
//            print("Separate Image")
//            let name: String = separateImageList?[i] != nil ? String(cString: separateImageList![i].name) : ""
//            print("ID: \(separateImageList?[i].id), BaseTypeID: \(separateImageList?[i].base_type_id), TypeID: \(separateImageList?[i].type_id), Name: \(name)");
//            print("Set: \(spvc_compiler_get_decoration(compiler_msl, separateImageList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, separateImageList![i].id, SpvDecorationBinding))")
//            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, separateImageList![i].id)
//            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
//    }

    
    
    
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    let str = String(cString: result!)
    print("Shader:\n\(str)")
    
    func mapInputBindings(_ inputTextures: [SpirvTextureBinding]) -> [MslSpirvTextureBindingOutput] {
        return inputTextures.map({
            let bufferIndex = imagesBindingIndices[$0.spirvId]?.0 ?? 0
            let bufferBindingIndex = imagesBindingIndices[$0.spirvId]?.1 ?? 0
            let sampled = imagesBindingIndices[$0.spirvId]?.sampled ?? false
            return MslSpirvTextureBindingOutput(texture: $0.texture, bufferIndex: bufferIndex, bufferBindingIndex: bufferBindingIndex, sampled: sampled)
        })
    }
    switch input {
    case .compute(let c):
        return .compute(MslSpirvComputeShaderOutput(shader: str, outputComputeTexture: MslSpirvTextureBindingOutput(texture: c.outputComputeTexture.texture, bufferIndex: outputImageBindingIndex.0, bufferBindingIndex: outputImageBindingIndex.1, sampled: outputImageBindingIndex.sampled), inputComputeTextures: mapInputBindings(c.inputComputeTextures), verticesBindingIndex: UInt32(verticesBindingIndex!), indicesBindingIndex: UInt32(indicesBindingIndex!)))
    case .computeRasterizer(let r):
        return .computeRasterizer(MslSpirvComputeRasterizerShaderOutput(shader: str, outputComputeTexture: MslSpirvTextureBindingOutput(texture: r.outputComputeTexture.texture, bufferIndex: outputImageBindingIndex.0, bufferBindingIndex: outputImageBindingIndex.1, sampled: outputImageBindingIndex.sampled), verticesBindingIndex: UInt32(verticesBindingIndex!), indicesBindingIndex: UInt32(indicesBindingIndex!)))
    case .vertex(let v):
        return .vertex(MslSpirvVertexShaderOutput(shader: str, inputComputeTextures: mapInputBindings(v.inputComputeTextures), frameDataBindingIndex: frameDataBindingIndex))
    case .fragment(let f):
        return .fragment(MslSpirvFragmentShaderOutput(shader: str, inputComputeTextures: mapInputBindings(f.inputComputeTextures), frameDataBindingIndex: frameDataBindingIndex))
    }
    
}



