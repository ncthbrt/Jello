//
//  JelloCompilerTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2023/12/08.
//

import XCTest
import SPIRV_Cross
import JelloCompiler

final class JelloGoodSpirvFileGeneratorTest: XCTestCase {
    private var spirvFile: [UInt32] = []
    
    override func setUpWithError() throws {
        var entryPoint = Instruction(opCode: SpvOpEntryPoint, operands: [SpvExecutionModelVertex.rawValue, 3])
        entryPoint.appendOperand(string: "main")
        
        let instructions = [
            Instruction(opCode: SpvOpCapability, operands: [SpvCapabilityShader.rawValue]),
            Instruction(opCode: SpvOpMemoryModel, operands: [SpvAddressingModelLogical.rawValue, SpvMemoryModelGLSL450.rawValue]),
            entryPoint,
            Instruction(opCode: SpvOpTypeVoid, resultId: 1),
            Instruction(opCode: SpvOpTypeFunction, resultId: 2, operands: [1]),
            Instruction(opCode: SpvOpFunction, id: 1, resultId: 3, operands: [0, 2]),
            Instruction(opCode: SpvOpLabel, resultId: 4),
            Instruction(opCode: SpvOpReturn),
            Instruction(opCode: SpvOpFunctionEnd),
         ]
        
        spirvFile = buildOutput(instructions: instructions, bounds: 5)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCompilingSpirvFileToMSLShouldProduceExpectedResult() throws {
        let result = try compileMSLShader(spirv: spirvFile)
        let expectedResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

vertex void main0()
{
}


"""
        XCTAssertEqual(result, expectedResult)
    }

}


final class JelloBadSpirvFileGeneratorTest: XCTestCase {
    private var spirvFile: [UInt32] = []
    
    override func setUpWithError() throws {
        var entryPoint = Instruction(opCode: SpvOpEntryPoint, operands: [SpvExecutionModelVertex.rawValue, 3])
        entryPoint.appendOperand(string: "main")
        
        let instructions = [
            Instruction(opCode: SpvOpCapability, operands: [SpvCapabilityShader.rawValue]),
            Instruction(opCode: SpvOpMemoryModel, operands: [SpvAddressingModelLogical.rawValue, SpvMemoryModelGLSL450.rawValue]),
            entryPoint,
            Instruction(opCode: SpvOpTypeVoid, resultId: 1),
            Instruction(opCode: SpvOpTypeFunction, resultId: 1, operands: [1]),
            Instruction(opCode: SpvOpFunction, id: 1, resultId: 3, operands: [0, 2]),
            Instruction(opCode: SpvOpLabel, resultId: 4),
            Instruction(opCode: SpvOpReturn),
            Instruction(opCode: SpvOpFunctionEnd),
         ]
        
        spirvFile = buildOutput(instructions: instructions, bounds: 5)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCompilingSpirvFileToMSLShouldThrow() throws {
        XCTAssertThrowsError(try compileMSLShader(spirv: self.spirvFile))
    }

}
