//
//  RayMarching3D.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import ShaderKit
import Metal

extension ContentView {
    static func operation3D(texture: Texture, count: Int) -> ComputePass {
        let scene = Scene3D.randomScene(objectCount: 50)
        let camera = Camera(position: SIMD3<Float>(0, 0, 0), rotation: SIMD3<Float>(0, 0, 0))
        
        return ComputePass(
            texture: texture,
            pipelines: [
                try! ComputeShader(
                    name: "rayMarch3D",
                    textures: [texture],
                    buffers: [
                        Buffer(constant: [camera.makeModelMatrix(), camera.makeProjectionMatrix()]),
                        Buffer(mutable: scene.objects),
                        Buffer(constant: scene.objects.count),
                        Buffer(mutable: scene.materials),
                    ],
                    threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                )
            ]
        )
    }
}
