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
                Object(type: .sphere, position: Float3.random() * 20 + Float3(0, 0, 15), rotation: Float3(0, 0, 0), scale: Float3(1, 1, 1), material: Int32(i % materialCount))
            }
        
        return Self(materials: materials, objects: objects)
    }
}
