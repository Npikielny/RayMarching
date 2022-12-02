//
//  Shared.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/28/22.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared.h"

Ray createRay(float3 origin, float3 direction) {
    Ray r;
    r.origin = origin;
    r.direction = direction;
    return r;
}

Ray createCameraRay(float2 uv, metal::float4x4 modelMatrix, metal::float4x4 projectionMatrix) {
    // Transform the camera origin to world space
    float3 origin = (modelMatrix * float4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;
    
    
    // Invert the perspective projection of the view-space position
    float3 direction = (projectionMatrix * float4(float2(-0.5, 0.5) + uv * float2(1, -1), 0.0f, 1.0f)).xyz;
    // Transform the direction from camera to world space and normalize
//    direction = (modelMatrix * float4(direction, 0.0f)).xyz;
    direction = metal::normalize(direction);
    return createRay(origin, direction);
}

template<typename T>
T lerp(T a, T b, float p) {
    return b * p + (1 - p) * a;
}

float3 skyColor(Ray ray, float3 lightDirection) {
    float cosPhi = metal::dot(ray.direction, -lightDirection);
//    if (cosPhi > 0.995) {
//        return lerp(float3(1, 0.7, 0.5), float3(1), (cosPhi - 0.995) / 0.005);
//    }
    
    return lerp(sky, scattering, metal::clamp(cosPhi, 0., 1.));
}

