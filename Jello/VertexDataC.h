//
//  VertexC.h
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/13.
//

#ifndef VertexC_h
#define VertexC_h

#include <simd/simd.h>

// Data constant across all threads, vertices, and fragments.
typedef struct
{
    vector_float3 position;
    vector_float2 texCoord;
    vector_float3 normal;
    vector_float3 tangent;
    vector_float3 bitangent;
} VertexDataC;


#endif /* VertexC_h */
