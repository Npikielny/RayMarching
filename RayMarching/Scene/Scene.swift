//
//  Scene.swift
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

import Foundation

struct Scene3D {
    var materials: [Material]
    var objects: [Object]
    
    static func randomScene(objectCount: Int) -> Self {
        assert(objectCount > 0)
        let materialCount = Int.random(in: 1..<objectCount)
        let materials = (0..<materialCount)
            .map { _ in Material.random() }
        
        let objects = (0..<objectCount)
            .map { i in
                if Int.random(in: 0...1) == 0 {
                    return Object(type: .sphere, position: Float3.randomDirection() * Float.random(in: 10...30), rotation: Float3(0, 0, 0), scale: Float3(repeating: Float.random(in: 0.5...3)), material: Int32(i % materialCount))
                } else {
                    return Object(type: .box, position: Float3.randomDirection() * Float.random(in: 10...30), rotation: Float3(0, 0, 0), scale: Float3.random(in: 1...4), material: Int32(i % materialCount))
                }
            } //+ [Object.plane(position: Float3.zero, rotation: Float3.zero, scale: Float3.zero, material: 0)]
        
        return Self(materials: materials, objects: objects)
    }
    
    static func testingScene() -> Self {
        let material = Material.random()
        
        let object = Object.box(position: Float3(0, 0, 10), rotation: Float3.zero, scale: Float3(3, 4, 1), material: 0)
        
        return Self(materials: [material], objects: [object])
    }
}
