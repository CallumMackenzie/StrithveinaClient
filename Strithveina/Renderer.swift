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
    let texCoord: vector_float2;
};

// Uniform data
struct STUniforms {
    let offset: vector_float2;
    var transform: matrix_float2x2;
    
    init() {
        self.offset = SIMD2(0, 0)
        self.transform = matrix_float2x2(SIMD2(1, 0),
                                         SIMD2(0, 1))
    }
}

struct GlobalUniforms {
    var transform: matrix_float2x2;
}

class Renderer: NSObject, MTKViewDelegate, STSceneOwner {
    
    var rotationRadians: Float = 0;
    var aspect: Float = 1;
    
    var globalUniforms: GlobalUniforms = GlobalUniforms(transform: matrix2x2_scale(x: 1, y: 1))
    
    var time: STTime
    
    var scene: STScene?
    
    @MainActor
    init?(metalKitView: MTKView) {
        
        self.time = STTime()
        
        super.init()
    }
    
    func setScene(scene: STScene?) {
        self.scene = scene
    }
    
    func stepGame() {
        self.scene?.update(time: self.time)
    }
    
    func updateUniforms() {
        self.globalUniforms.transform = matrix2x2_scale(x: 1, y: self.aspect)
    }
    
    func draw(in view: MTKView) {
        self.stepGame()
        self.updateUniforms()
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.aspect = Float(size.width / size.height)
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
