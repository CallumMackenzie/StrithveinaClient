//
//  Camera.swift
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-11-14.
//

import Metal
import MetalKit
import simd

class STCamera2D {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    let renderPipelineDescriptor: MTLRenderPipelineDescriptor
    let pso: MTLRenderPipelineState
    
    init(device: MTLDevice,
         commandQueue: MTLCommandQueue,
         library: MTLLibrary,
         renderPipelineDescriptor: MTLRenderPipelineDescriptor,
         pso: MTLRenderPipelineState) {
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
        self.renderPipelineDescriptor = renderPipelineDescriptor
        self.pso = pso
    }
    
    func render(view: MTKView) {
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
        renderEncoder.setRenderPipelineState(self.pso)
        
        renderEncoder.setVertexBytes([self.globalUniforms],
                               length: MemoryLayout<GlobalUniforms>.stride,
                               attributeStride: MemoryLayout<GlobalUniforms>.stride, index: BufferIndex.globalUniformData.rawValue)

        for renderable in self.renderables {
            renderable.preRender(encoder: renderEncoder)
            renderable.render(encoder: renderEncoder)
        }
        
        // Finished encoding render commands
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}

class STCamera2DFactory {
    
    /// The name of this camera
    let name: String
    
    init?(view: MTKView, name: String) {
        self.name = name
    }
    
    /// Creates the camera with given factory parameters
    func createCamera(view: MTKView) -> STCamera2D? {
        guard let device = self.setupDevice(view) else { return nil }
        guard let commandQueue = self.setupCommandQueue(device) else { return nil }
        guard let library = self.setupLibrary(device) else { return nil }
        let pipelineDescriptor = self.setupRenderPipelineDescriptor(view)
        if !self.setupShaders(library: library, pipelineDescriptor: pipelineDescriptor) { return nil }
        guard let pso = self.setupPipelineStateObject(device: device, pipelineStateDescrptor: pipelineDescriptor) else { return nil }
        
        return STCamera2D(device: device,
                          commandQueue: commandQueue,
                          library: library,
                          renderPipelineDescriptor: pipelineDescriptor,
                          pso: pso)
    }
    
    func setupDevice(_ view: MTKView) -> MTLDevice? {
        // Retrieve device from view
        guard let dev = view.device else {
            Log.cameraError("Device was undefined")
            return nil
        }
        Log.camera("Created device")
        return dev
    }
    
    func setupCommandQueue(_ device: MTLDevice) -> MTLCommandQueue? {
        // Create the command queue
        guard let commandQueue = device.makeCommandQueue() else {
            Log.cameraError("Command queue could not be created")
            return nil
        }
        Log.camera("Created command queue")
        return commandQueue
    }
    
    func setupLibrary(_ device: MTLDevice) -> MTLLibrary? {
        // Get metal library
        guard let lib = device.makeDefaultLibrary() else {
            Log.cameraError("Library was undefined")
            return nil
        }
        Log.camera("Created library")
        return lib
    }
    
    func setupRenderPipelineDescriptor(_ view: MTKView) -> MTLRenderPipelineDescriptor {
        let pipelineStateDescrptor = MTLRenderPipelineDescriptor()
        pipelineStateDescrptor.label = self.name
        pipelineStateDescrptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        return pipelineStateDescrptor
    }
    
    /// Returns whether shader creation succeeded
    func setupShaders(library: MTLLibrary, pipelineDescriptor: MTLRenderPipelineDescriptor) -> Bool {
        // Create shaders
        guard let vertexShader = library.makeFunction(name: "vertexShader") else {
            Log.cameraError("Failed to create vertex shader")
            return false
        }
        guard let fragmentShader = library.makeFunction(name: "fragmentShader") else {
            Log.cameraError("Failed to create fragment shader")
            return false
        }
        Log.camera("Created shaders")
        return true
    }
    
    func setupPipelineStateObject(device: MTLDevice, pipelineStateDescrptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState? {
        // Create render pipeline state from descriptor
        do {
            let pso = try device.makeRenderPipelineState(descriptor: pipelineStateDescrptor)
            Log.camera("Created pipeline state object (PSO)")
            return pso
        } catch {
            Log.cameraError("Failed to create render pipeline state from descriptor")
            return nil
        }
    }
    
}
