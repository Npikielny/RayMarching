//
//  SDF.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/27/22.
//

#include <metal_stdlib>
using namespace metal;
#include "SDF.h"


metal::float3x3 rotationMatrix(float3 rotation) {
    // z y x
    return metal::float3x3(metal::cos(rotation.z), -metal::sin(rotation.z), 0,
                           metal::sin(rotation.x), metal::cos(rotation.z), 0,
                           0, 0, 1) *
    // y
           metal::float3x3(metal::cos(rotation.y), 0, metal::sin(rotation.y),
                            0, 1, 0,
                            -metal::sin(rotation.y), 0, metal::cos(rotation.y)) *
           metal::float3x3(1, 0, 0,
                           0, metal::cos(rotation.x), -metal::sin(rotation.x),
                           0, metal::sin(rotation.x), metal::cos(rotation.x));
}

float3 toCoordinates(float3 p, float3 rotation) {
    return rotationMatrix(rotation) * p;
}

float planeDistance(Object plane, Ray ray) {
    float dir = plane.position.y - ray.origin.y;
    return dir * ray.direction.y > 0 ? dir : INFINITY;
//    metal::float3x3 r = rotationMatrix(plane.rotation);
//    float3 rOrigin = r * (ray.origin - plane.position);
////    float3 rDir = r * ray.direction;
//
//    return metal::abs(rOrigin.y);
}

float waterHeight(float3 position) {
//    float dist = metal::dot(position, float3(1, 0, 1));
    float3 p = position * float3(1, 0, 1) / 8 - float3(0, 0, 50);
    float dist = metal::dot(p, p);
    float dist2 = dist * dist;
    float dist4 = dist2 * dist2;
    float dist6 = dist4 * dist2;
    return -4.2 * dist2 + 3.2 * dist4 - dist6;
//    return metal::sin(p.x) * metal::sin(p.z) * 3 - 3;
}

float waterDistance(Ray ray) {
    float dist = ray.origin.y - waterHeight(ray.origin);
    if (dist > 1) {
        return dist * 0.8;
    } else {
        return dist * 0.1;
    }
}

float sphereDistance(Object sphere, Ray ray) {
    return metal::distance(ray.origin, sphere.position) - sphere.scale.x;
}

float max(float3 vals) {
    return metal::max(vals.x, metal::max(vals.y, vals.z));
}

float boxDistance(Object object, Ray ray) {
    float3 local = rotationMatrix(-object.rotation) * metal::abs(ray.origin - object.position);
    
    float3 diffs = local - object.scale / 2;
    
    if (diffs.x <= 0 && diffs.y <= 0 && diffs.z <= 0) {
        return metal::max(diffs.x, metal::max(diffs.y, diffs.z));
    } else {
        float3 clamped = metal::clamp(diffs, 0., INFINITY);
        return metal::sqrt(metal::dot(clamped, clamped));
    }
}

float distanceToObject(Object object, Ray ray) {
    switch (object.type) {
        case WATER:
            return waterDistance(ray);
            break;
        case SPHERE:
            return sphereDistance(object, ray);
            break;
        case PLANE:
            return planeDistance(object, ray);
            break;
        case BOX:
            return boxDistance(object, ray);
            break;
        default:
            break;
    }
    return INFINITY;
}

SDFRecord sceneDistance(constant Object * objects, int objectCount, Ray ray) {
    SDFRecord sdf;
    for (int i = 0; i < objectCount; i++) {
        Object object = objects[i];
        float dist = distanceToObject(object, ray);
        sdf.object = abs(sdf.distance) > dist ? object : sdf.object;
        sdf.distance = metal::min(abs(sdf.distance), dist);
    }
    
    return sdf;
}

float gradient(Ray ray, Object object, float3 direction, float precision) {
    float3 dt = direction * precision;
    ray.origin += dt;
    float d1 = distanceToObject(object, ray);
    ray.origin -= dt * 2;
    float d2 = distanceToObject(object, ray);
    return (d2 - d1);
}

float3 calculateNormal(Ray ray, Object object, float precision) {
    ray.origin -= ray.direction * precision;
    return -metal::normalize(float3(
                            gradient(ray, object, float3(1, 0, 0), precision),
                            gradient(ray, object, float3(0, 1, 0), precision),
                            gradient(ray, object, float3(0, 0, 1), precision)
                            )
                     );
}



float3 shade(SDFRecord sdf, Material material, Ray ray, float3 lightDirection, float precision) {
//    float3 sky = skyColor(ray, lightDirection);
    float3 normal = calculateNormal(ray, sdf.object, precision);
    
    return material.diffuse * (metal::max(metal::dot(-lightDirection, normal), 0.) + 0.15);
}
