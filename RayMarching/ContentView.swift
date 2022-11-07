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
        case renderingEngine = "Rendering Environment"
    }
    
    
    var body: some View {
        switch screen {
            case .some(.rayMarch2D):
                embed(RayMarch2D(commandQueue: Self.commandQueue))
            case .some(.rayMarch3D):
                embed(RayMarch3D(commandQueue: Self.commandQueue))
            default:
                VStack {
                    Text("Renderers")
                    List(Screens.allCases, id: \.rawValue) { screen in
                        Button(screen.rawValue) {
                            self.screen = screen
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
