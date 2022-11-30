//
//  Camera.swift
//  RenderingEngine
//
//  Created by Noah Pikielny on 10/31/22.
//

import SceneKit
import ShaderKit

struct Camera {
    var fov: Float = Float.pi / 3
    var aspectRatio: Float = 1
    var position = SIMD3<Float>(0, 1, -5)
    var rotation = SIMD3<Float>.zero
    
    init(fov: Float = Float.pi / 3, aspectRatio: Float = 1, position: SIMD3<Float> = SIMD3<Float>(0, 1, -5), rotation: SIMD3<Float> = SIMD3<Float>.zero) {
        self.fov = fov
        self.aspectRatio = aspectRatio
        self.position = position
        self.rotation = rotation
    }
    
    func wrap(_ s: SIMD3<Float>) -> SIMD4<Float> {
        SIMD4<Float>(s, 1)
    }
    
    func makeProjectionMatrix(with cachedRotation: SIMD3<Float> = SIMD3<Float>.zero) -> float4x4 {
        let rotationMatrixX = float4x4(simd_quatf(angle: rotation.x + cachedRotation.x, axis: SIMD3<Float>(1, 0, 0)))
        let rotationMatrixY = float4x4(simd_quatf(angle: rotation.y + cachedRotation.y, axis: SIMD3<Float>(0, 1, 0)))
        let rotationMatrixZ = float4x4(simd_quatf(angle: rotation.z + cachedRotation.z, axis: SIMD3<Float>(0, 0, 1)))
        
        let rotation = rotationMatrixZ * rotationMatrixY * rotationMatrixX
        
        let forward = SIMD4<Float>(0, 0, 1, 1)
        let up = SIMD4<Float>(0, 1, 0, 0) * sin(fov)
        let right = SIMD4<Float>(1, 0, 0, 0) * sin(fov)
        
        let matrix = float4x4(right, up, SIMD4<Float>(0, 0, 0, 0), forward)
        return rotation * matrix
    }

    func makeModelMatrix(with cached: SIMD3<Float> = SIMD3<Float>.zero) -> float4x4 {
        return float4x4(rows: [SIMD4(1, 0, 0, position.x + cached.x),
                               SIMD4(0, 1, 0, position.y + cached.y),
                               SIMD4(0, 0, -1, position.z + cached.z),
                               SIMD4(0, 0, 0, 1)])
    }

}

extension float4x4: GPUEncodable {
    
}
