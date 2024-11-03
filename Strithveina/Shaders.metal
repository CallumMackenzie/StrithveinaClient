//
//  Shaders.metal
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-10-24.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float2 position;
    float4 color;
    float2 texCoord;
} Vertex;

typedef struct
{
    float4 position [[position]];
    float4 color;
    float2 texCoord;
} ColorInOut;

typedef struct {
    float2 offset;
    matrix_float2x2 transform;
} Uniforms;

vertex ColorInOut vertexShader(device const Vertex *vertexes [[buffer(BufferIndexVertexData)]],
                               uint vid [[vertex_id]],
                               constant Uniforms &uniforms [[buffer(BufferIndexUniformData)]])
{
    ColorInOut out;
    
    float2 transformed = vertexes[vid].position * uniforms.transform;
    
    out.position = float4(transformed + uniforms.offset, 0.0, 1.0);
    out.color = vertexes[vid].color;
    out.texCoord = vertexes[vid].texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> colorMap [[ texture(TextureIndexTest) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    return float4(in.color) * float4(colorSample);
}
