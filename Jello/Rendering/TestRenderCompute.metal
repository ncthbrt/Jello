#pragma clang diagnostic ignored "-Wunused-variable"

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_atomic>

using namespace metal;

struct VertexData
{
    float3 position;
    float2 texCoord;
    float3 normal;
    float3 tangent;
    float3 bitangent;
};

struct _13
{
    int index;
};

struct spvDescriptorSetBuffer0
{
    const device VertexData* vertices [[id(0)]];
    const device _13* indices [[id(1)]];
};

struct spvDescriptorSetBuffer3
{
    texture2d<int, access::read_write> m_17 [[id(0)]];
};

kernel void computeMain(constant spvDescriptorSetBuffer0& spvDescriptorSet0 [[buffer(0)]], constant spvDescriptorSetBuffer3& spvDescriptorSet3 [[buffer(3)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int _26 = int3(gl_GlobalInvocationID).x * 3;
    int _27 = _26 + 1;
    float2 _46 = fast::max(fast::min(spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_26].index].texCoord, spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27].index].texCoord), spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27 + 1].index].texCoord);
    int2 _60 = int2(_46 * float2(8.0));
    int2 _61 = int2(ceil(fast::max(fast::max(spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_26].index].texCoord, spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27].index].texCoord), spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27 + 1].index].texCoord) * float2(8.0)));
    int _62 = _60.x;
    int _63 = _60.y;
    int _64 = _61.x;
    int _65 = _61.y;
    float2 _66 = spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27].index].texCoord - spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_26].index].texCoord;
    float2 _67 = spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_27 + 1].index].texCoord - spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_26].index].texCoord;
    float _70 = _66.x;
    float _71 = _66.y;
    float _72 = _67.x;
    float _73 = _67.y;
    float _75 = _70 * _73;
    float _68 = _75 - _75;
    if (0.0 != _68)
    {
        return;
    }
    float _69 = 1.0 / _68;
    float _80 = 1.0 / 8.0;
    float _81 = 1.0 / 8.0;
    float _82 = _46.x;
    float _83 = _46.y;
    int _96 = _62;
    float _97 = _82;
    for (; _96 < _64; _96++, _97 += _80)
    {
        int _99 = _63;
        float _100 = _83;
        for (; _99 < _65; _99++, _100 += _81)
        {
            float2 _103 = float2(_97, _100) - spvDescriptorSet0.vertices[spvDescriptorSet0.indices[_26].index].texCoord;
            float _104 = _103.x;
            float _105 = _103.y;
            float _107 = _69 * ((_104 * _73) - (_105 * _72));
            float _112 = _105 * _70;
            float _108 = _69 * (_112 - _112);
            if (!(((((1.0 - _107) - _108) < 0.0) || (_107 < 0.0)) || (_108 < 0.0)))
            {
                int _129 = spvDescriptorSet3.m_17.atomic_fetch_max(uint2(int2(_96, _99)), int3(gl_GlobalInvocationID).x).x;
            }
        }
    }
}

