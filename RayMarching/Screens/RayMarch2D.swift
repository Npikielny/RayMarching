//
//  RayMarch2D.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import ShaderKit
import SwiftUI

struct RayMarch2D: BasicScreen {
    
    var timer: Publisher = Timer.publish(every: 1 / 60, on: .main, in: .default).autoconnect()
    var operation: ShaderKit.PresentingOperation
    
    let view: MTKViewRepresentable
    let commandQueue: MTLCommandQueue?
    
    let angle: UnsafeMutablePointer<Float>
    
    @State var rate: Float = 0.1
    
    init(commandQueue: MTLCommandQueue?) {
        self.commandQueue = commandQueue
        view = MTKViewRepresentable(
            frame: CGRect(x: 0, y: 0, width: 512, height: 512),
            device: commandQueue?.device
        )
        
        let texture = Texture.newTexture(pixelFormat: .bgra8Unorm, width: 512, height: 512, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        
        let ptr = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        angle = ptr
        
        self.operation = RenderOperation(presents: true) {
            ComputePass(
                texture: texture,
                pipelines: [
                    try! ComputeShader(
                        name: "rayMarch2D",
                        textures: [texture],
                        buffers: [Buffer(constantPointer: ptr, count: 1)],
                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                    )
                ]
            )
            
            RenderShader.default(texture: texture)
        }
    }
    
    func mutateState(publisher: Publisher.Output) {
        angle.pointee += rate
    }
    
    var contents: some View {
        ZStack(alignment: .bottomLeading) {
            view
            HStack {
                Slider(value: $rate, in: 0.001...(1 / 30)) {
                    Text("Rate")
                }
                    .frame(maxWidth: 200)
                Text("\(rate)")
            }
        }
    }
}

struct RayMarch2D_Previews: PreviewProvider {
    static var previews: some View {
        RayMarch2D(commandQueue: MTLCreateSystemDefaultDevice()?.makeCommandQueue())
    }
}
