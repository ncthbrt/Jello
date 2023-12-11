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


fileprivate let spirvMagicNumber: UInt32 = 0x07230203
fileprivate let generatorMagicNumber: UInt32 = 0x0
fileprivate let spirvVersion: UInt32 = 0x00010600

fileprivate func buildHeader(bounds: UInt32) -> [UInt32] {
    return [
        spirvMagicNumber,
        spirvVersion,
        generatorMagicNumber,
        bounds,
        UInt32(0) // Schema
    ]
}

public struct Instruction {
    public let opCode: SPIRV_Cross.SpvOp
    public var id: UInt32? = nil
    public var resultId: UInt32? = nil
    public var operands: [UInt32]
    
    public init(opCode: SPIRV_Cross.SpvOp, id: UInt32? = nil, resultId: UInt32? = nil, operands: [UInt32] = []) {
        self.opCode = opCode
        self.id = id
        self.resultId = resultId
        self.operands = operands
    }
    
     
    func length() -> UInt32 {
        var sum: UInt32 = 1
        sum += id != nil ? 1: 0
        sum += resultId != nil ? 1 : 0
        return sum + UInt32(operands.count)
    }
    
    
    public mutating func appendOperand(bool: Bool){
        operands.append(bool ? 0x1: 0x0)
    }
    
    public mutating func appendOperand(string: String){
        let data = Data(string.utf8)
        let div4 = data.count/4
        for i in 0..<div4 {
            var value: UInt32 = 0
            for j in (0..<4) {
                let byte = UInt32(data[i*4+j])
                value |= byte<<(8*j)
            }
            operands.append(value)
        }
        let remainder = data.count - (div4*4)
        var value: UInt32 = 0
        for j in (0..<remainder) {
            let byte = UInt32(data[div4*4+j])
            value |= byte<<(8*j)
        }
        operands.append(value)
    }
    
    public mutating func appendOperand(float: Float){
        operands.append(float.bitPattern)
    }
    
    public mutating func appendOperand(int: Int32){
        operands.append(UInt32(bitPattern: int))
    }
}

public func buildInstruction(instruction: Instruction) -> [UInt32] {
    let opCode: UInt32 =  (instruction.length() << 16) | instruction.opCode.rawValue
    var arr = [opCode]
    if let id = instruction.id {
        arr.append(id)
    }
    if let resultId = instruction.resultId {
        arr.append(resultId)
    }
    arr.append(contentsOf: instruction.operands)
    return arr
}

public func buildOutput(instructions: [Instruction], bounds: UInt32) -> [UInt32] {
    var output = buildHeader(bounds: bounds)
    output.append(contentsOf: instructions.flatMap({instruction in buildInstruction(instruction: instruction)}))
    return output
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
    
    var errorContext: SpirvCompilationErrorContext = .init()
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
    
    //    for i in 0..<count {
    //        print("ID: \(list?[i].id), BaseTypeID: \(list?[i].base_type_id), TypeID: \(list?[i].type_id), Name: \(list?[i].name)");
    //        print("Set: \(spvc_compiler_get_decoration(compiler_msl, list![i].id, SpvDecorationDescriptorSet)), Binding: \(spvc_compiler_get_decoration(compiler_msl, list![i].id, SpvDecorationBinding))")
    //    }
    
    // Modify options.
    spvc_compiler_create_compiler_options(compiler_msl, &options)
    if let errValue = errorContext.errorValue {
        throw SpirvCompilationError.compilationError(errValue)
    }
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_VERSION, 20000)
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



