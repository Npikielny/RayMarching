//
//  RayMarching3D.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

#include <metal_stdlib>
using namespace metal;
#include "SDF.h"

//constant float3 lightDirection = -normalize(float3(1));

//float3 groundPlane(Ray ray, float3 groundColor, float3 observer, float3 lightDirection) {
//    if (ray.direction.y < 0) {
//        float t = (-ray.origin.y / ray.direction.y);
//        float3 loc = t * ray.direction + ray.origin;
//        int3 l = int3(loc);
//        return 0.15 + float(abs((l.x + l.z) % 2)) * 0.05 * max(dot(float3(0, 1, 0), -lightDirection), 0.f);
//    }
//    return skyColor(ray, lightDirection);
//}

//void writeGroundPlane(uint2 tid, texture2d<float, access::write> image, Ray ray, float3 groundColor, float3 observer, float3 lightDirection) {
//    image.write(float4(groundPlane(ray, groundColor, observer, lightDirection), 1), tid);
//}


[[kernel]]
void rayMarch3D(uint2 tid [[thread_position_in_grid]],
                constant float4x4 * matrices,
                constant Object * objects,
                constant int & objectCount,
                constant Material * materials,
                constant int & maxIterations,
                constant float & precision,
                texture2d<float, access::write> out) {
    
    float4x4 modelMatrix = matrices[0];
    float4x4 projection = matrices[1];
    
    float2 uv = float2(tid) / float2(out.get_width(), out.get_height());
    Ray ray = createCameraRay(uv, modelMatrix, projection);
    
    float maxDistance = 30;
    
    float3 lightDirection = normalize(float3(-1, -4, 6));
    
    SDFRecord sdf = SDFRecord { 0 };
    for (int i = 0; i < maxIterations && sdf.distance < maxDistance; i ++) {
        ray.origin += ray.direction * sdf.distance;
        sdf = sceneDistance(objects, objectCount, ray);
        if (sdf.distance < precision) {
//            out.write(float4(materials[sdf.object.material].diffuse, 1), tid);
            out.write(float4(shade(sdf, materials[sdf.object.material], ray, lightDirection, precision), 1), tid);
            return;
        }
    }
//    return writeGroundPlane(tid, out, ray, groundColor, observer, lightDirection);
    out.write(float4(float3(0), 1), tid);
//    out.write(float4(materials[sdf.object.material].diffuse, 1), tid);
    return;
}
