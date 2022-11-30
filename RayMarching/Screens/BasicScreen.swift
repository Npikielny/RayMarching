//
//  BasicScreen.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/7/22.
//

import Combine
import ShaderKit
import SwiftUI

protocol Screen: View {
    init(commandQueue: MTLCommandQueue?)
}

protocol BasicScreen: Screen {
    typealias Publisher = Publishers.Autoconnect<Timer.TimerPublisher>
    
    var commandQueue: MTLCommandQueue? { get }
    var view: MTKViewRepresentable { get }
    var timer: Publisher { get }
    
    var operation: PresentingOperation { get }
    
    associatedtype RenderingContents: View
    var contents: RenderingContents { get }
    
    func mutateState(publisher: Publisher.Output)
}

extension BasicScreen {
    var body: some View {
        contents
            .onReceive(timer) { publisher in
                mutateState(publisher: publisher)
                draw()
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
    
    func mutateState(publisher: Publisher.Output) {}
}
