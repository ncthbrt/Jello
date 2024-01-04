//
//  JelloDefaultFragmentShaderTest.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import Foundation

//
//  JelloCompilerTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2023/12/08.
//

import XCTest
@testable import JelloCompilerStatic

final class JelloDefaultFragmentShaderTest: XCTestCase {
    
    func testCompilingSpirvFileToMSLShouldProduceExpectedResult() throws {
        print(defaultFragmentShader)
        let result = try compileMSLShader(spirv: defaultFragmentShader)
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

