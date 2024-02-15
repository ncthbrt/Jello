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


public func compileMSLShader(input: SpirvShader) throws -> String  {
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
    
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_VERSION, makeMSLVersion(2, 1, 0))
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_MSL_ARGUMENT_BUFFERS, 1)
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_ARGUMENT_BUFFERS_TIER, 1)
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_PLATFORM, 0)
    
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_install_compiler_options(compiler_msl, options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }

    spvc_compiler_compile(compiler_msl, &result)
    
    
    
    var resources: spvc_resources? = nil
    var inputCount = 0
    var inputList: UnsafePointer<spvc_reflected_resource>? = nil
    var storageBufferCount = 0
    var storageBufferList: UnsafePointer<spvc_reflected_resource>? = nil

    var imageCount = 0
    var imageList: UnsafePointer<spvc_reflected_resource>? = nil

    var sampledImageCount = 0
    var sampledImageList: UnsafePointer<spvc_reflected_resource>? = nil

    var uniformCount = 0
    var uniformList: UnsafePointer<spvc_reflected_resource>? = nil

    
    var separateImageCount = 0
    var separateImageList: UnsafePointer<spvc_reflected_resource>? = nil

    spvc_compiler_create_shader_resources(compiler_msl, &resources)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STAGE_INPUT, &inputList, &inputCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STORAGE_BUFFER, &storageBufferList, &storageBufferCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &uniformList, &uniformCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_STORAGE_IMAGE, &imageList, &imageCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_SEPARATE_IMAGE, &separateImageList, &separateImageCount)
    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_SAMPLED_IMAGE, &sampledImageList, &sampledImageCount)

    
    for i in 0..<storageBufferCount {
        print("Buffers")
        let name: String = storageBufferList?[i] != nil ? String(cString: storageBufferList![i].name) : ""
        print("ID: \(storageBufferList?[i].id), BaseTypeID: \(storageBufferList?[i].base_type_id), TypeID: \(storageBufferList?[i].type_id), Name: \(name)");
        print("Set: \(spvc_compiler_get_decoration(compiler_msl, storageBufferList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, storageBufferList![i].id, SpvDecorationBinding))")
        let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, storageBufferList![i].id)
        print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
    }
    
    for i in 0..<inputCount {
            print("Inputs")
            let name: String = inputList?[i] != nil ? String(cString: inputList![i].name) : ""
            print("ID: \(inputList?[i].id), BaseTypeID: \(inputList?[i].base_type_id), TypeID: \(inputList?[i].type_id), Name: \(name)");
            print("Set: \(spvc_compiler_get_decoration(compiler_msl, inputList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, inputList![i].id, SpvDecorationBinding))")
    }
    
    
    for i in 0..<imageCount {
            print("Images")
            let name: String = imageList?[i] != nil ? String(cString: imageList![i].name) : ""
            print("ID: \(imageList?[i].id), BaseTypeID: \(imageList?[i].base_type_id), TypeID: \(imageList?[i].type_id), Name: \(name)");
            print("Set: \(spvc_compiler_get_decoration(compiler_msl, imageList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, imageList![i].id, SpvDecorationBinding))")
            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, imageList![i].id)
            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
    }
    
    for i in 0..<sampledImageCount {
            print("Sampled Images")
            let name: String = sampledImageList?[i] != nil ? String(cString: sampledImageList![i].name) : ""
            print("ID: \(sampledImageList?[i].id), BaseTypeID: \(sampledImageList?[i].base_type_id), TypeID: \(sampledImageList?[i].type_id), Name: \(name)");
            print("Set: \(spvc_compiler_get_decoration(compiler_msl, sampledImageList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, sampledImageList![i].id, SpvDecorationBinding))")
            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, sampledImageList![i].id)
            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
    }
    
    for i in 0..<uniformCount {
            print("Uniform")
            let name: String = uniformList?[i] != nil ? String(cString: uniformList![i].name) : ""
            print("ID: \(uniformList?[i].id), BaseTypeID: \(uniformList?[i].base_type_id), TypeID: \(uniformList?[i].type_id), Name: \(name)");
            print("Set: \(spvc_compiler_get_decoration(compiler_msl, uniformList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, uniformList![i].id, SpvDecorationBinding))")
            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, uniformList![i].id)
            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
    }
    
    for i in 0..<separateImageCount {
            print("Separate Image")
            let name: String = separateImageList?[i] != nil ? String(cString: separateImageList![i].name) : ""
            print("ID: \(separateImageList?[i].id), BaseTypeID: \(separateImageList?[i].base_type_id), TypeID: \(separateImageList?[i].type_id), Name: \(name)");
            print("Set: \(spvc_compiler_get_decoration(compiler_msl, separateImageList![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, separateImageList![i].id, SpvDecorationBinding))")
            let resourceBinding = spvc_compiler_msl_get_automatic_resource_binding(compiler_msl, separateImageList![i].id)
            print("Resource Binding: \(Int32(bitPattern: resourceBinding))")
    }

    
    
    
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    let str = String(cString: result!)
    print("Shader:\n\(str)")
    
    return str
}



