//
//  JelloCompilerTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2023/12/08.
//

import XCTest
import JelloCompilerStatic
import SpirvMacros
import SpirvMacrosShared
import SPIRV_Headers_Swift

final class JelloGoodSpirvFileGeneratorTest: XCTestCase {
    private var spirvFile: [UInt32] = []
    
    override func setUpWithError() throws {
        spirvFile = #document ({
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
            #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
            let entryPoint = #id
            #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelVertex.rawValue, entryPoint],  #stringLiteral("main"))
            let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
            let entryPointFuncType = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
            #functionHead(opCode: SpirvOpFunction, [typeVoid, entryPoint, 0, entryPointFuncType])
            #functionHead(opCode: SpirvOpLabel, [#id])
            #functionBody(opCode: SpirvOpReturn)
            #functionBody(opCode: SpirvOpFunctionEnd)
            SpirvFunction.instance.writeFunction()
        })
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
        spirvFile = #document ({
            #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
            #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
            let entryPoint = #id
            #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelVertex.rawValue, entryPoint],  #stringLiteral("main"))
            let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
            let entryPointFuncType = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
            #functionHead(opCode: SpirvOpFunction, [typeVoid, entryPoint, 0, entryPointFuncType])
            #functionHead(opCode: SpirvOpLabel, [#id])
            #functionBody(opCode: SpirvOpReturn)
            SpirvFunction.instance.writeFunction()
        })
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCompilingSpirvFileToMSLShouldProduceExpectedResult() throws {
        XCTAssertThrowsError(try compileMSLShader(spirv: self.spirvFile))
    }

}
