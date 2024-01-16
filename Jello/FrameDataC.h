//
//  FrameDataC.h
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/16.
//

#ifndef FrameDataC_h
#define FrameDataC_h

#include <simd/simd.h>

// Data constant across all threads, vertices, and fragments.
typedef struct
{
    // Per-frame constants.
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 projectionMatrixInv;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 viewMatrixInv;
    vector_float2 depthUnproject;
    vector_float3 screenToViewSpace;
    
    // Per-mesh constants.
    matrix_float4x4 modelViewMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 modelMatrix;
    
    // Per-light properties.
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    uint framebufferWidth;
    uint framebufferHeight;
} FrameDataC;

#endif /* FrameDataC_h */
