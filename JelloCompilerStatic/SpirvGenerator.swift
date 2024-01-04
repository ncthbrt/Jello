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


public func compileMSLShader(spirv: [UInt32]) throws -> String  {
    var context : spvc_context? = nil
    var ir: spvc_parsed_ir? = nil
    var compiler_msl : spvc_compiler? = nil
    var result: UnsafePointer<CChar>? = nil
    var options: spvc_compiler_options? = nil
    
    
    var spirvData = spirv
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
//    var count = 0
//    var resources: spvc_resources? = nil
//    var list: UnsafePointer<spvc_reflected_resource>? = nil

//    spvc_compiler_create_shader_resources(compiler_msl, &resources)
//    spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &list, &count)
    
//        for i in 0..<count {
//            print("ID: \(list?[i].id), BaseTypeID: \(list?[i].base_type_id), TypeID: \(list?[i].type_id), Name: \(list?[i].name)");
//            print("Set: \(spvc_compiler_get_decoration(compiler_msl, list![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, list![i].id, SpvDecorationBinding))")
//        }
    
    // Modify options.
    spvc_compiler_create_compiler_options(compiler_msl, &options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_VERSION, 20100)
    
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_install_compiler_options(compiler_msl, options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_compile(compiler_msl, &result)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    let str = String(cString: result!)
    
    return str
}



