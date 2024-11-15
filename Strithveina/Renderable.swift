//
//  Renderable.swift
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-11-03.
//

import Metal
import MetalKit

/// Any object or set of objects which can be rendered
protocol STRenderable {
    /// Prepare for rendering
    func preRender(encoder: MTLRenderCommandEncoder)
    
    /// Render with the given command encoder
    func render(encoder: MTLRenderCommandEncoder)
}

/// A 2d renderable mesh
class STMesh: STRenderable {
    /// Raw vertices
    var vertices: [STVertex]
    
    /// Buffer containing vertex data
    var vertexBuffer: MTLBuffer
    
    /// Uniform data for this mesh
    var uniforms: STUniforms
    
    /// Mesh vertex layout type
    var primitiveType: MTLPrimitiveType
    
    
    init?(device: MTLDevice,
          primitiveType: MTLPrimitiveType,
          vertices: [STVertex]) {
        self.vertices = vertices
        
        // Populate vertex buffer
        guard let vertexBuffer = device.makeBuffer(bytes: self.vertices,
                                                   length: MemoryLayout<STVertex>.stride * self.vertices.count) else {
            Log.meshError("Failed to create vertex buffer object")
            return nil
        }
        self.vertexBuffer = vertexBuffer
        
        // Create uniform data
        self.uniforms = STUniforms()
        
        // Set type
        self.primitiveType = primitiveType
    }
    
    /// Sets buffer for both uniforms and vertices
    func preRender(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(self.vertexBuffer,
                                offset: 0,
                                index: BufferIndex.vertexData.rawValue)
        encoder.setVertexBytes([self.uniforms],
                               length: MemoryLayout<STUniforms>.stride,
                               attributeStride: MemoryLayout<STUniforms>.stride, index: BufferIndex.meshUniformData.rawValue)
    }
    
    /// Renders as triangle primitives
    func render(encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: self.primitiveType,
                               vertexStart: 0,
                               vertexCount: self.vertices.count)
    }
    
    /// Creates a quad mesh
    public static func quad(device: MTLDevice, scale: Float = 0.5) -> STMesh? {
        let vertices: [STVertex] = [
            // 2D positions,    RGBA colors
            STVertex(position: SIMD2(-scale, -scale), texCoord: SIMD2(0, 1)),
            STVertex(position: SIMD2(scale, -scale), texCoord: SIMD2(1, 1)),
            STVertex(position: SIMD2(-scale, scale), texCoord: SIMD2(0, 0)),
            
            STVertex(position: SIMD2(scale,scale), texCoord: SIMD2(1, 0)),
            STVertex(position: SIMD2(scale, -scale),texCoord: SIMD2(1, 1)),
            STVertex(position: SIMD2(-scale, scale), texCoord: SIMD2(0, 0)),
        ];
        
        return STMesh(device:device, primitiveType: .triangle, vertices: vertices)
    }
    
}

/// A 2d renderable mesh with a texture
class STTexturedMesh: STMesh {
    var texture: MTLTexture
    var textureIndex: Int
    
    init?(device: MTLDevice,
          textureName: String,
          textureIndex: Int,
          primitiveType: MTLPrimitiveType,
          vertices: [STVertex]) {
        do {
            self.texture = try TextureUtils.loadTexture(device: device, textureName: textureName)
        } catch {
            Log.meshError("Unable to load texture. Error info: \(error)")
            return nil
        }
        
        self.textureIndex = textureIndex
        
        super.init(device: device, primitiveType: primitiveType, vertices: vertices)
    }
    
    override func preRender(encoder: any MTLRenderCommandEncoder) {
        super.preRender(encoder: encoder)
        encoder.setFragmentTexture(self.texture, index: self.textureIndex)
    }
    
    public static func quad(device: MTLDevice, textureName: String, textureIndex: Int, scale: Float = 0.5) -> STTexturedMesh? {
        let vertices: [STVertex] = [
            // 2D positions,    RGBA colors
            STVertex(position: SIMD2(-scale, -scale), texCoord: SIMD2(0, 1)),
            STVertex(position: SIMD2(scale, -scale), texCoord: SIMD2(1, 1)),
            STVertex(position: SIMD2(-scale, scale), texCoord: SIMD2(0, 0)),
            
            STVertex(position: SIMD2(scale,scale), texCoord: SIMD2(1, 0)),
            STVertex(position: SIMD2(scale, -scale),texCoord: SIMD2(1, 1)),
            STVertex(position: SIMD2(-scale, scale), texCoord: SIMD2(0, 0)),
        ];
        
        return STTexturedMesh(device: device, textureName: textureName, textureIndex: textureIndex, primitiveType: MTLPrimitiveType.triangle, vertices: vertices)
    }
}

class TextureUtils {
    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
        
    }
}


