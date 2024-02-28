//
//  MathUtils.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/26.
//

import Foundation
import simd

func matrix_make_columns(_ col0:vector_float3, _ col1:vector_float3 , _ col2: vector_float3) -> matrix_float3x3 {
    return matrix_float3x3(col0, col1, col2);
}

func matrix3x3_upper_left(_ m: matrix_float4x4) -> matrix_float3x3 {
    let x = vector_float3(m.columns.0.x,m.columns.0.y, m.columns.0.z);
    let y = vector_float3(m.columns.1.x,m.columns.1.y, m.columns.1.z);
    let z = vector_float3(m.columns.2.x,m.columns.2.y, m.columns.2.z);
    return matrix_make_columns(x, y, z);
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}



func matrix_perspective_left_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (farZ - nearZ)
    return matrix_float4x4(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, 1),
                                         vector_float4( 0,  0, -nearZ*zs, 0)))
}


func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
