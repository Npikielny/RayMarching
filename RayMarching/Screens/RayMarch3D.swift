//
//  RayMarch3D.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import SceneKit
import ShaderKit
import SwiftUI

struct RayMarch3D: BasicScreen {
    let commandQueue: MTLCommandQueue?
    let view: ShaderKit.MTKViewRepresentable
    
    let timer: Publisher = Timer.publish(every: 1 / 60, on: .main, in: .default).autoconnect()
    
    var operation: ShaderKit.PresentingOperation
    
    @State var camera: Camera
    let matrices: UnsafeMutablePointer<float4x4>
    
    init(commandQueue: MTLCommandQueue?) {
        self.commandQueue = commandQueue
        view = MTKViewRepresentable(
            frame: CGRect(x: 0, y: 0, width: 512, height: 512),
            device: commandQueue?.device
        )
        
        let texture = Texture.newTexture(pixelFormat: .bgra8Unorm, width: 512, height: 512, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        
        let camera = Camera(position: Float3(0, 0, 0), rotation: Float3(0, 0, 0))
        self._camera = State(initialValue: camera)
        let matricesPtr = UnsafeMutablePointer<float4x4>.allocate(capacity: 2)
        matrices = matricesPtr
        matricesPtr.pointee = camera.makeModelMatrix()
        matricesPtr.successor().pointee = camera.makeProjectionMatrix()
        
        let scene = Scene3D.randomScene(objectCount: 50)
        
        self.operation = RenderOperation(presents: true) {
            ComputePass(
                texture: texture,
                pipelines: [
                    try! ComputeShader(
                        name: "rayMarch3D",
                        textures: [texture],
                        buffers: [
                            Buffer(constantPointer: matricesPtr, count: 2),
                            Buffer(mutable: scene.objects),
                            Buffer(constant: scene.objects.count),
                            Buffer(mutable: scene.materials),
                        ],
                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                    )
                ]
            )
            
            RenderShader.default(texture: texture)
        }
    }
    
    var contents: some View {
        view
    }
}
