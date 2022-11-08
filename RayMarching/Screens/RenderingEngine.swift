//
//  RenderingEngine.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import SceneKit
import ShaderKit
import SwiftUI

struct RenderingEngine: Screen {
    @State var moving: Bool = false
    
    let commandQueue: MTLCommandQueue?
    
    let view: MTKViewRepresentable
    
    let timer = Timer.publish(every: 1 / 60, on: .main, in: .default).autoconnect()
    
    let operation: ShaderKit.PresentingOperation
    
    @State var camera: Camera
    let matrices: UnsafeMutablePointer<float4x4>
    
    @State var cached = Float3.zero
    
    let iterations: UnsafeMutablePointer<Int32>
    
    init(commandQueue: MTLCommandQueue?) {
        self.commandQueue = commandQueue
        view = MTKViewRepresentable(
            frame: CGRect(x: 0, y: 0, width: 1024, height: 1024),
            device: commandQueue?.device
        )
        
        let iterationCount = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        iterationCount.pointee = 100
        self.iterations = iterationCount
        
        let texture = Texture.newTexture(pixelFormat: .bgra8Unorm, width: 512, height: 512, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        
        let matricesPtr = UnsafeMutablePointer<float4x4>.allocate(capacity: 2)
        matrices = matricesPtr
        let camera = Camera()
        
        matricesPtr.pointee = camera.makeModelMatrix()
        matricesPtr.successor().pointee = camera.makeProjectionMatrix()
        
        self._camera = State(initialValue: camera)
        let scene = Scene3D.testingScene()
        
        operation = RenderOperation(presents: true) {
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
                            Buffer(constantPointer: iterationCount, count: 1)
                        ],
                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                    )
                ]
            )
            
            RenderShader.default(texture: texture)
        }
    }
    
    func mutateState(publisher: Timer) {
//        NSLog("Update")
        matrices.pointee = camera.makeModelMatrix(with: moving ? cached : .zero)
        matrices.successor().pointee = camera.makeProjectionMatrix(with: moving ? .zero : cached)
    }
    
    var contents: some View {
        HStack {
            settings.padding()
            GeometryReader { geometry in
                view
                    .gesture(DragGesture()
                        .onChanged { gesture in
                            handleDrag(drag: gesture.translation, size: geometry.size)
                        }
                        .onEnded { gesture in
                            handleDrag(drag: gesture.translation, size: geometry.size)
                            if moving {
                                camera.position += cached
                            } else {
                                camera.rotation += cached
                            }
                            cached = .zero
                        }
                    )
            }
        }
    }
    
    var body: some View {
        contents.onAppear {
            let _ = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { timer in
                mutateState(publisher: timer)
                draw()
            }
        }
    }
    
    func draw() {
        guard let commandQueue,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            print("[RenderError] unable to fetch resources for draw call")
            return
        }
        
        Task {
            try await commandQueue.execute(renderBuffer: operation, renderDescriptor: descriptor, drawable: drawable)
        }
    }
    
    func handleDrag(drag: CGSize, size: CGSize) {
        let drag = Float3(
            Float(drag.height / size.height),
            Float(drag.width / size.width),
            0
        )
        
        if moving {
            move(drag: drag * Float.pi)
        } else {
            rotate(drag: drag)
        }
    }
    
    func move(drag: Float3) {
        let drag = Float3(drag.y, -drag.x, 0)
        let rotation = float3x3(Float3(cos(drag.y), 0, sin(drag.y)),
                                Float3(0, 1, 0),
                                Float3(-sin(drag.y), 0, cos(drag.y))
        ) * float3x3(Float3(1, 0, 0),
                     Float3(0, cos(drag.x), -sin(drag.x)),
                     Float3(0, sin(drag.x), cos(drag.x))
        )
        
        cached = rotation * drag
    }
    
    func rotate(drag: Float3) {
        cached = drag
    }
    
    var settings: some View {
        VStack {
            Toggle(isOn: $moving) {
                Text(moving ? "Moving" : "Rotating")
            }
            Spacer()
            VStack {
                slider(value: Binding<Float>.init(get: {
                    Float(iterations.pointee)
                }, set: { newValue in
                    iterations.pointee = Int32(newValue)
                }), in: 1...300, name: "Max Iterations")
//                slider(value: $camera.position.x, name: "x")
//                slider(value: $camera.position.y, name: "y")
//                slider(value: $camera.position.z, name: "z")
            }.frame(maxWidth: 200)
        }.padding(.top, 30)
    }
    
    private func slider<T: BinaryFloatingPoint>(value: Binding<T>, in range: ClosedRange<T>, name: String) -> some View where T.Stride: BinaryFloatingPoint {
        HStack {
            Slider(value: value, in: range) { Text("\(name): ") }
                .frame(maxWidth: 200)
//            Text("\(value)")
        }
    }
}

struct RenderingEngine_Previews: PreviewProvider {
    static var previews: some View {
        RenderingEngine(commandQueue: MTLCreateSystemDefaultDevice()?.makeCommandQueue())
    }
}
