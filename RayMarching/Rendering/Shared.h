//
//  Rendering.h
//  RayMarching
//
//  Created by Noah Pikielny on 11/27/22.
//

#ifndef Rendering_h
#define Rendering_h

constant float2 verts[] = {
    float2(-1, -1),
    float2(1, -1),
    float2(1, 1),
    
    float2(-1, -1),
    float2(1, 1),
    float2(-1, 1)
};

struct Vert {
    float4 position [[position]];
    float2 uv;
};

struct Ray {
    float3 origin;
    float3 direction;
};

Ray createRay(float3 origin, float3 direction);

Ray createCameraRay(float2 uv, metal::float4x4 modelMatrix, metal::float4x4 projectionMatrix);

constant float3 groundColor = float3(1, 0, 1);
constant float3 scattering = float3(0.57, 0.57, 0.93);
constant float3 sky = float3(0.25, 0.33, 1);

template<typename T>
T lerp(T a, T b, float p);

float3 skyColor(Ray ray, float3 lightDirection);
#endif /* Rendering_h */
