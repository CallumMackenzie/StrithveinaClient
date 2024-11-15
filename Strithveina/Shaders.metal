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
    float2 texCoord;
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

typedef struct {
    float2 offset;
    matrix_float2x2 transform;
} MeshUniforms;

typedef struct {
    matrix_float2x2 transform;
} GlobalUniforms;

vertex ColorInOut vertexShader(device const Vertex *vertices [[buffer(BufferIndexVertexData)]],
                               uint vid [[vertex_id]],
                               constant MeshUniforms &mesh_uniforms [[buffer(BufferIndexMeshUniformData)]],
                               constant GlobalUniforms &global_uniforms [[buffer(BufferIndexGlobalUniformData)]])
{
    ColorInOut out;
    
    float2 scaled_for_aspect = global_uniforms.transform * vertices[vid].position;
    float2 transformed = mesh_uniforms.transform * scaled_for_aspect;
    
    out.position = float4(transformed + mesh_uniforms.offset, 0.0, 1.0);
    out.texCoord = vertices[vid].texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> colorMap [[ texture(TextureIndexColorMap) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    return float4(colorSample);
}
