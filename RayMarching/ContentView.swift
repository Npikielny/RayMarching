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
    
    static let texture = Texture("/Users/noahpikielny/Desktop/blobs.jpg")
    
    init() {
        let intermediate = Self.texture.emptyCopy(usage: [.shaderRead, .shaderWrite])
        
        operation = RenderOperation(presents: true) {
            ComputePass(
                texture: intermediate,
                pipelines: [
                    try! ComputeShader(
                        name: "rayMarch2D",
                        textures: [intermediate],
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
        view.onReceive(timer) { _ in draw() }
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
