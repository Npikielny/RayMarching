//
//  Operation2D.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import ShaderKit
import Metal

extension ContentView {
    static func operation2D(texture: Texture) -> ComputePass {
        ComputePass(
            texture: texture,
            pipelines: [
                try! ComputeShader(
                    name: "rayMarch2D",
                    textures: [texture],
                    threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                )
            ]
        )
    }
}
