//
//  VertexData.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2024/02/13.
//
import Foundation
import simd
import SpirvMacrosShared
import SpirvMacros
import SPIRV_Headers_Swift

@SpirvStruct
public struct VertexData {
    public var position : vector_float3
    public var texCoord : vector_float2
    public var normal : vector_float3
    public var tangent : vector_float3
    public var bitangent : vector_float3
}
