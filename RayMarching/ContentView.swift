//
//  ContentView.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

import SceneKit
import ShaderKit
import SwiftUI

struct ContentView: View {
    static let device = MTLCreateSystemDefaultDevice()
    static let commandQueue = device?.makeCommandQueue()
    
    @State var screen: Screens? = nil
    
    enum Screens: String, CaseIterable {
        case rayMarch2D = "2D Illustration of Ray Marching"
        case rayMarch3D = "3D Ray Marching"
        case renderingEngine = "Island Scene"
        
        var image: Image {
            switch self {
                case .rayMarch2D: return Image("Ray Marching 2D")
                case .rayMarch3D: return Image("Ray Marching 3D")
                case .renderingEngine: return Image("Island")
            }
        }
        
        var description: String {
            switch self {
                case .rayMarch2D:
                    return """
2D Visualization of an SDF ray marching algorithm
"""
                case .rayMarch3D:
                    return """
A fully fledged 3D ray marching engine with Lambertian shading that can render planes, spheres, and boxes.
"""
                case .renderingEngine:
                    return """
An artistic use of ray marching to render a procedural island with water and sky.
"""
            }
        }
    }
    
    
    var body: some View {
        if let screen {
            switch screen {
                case .rayMarch2D:
                    embed(RayMarch2D(commandQueue: Self.commandQueue))
                case .rayMarch3D:
                    embed(RayMarch3D(commandQueue: Self.commandQueue))
                case .renderingEngine:
                    embed(RenderingEngine(commandQueue: Self.commandQueue))
            }
        } else {
            VStack {
                Text("Renderers")
                List(Screens.allCases, id: \.rawValue) { screen in
                    VStack {
                        Text(screen.description)
                        screen.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                        Button(screen.rawValue) {
                            self.screen = screen
                        }
                        Divider()
                    }
                }
            }
            .padding()
        }
    }
    
    func embed(_ view: some View) -> some View {
        ZStack(alignment: .topLeading) {
            view
            Button("Back") { screen = nil }
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension RenderShader {
    static func `default`(texture: Texture) -> RenderShader {
        return try! RenderShader(
            pipeline: RenderFunction(
                vertex: "imageVert",
                fragment: "copyToDrawable",
                destination: texture
            ),
            fragmentTextures: [texture],
            renderPassDescriptor: RenderPassDescriptor.drawable
        )
    }
}
