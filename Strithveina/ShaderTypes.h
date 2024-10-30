//
//  ShaderTypes.h
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-10-24.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>


typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexVertexData = 0,
};

//typedef NS_ENUM(EnumBackingType, VertexAttribute)
//{
//    VertexAttributePosition  = 0,
//    VertexAttributeColor  = 1,
//};

//typedef NS_ENUM(EnumBackingType, TextureIndex)
//{
//    TextureIndexColor    = 0,
//};

//typedef struct
//{
//    matrix_float2x2 modelViewMatrix;
//} Uniforms;

#endif /* ShaderTypes_h */

