//
//  Renderer.swift
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-10-24.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

// Vertex data
struct STVertex {
    let position: vector_float2;
    let color: vector_float4;
    let texCoord: vector_float2;
};

// Uniform data
struct STUniform {
    let offset: vector_float2;
    var transform: matrix_float2x2;
}

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    let renderPipelineState: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    
    let texture: MTLTexture
    
    let vertices: [STVertex] = [
        // 2D positions,    RGBA colors
        STVertex(position: SIMD2(-0.5, -0.5 ), color: SIMD4(1, 0, 0, 1), texCoord: SIMD2(0, 1)),
        STVertex(position: SIMD2(0.5, -0.5 ), color: SIMD4(0, 1, 0, 1), texCoord: SIMD2(1, 1)),
        STVertex(position: SIMD2(-0.5, 0.5), color: SIMD4(0, 0, 1, 1), texCoord: SIMD2(0, 0)),
        
        STVertex(position: SIMD2(0.5, 0.5 ), color: SIMD4(1, 0, 0, 1), texCoord: SIMD2(1, 0)),
        STVertex(position: SIMD2(0.5, -0.5 ), color: SIMD4(0, 1, 0, 1), texCoord: SIMD2(1, 1)),
        STVertex(position: SIMD2(-0.5, 0.5), color: SIMD4(0, 0, 1, 1), texCoord: SIMD2(0, 0)),
    ];
    
    var uniforms: STUniform = STUniform(
        offset: SIMD2(0, 0),
        transform: matrix2x2_rotation(radians: 0)
    );
    
    var rotationRadians: Float = 0;
    var aspect: Float = 1;
  
    @MainActor
    init?(metalKitView: MTKView) {
        // Set pixel format
        
        // Retrieve device from view
        guard let dev = metalKitView.device else {
            Log.renderError("Device was undefined")
            return nil
        }
        self.device = dev
        Log.render("Created device")
        
        
        // Create the command queue
        guard let commandQueue = self.device.makeCommandQueue() else {
            Log.renderError("Command queue could not be created")
            return nil
        }
        self.commandQueue = commandQueue
        Log.render("Created command queue")
        
        

        // Get metal library
        guard let lib = self.device.makeDefaultLibrary() else {
            Log.renderError("Library was undefined")
            return nil
        }
        self.library = lib
        Log.render("Created library")
        
        
        
        // Create shaders
        guard let vertexShader = library.makeFunction(name: "vertexShader") else {
            Log.renderError("Failed to create vertex shader")
            return nil
        }
        guard let fragmentShader = library.makeFunction(name: "fragmentShader") else {
            Log.renderError("Failed to create fragment shader")
            return nil
        }
        Log.render("Created shaders")
        
        // Make pipeline descriptor
        let pipelineStateDescrptor = MTLRenderPipelineDescriptor()
        pipelineStateDescrptor.label = "Strithveina Renderer"
        pipelineStateDescrptor.vertexFunction = vertexShader
        pipelineStateDescrptor.fragmentFunction = fragmentShader
        pipelineStateDescrptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        // Create render pipeline state from descriptor
        do {
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescrptor)
        } catch {
            Log.renderError("Failed to create render pipeline state from descriptor")
            return nil
        }
        Log.render("Created pipeline state object (PSO)")
        
        
        // Populate vertex buffer
        guard let vertexBuffer = self.device.makeBuffer(bytes: self.vertices,
                                                        length: MemoryLayout<STVertex>.stride * self.vertices.count) else {
            Log.renderError("Failed to create vertex buffer object")
            return nil
        }
        self.vertexBuffer = vertexBuffer
    
        do {
             texture = try Renderer.loadTexture(device: device, textureName: "ColorMap")
         } catch {
             Log.renderError("Unable to load texture. Error info: \(error)")
             return nil
         }
        
        super.init()
    }
    
    func stepGame() {
        self.rotationRadians += 0.01;
    }
    
    func updateUniforms() {
        self.uniforms.transform = matrix2x2_rotation(radians: self.rotationRadians) * matrix2x2_scale(x: 1, y: self.aspect) * matrix2x2_scale(x: 0.5, y: 0.5)
    }
    
    func draw(in view: MTKView) {
        self.stepGame()
        self.updateUniforms()
        
        // Create command buffer
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
            Log.renderError("Failed to create command buffer")
            return
        }
        
        // Get render pass descriptor for current frame
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            Log.renderError("Render pass descriptor was null")
            return
        }

        // Create command encoder for current frame (render pass descriptor)
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            Log.renderError("Failed to create render command encoder")
            return
        }
        renderEncoder.label = "Primary render encoder"
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: BufferIndex.vertexData.rawValue)
        renderEncoder.setVertexBytes([self.uniforms], length: MemoryLayout<STUniform>.stride, attributeStride: MemoryLayout<STUniform>.stride, index: BufferIndex.uniformData.rawValue)
        renderEncoder.setFragmentTexture(self.texture, index: TextureIndex.test.rawValue)
        renderEncoder.drawPrimitives(type: MTLPrimitiveType.triangle,
                                     vertexStart: 0,
                                     vertexCount: self.vertices.count)
        
        // Finished encoding render commands
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.aspect = Float(size.width / size.height)
    }
    
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

func matrix2x2_rotation(radians: Float) -> matrix_float2x2 {
    return matrix_float2x2(SIMD2(cos(radians), sin(radians)),
                           SIMD2(-sin(radians), cos(radians)))
}

func matrix2x2_scale(x: Float, y: Float) -> matrix_float2x2 {
    return matrix_float2x2(SIMD2(x, 0),
                           SIMD2(0, y));
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
