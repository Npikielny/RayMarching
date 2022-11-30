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
            }
        
        print(objects.filter { $0.position.y < 0 }.count)
        
        return Self(materials: materials, objects: objects)
    }
    
    static func waterScene() -> Self {
        let material = Material(diffuse: Float3(0.25, 0.25, 1), specular: Float3.one)
        let water = Object.water(position: Float3.zero, rotation: Float3.zero, scale: Float3.zero, material: 0)
        return Self(materials: [material], objects: [water])
    }
    
    static func testingScene() -> Self {
//        let material = Material.random()
//        let m1 = Material(diffuse: Float3(1, 0, 0), specular: Float3.zero)
//        let m2 = Material(diffuse: Float3(0, 1, 0), specular: Float3.zero)
//        let m3 = Material(diffuse: Float3(0, 0, 1), specular: Float3.zero)
        
//        let objects = (0...5).map { _ in
//            Object(type: .box, position: Float3.randomDirection() * Float.random(in: 10...30), rotation: Float3.random(in: 0...Float.pi * 2), scale: Float3.random(in: 1...4), material: 0)
//        }
        
//        let objects = [
////            Object.plane(position: Float3.zero, rotation: Float3.zero, scale: Float3.zero, material: 2),
//            Object.sphere(position: Float3(0, 0, 10), rotation: Float3.zero, scale: 3, material: 0),
//            Object.box(position: Float3(-10, 0, 10), rotation: Float3.zero, scale: Float3(3, 4, 1), material: 0),
//            Object.box(position: Float3(0, 10, 10), rotation: Float3.zero, scale: Float3(3, 4, 1), material: 1),
//            Object.box(position: Float3(10, 20, 10), rotation: Float3.zero, scale: Float3(3, 4, 1), material: 2),
//        ]
        
//        return Self(materials: [m1, m2, m3], objects: objects)
        return randomScene(objectCount: 30)
    }
}
