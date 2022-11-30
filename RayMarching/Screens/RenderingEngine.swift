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
    
    let time: UnsafeMutablePointer<Float>
    
    let precisionPointer: UnsafeMutablePointer<Float>
    @Binding var precision: Float
    
    @State var needsUpdating = true
    
    init(commandQueue: MTLCommandQueue?) {
        self.commandQueue = commandQueue
        view = MTKViewRepresentable(
            frame: CGRect(x: 0, y: 0, width: 2048, height: 2048),
            device: commandQueue?.device
        )
        
        let _precision = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        _precision.pointee = 0.1
        self.precisionPointer = _precision
        self._precision = Binding(get: {
            1 / _precision.pointee
        }, set: { newValue in
            _precision.pointee = 1 / newValue
        })
        
        let _time = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        _time.pointee = 0
        time = _time
        
        let texture = Texture.newTexture(pixelFormat: .bgra8Unorm, width: 512, height: 512, storageMode: .private, usage:  [.shaderRead, .shaderWrite])
        
        let matricesPtr = UnsafeMutablePointer<float4x4>.allocate(capacity: 2)
        matrices = matricesPtr
        let camera = Camera(position: SIMD3<Float>(0, 1, -50))
        
        matricesPtr.pointee = camera.makeModelMatrix()
        matricesPtr.successor().pointee = camera.makeProjectionMatrix()
        
        self._camera = State(initialValue: camera)
        
        operation = RenderOperation(presents: true) {
            ComputePass(
                texture: texture,
                pipelines: [
                    try! ComputeShader(
                        name: "realisticScene",
                        textures: [texture],
                        buffers: [
                            Buffer(constantPointer: matricesPtr, count: 2),
                            Buffer(constantPointer: _precision, count: 1),
                            Buffer(constantPointer: _time, count: 1)
                        ],
                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                    )
                ]
            )
//            ComputePass(
//                texture: texture,
//                pipelines: [
//                    try! ComputeShader(
//                        name: "rayMarch3D",
//                        textures: [texture],
//                        buffers: [
//                            Buffer(constantPointer: matricesPtr, count: 2),
//                            Buffer(mutable: scene.objects),
//                            Buffer(constant: scene.objects.count),
//                            Buffer(mutable: scene.materials),
//                            Buffer(constant: Float(0.001)),
//                            Buffer(constantPointer: iterationCount, count: 1)
//                        ],
//                        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
//                    )
//                ]
//            )
//
            RenderShader.default(texture: texture)
        }
    }
    
    func mutateState() {
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
        contents.onReceive(timer) { t in
//            if needsUpdating {
                mutateState()
                needsUpdating = false
                draw()
            time.pointee += Float(0.01)
//            }
        }
    }
    
    func draw() {
        guard let commandQueue,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            NSLog("[RenderError] unable to fetch resources for draw call")
            return
        }
        
        Task {
            try await commandQueue.execute(renderBuffer: operation, renderDescriptor: descriptor, drawable: drawable)
        }
    }
    
    func handleDrag(drag: CGSize, size: CGSize) {
        needsUpdating = true
        let drag = -Float3(
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
                slider(value: $precision, in: 1...300, name: "Iterations")
//                slider(value: $camera.position.x, name: "x")
//                slider(value: $camera.position.y, name: "y")
//                slider(value: $camera.position.z, name: "z")
            }.frame(maxWidth: 200)
        }.padding(.top, 30)
    }
    
    private func slider<T: BinaryFloatingPoint>(value: Binding<T>, in range: ClosedRange<T>, display: Text? = nil, name: String) -> some View where T.Stride: BinaryFloatingPoint {
        HStack {
            Slider(value: value, in: range) { Text("\(name): ") }
                .frame(maxWidth: 200)
            if let display {
                display
            }
        }
    }
}

struct RenderingEngine_Previews: PreviewProvider {
    static var previews: some View {
        RenderingEngine(commandQueue: MTLCreateSystemDefaultDevice()?.makeCommandQueue())
    }
}
