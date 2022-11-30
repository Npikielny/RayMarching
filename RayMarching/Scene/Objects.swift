//
//  Objects.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

import Foundation
import ShaderKit

typealias Float3 = SIMD3<Float>

struct Object: GPUEncodable {
    var type: Int32
    var position: Float3
    var rotation: Float3
    var scale: Float3
    var material: Int32
    
    enum ObjectType: Int32 {
        case water = -2
        case plane = -1
        case sphere = 0
        case box = 1
    }
    
    init(type: ObjectType, position: Float3, rotation: Float3, scale: Float3, material: Int32) {
        self.type = type.rawValue
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.material = material
    }
    
    static func sphere(position: Float3, rotation: Float3, scale: Float, material: Int32) -> Self {
        Object(type: .sphere, position: position, rotation: rotation, scale: Float3(repeating: scale), material: material)
    }
    
    static func plane(position: Float3, rotation: Float3, scale: Float3, material: Int32) -> Self {
        Object(type: .plane, position: position, rotation: rotation, scale: scale, material: material)
    }
    
    static func water(position: Float3, rotation: Float3, scale: Float3, material: Int32) -> Self {
        Object(type: .water, position: position, rotation: rotation, scale: scale, material: material)
    }
    
    static func box(position: Float3, rotation: Float3, scale: Float3, material: Int32) -> Self {
        Object(type: .box, position: position, rotation: rotation, scale: scale, material: material)
    }
}

struct Material: GPUEncodable {
    var diffuse: Float3
    var specular: Float3
    
    static func random() -> Material {
        Material(diffuse: Float3.random(), specular: Float3.random())
    }
}

extension Float3 {
    static func random() -> Float3 {
        var values = (0..<3)
            .map { _ in Float.random(in: 0...1) }
        let sum = values.reduce(0, +)
        values = values.map { $0 / sum }
        
        return Float3(values[0], values[1], values[2])
    }
    
    static func randomDirection() -> Float3 {
        let x1 = Float.random(in: 0...1)
        let x2 = Float.random(in: 0...1)
        
        let phi = x1 * Float.pi * 2;
        let theta = acos(1 - 2 * x2);
            return Float3(
                cos(phi) * sin(theta),
                sin(phi) * sin(theta),
                cos(theta))
    }
}
