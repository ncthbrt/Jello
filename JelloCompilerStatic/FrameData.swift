//
//  FrameData.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2024/01/15.
//

import Foundation
import simd
import SpirvMacrosShared
import SpirvMacros
import SPIRV_Headers_Swift

@SpirvStruct
public struct FrameData {
    // Per-frame constants.
    public var projectionMatrix : matrix_float4x4 // 0, 0
    public var projectionMatrixInv : matrix_float4x4 // 1, 64
    public var viewMatrix: matrix_float4x4 // 2, 64
    public var viewMatrixInv: matrix_float4x4 // 3, 64
    public var depthUnproject: vector_float2 // 4, 64
    public var screenToViewSpace: vector_float3 // 5, 8
    
    // Per-mesh constants.
    public var modelViewMatrix : matrix_float4x4 // 6, 12
    public var normalMatrix: matrix_float3x3 // 7, 64
    public var modelMatrix : matrix_float4x4 // 8, 36
    
    // Per-light properties.
    public var ambientLightColor: vector_float3 // 9, 64
    public var directionalLightDirection : vector_float3 // 10, 12
    public var directionalLightColor: vector_float3 // 12, 12
    public var framebufferWidth: UInt32 // 12, 12
    public var framebufferHeight : UInt32 // 13, 4
}
