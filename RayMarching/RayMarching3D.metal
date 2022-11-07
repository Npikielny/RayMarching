//
//  RayMarching3D.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

#include <metal_stdlib>
#include "SDF.h"
using namespace metal;

//constant float3 lightDirection = -normalize(float3(1));

[[kernel]]
void rayMarch3D(uint2 tid [[thread_position_in_grid]],
                constant float4x4 * matrices,
                constant Object * objects,
                constant int & objectCount,
                constant Material * materials,
                texture2d<float, access::write> out) {
    
//    float4x4 projection = {
//        1, 0, 0, 0,
//        0, 1, 0, 0,
//        0, 0, 1, 0,
//        0, 0, 0, 1
//    };
    float4x4 modelMatrix = matrices[0];
    float4x4 projection = matrices[1];
    
    float2 uv = float2(tid) / float2(out.get_width(), out.get_height());
    Ray ray = createCameraRay(uv, modelMatrix, projection);
    
    int maxDistance = 100;
    int maxIterations = 40;
    for (int i = 0; i < maxIterations; i ++) {
        SDFRecord sdf = sceneDistance(objects, objectCount, ray);
        if (sdf.distance < 0.1) {
            float3 lightDirection = -normalize(float3(1));
            float3 normal = normalize(ray.origin - sdf.object.position);
            float cosTheta = dot(normal, lightDirection);
            out.write(float4(cosTheta * materials[sdf.object.material].diffuse, 1), tid);
            return;
        }
        ray.origin += ray.direction * sdf.distance;
        if (sdf.distance >= maxDistance) {
            out.write(float4(float3(float(i)/float(maxIterations)), 1), tid);
            return;
        }
    }
    out.write(float4(float3(0), 1), tid);
    return;
}
