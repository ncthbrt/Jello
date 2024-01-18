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

final class JelloDefaultVertexShaderTest: XCTestCase {
    
    func testCompilingSpirvFileToMSLShouldProduceExpectedResult() throws {
        let result = try compileMSLShader(spirv: defaultVertexShader)
        let expectedResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct FrameData
{
    float4x4 projectionMatrix;
    float4x4 projectionMatrixInv;
    float4x4 viewMatrix;
    float4x4 viewMatrixInv;
    float2 depthUnproject;
    float3 screenToViewSpace;
    float4x4 modelViewMatrix;
    float3x3 normalMatrix;
    float4x4 modelMatrix;
    float3 ambientLightColor;
    float3 directionalLightDirection;
    float3 directionalLightColor;
    uint framebufferWidth;
    uint framebufferHeight;
};

struct vertexMain_out
{
    float4 worldPos [[user(locn0)]];
    float2 texCoord [[user(locn1)]];
    float3 tangent [[user(locn2)]];
    float3 bitangent [[user(locn3)]];
    float3 normal [[user(locn4)]];
    float4 gl_Position [[position]];
};

struct vertexMain_in
{
    float4 position [[attribute(0)]];
    float2 texCoord_1 [[attribute(1)]];
    float3 normal_1 [[attribute(2)]];
    float3 tangent_1 [[attribute(3)]];
    float3 bitangent_1 [[attribute(4)]];
};

vertex vertexMain_out vertexMain(vertexMain_in in [[stage_in]], constant FrameData& frameData [[buffer(2)]])
{
    vertexMain_out out = {};
    out.texCoord = in.texCoord_1;
    out.worldPos = frameData.modelMatrix * in.position;
    out.gl_Position = frameData.projectionMatrix * (frameData.modelViewMatrix * in.position);
    out.normal = fast::normalize(frameData.normalMatrix * in.normal_1);
    out.tangent = fast::normalize(frameData.normalMatrix * in.tangent_1);
    out.bitangent = -fast::normalize(frameData.normalMatrix * in.bitangent_1);
    return out;
}


"""
        XCTAssertEqual(result, expectedResult)
    }

}

