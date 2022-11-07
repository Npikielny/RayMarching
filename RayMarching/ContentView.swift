//
//  ContentView.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

import ShaderKit
import SwiftUI

struct ContentView: View {
    static let device = MTLCreateSystemDefaultDevice()
    static let commandQueue = device?.makeCommandQueue()
    
    let view = MTKViewRepresentable(
        frame: CGRect(x: 0, y: 0, width: 512, height: 512),
        device: device,
        pixelFormat: .bgra8Unorm
    )
    
    let timer = Timer.publish(every: 1 / 60, on: .main, in: .default).autoconnect()
    
    let operation: PresentingOperation
    
    let angle: UnsafeMutablePointer<Float>
    
    init() {
        let intermediate = Texture.newTexture(pixelFormat: .bgra8Unorm, width: 500, height: 500, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        
        let ptr = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        angle = ptr
        let computePass = ContentView.operation2D(texture: intermediate, angle: ptr)
        
        operation = RenderOperation(presents: true) {
            computePass
            ComputePass(
                texture: intermediate,
                pipelines: [
                    try! ComputeShader(
                        name: "rayMarch2D",
                        textures: [intermediate],
                        buffers: [Buffer(constantPointer: ptr, count: 1)],
                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                    )
                ]
            )
            
            try! RenderShader(
                pipeline: RenderFunction(
                    vertex: "imageVert",
                    fragment: "copyToDrawable",
                    destination: intermediate
                ),
                fragmentTextures: [intermediate],
                renderPassDescriptor: RenderPassDescriptor.drawable
            )
        }
    }
    
    var body: some View {
        view.onReceive(timer) { _ in draw(); angle.pointee += 0.1 }
    }
    
    func draw() {
        guard let commandQueue = Self.commandQueue,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            print("exiting")
            return
        }
        
        Task {
            try await commandQueue.execute(
                renderBuffer: operation,
                library: nil,
                renderDescriptor: descriptor,
                drawable: drawable
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
