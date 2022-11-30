//
//  RenderingEngine.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/27/22.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared.h"
//#include "SDF.h"

enum SurfaceType {
    WATER,
    TERRAIN,
    NONE
};

float3 color(SurfaceType surface, float3 position) {
    switch (surface) {
        case WATER:
            return float3(0, 0, 1);
        case TERRAIN:
            return float3(0, 1, 0);
        case NONE:
            return 0.;
    }
}

struct SDFRecord {
    SurfaceType surface = NONE;
    float t = INFINITY;
    float3 normal = 0.;
};

float terrainHeight(float2 xz) {
    return -dot(xz / 8, xz / 8) + 1;
//    return sin(xz.x + 0.5) * cos(xz.y + 0.5) - 5;
//    return 0;
}

float waterHeight(float2 xz, float time) {
    float y = -5;
    float t = terrainHeight(xz);
    float water = clamp(abs(t - y), 0.f, 1.f) * (sin(xz.x - time) + sin(M_PI_F * xz.x - 2 * time) / 2) / 3 * 2 * cos(xz.y) + y;;
    return water;
}

//SDFRecord waterSDF(Ray ray, float maxT, float precision) {
//    for (float t = 0; t < maxT; t += precision) {
//        float dist = abs(waterHeight(ray.origin.xz) - ray.origin.y);
//        if (dist <= precision) {
//            return { WATER, t };
//        }
//        ray.origin += ray.direction * precision;
//    }
//    return SDFRecord();
//}

SDFRecord min(SDFRecord a, SDFRecord b) {
    return b.t < a.t ? b : a;
}

void normal(thread SDFRecord & r, Ray ray) {
    switch (r.surface) {
        case WATER:
            r.normal = float3(0, 1, 0);
            break;
        case TERRAIN:
            r.normal = float3(0, 1, 0);
            break;
        case NONE:
            break;
    }
}

float mapHeight(float3 position, SurfaceType surface, float time) {
    switch (surface) {
        case WATER:
            return abs(waterHeight(position.xz, time) - position.y);
        case TERRAIN:
            return abs(terrainHeight(position.xz) - position.y);
        case NONE:
            return INFINITY;
    }
}

SDFRecord mapHeights(Ray ray, float time) {
    SDFRecord water = { WATER, mapHeight(ray.origin, WATER, time) };
    SDFRecord terrain = { TERRAIN, mapHeight(ray.origin, TERRAIN, time) };
    return min(water, terrain);
}

float gradient(Ray ray, float3 direction, float precision, SurfaceType surface, float time) {
    float3 position = ray.origin - ray.direction * precision;
    float3 dt = direction * precision;
    float d1 = mapHeight(position + dt, surface, time);
    float d2 = mapHeight(position - dt, surface, time);
    return (d2 - d1);
}

float3 getNormal(Ray ray, float precision, SurfaceType surface, float time) {
    return -metal::normalize(
//                             float3(
//                                    gradient(position, float3(1, 0, 0), precision, surface, time),
//                                    gradient(position, float3(0, 1, 0), precision, surface, time),
//                                    gradient(position, float3(0, 0, 1), precision, surface, time)
//                                    )
                            float3(
                                   gradient(ray, float3(1, 0, 0), precision, surface, time),
                                   gradient(ray, float3(0, 1, 0), precision, surface, time),
                                   gradient(ray, float3(0, 0, 1), precision, surface, time)
                                   )
                             );
//    return normalize(float3(cos(position.x) * cos(position.z),
//                            abs(sin(position.x) * cos(position.z)),
//                            sin(position.x) * -sin(position.z)
//                            )
//                     );
}

SDFRecord sdf(Ray ray, float maxT, float precision, float time) {
    SDFRecord r;
    float dist = dist;
    for (float t = 0; t < maxT; t += dist) {
        SDFRecord temp = mapHeights(ray, time);
        dist = temp.t / 4;
        ray.origin += ray.direction * dist;
        if (temp.t <= precision) {
            temp.normal = getNormal(ray, precision, temp.surface, time);
            return temp;
        }
    }
    return SDFRecord();
    
    
    return r;
}





//float terrainSDF(Ray ray, float minT, float maxT, )

//
//float3 sceneNormal(Ray ray, float precision) {
//    ray.origin -= ray.direction * precision;
//    return -metal::normalize(
//                             float3(
//                                    derivative(ray, float3(1, 0, 0), precision),
//                                    derivative(ray, float3(0, 1, 0), precision),
//                                    derivative(ray, float3(0, 0, 1), precision)
//                                    )
//                             );
//}

[[kernel]]
void realisticScene(uint2 tid [[thread_position_in_grid]],
                constant float4x4 * matrices,
                constant float & precision,
                    constant float & time,
                texture2d<float, access::write> out) {
    
    float4x4 modelMatrix = matrices[0];
    float4x4 projection = matrices[1];
    
    float2 uv = float2(tid) / float2(out.get_width(), out.get_height());
    
    Ray ray = createCameraRay(uv, modelMatrix, projection);
    
    float maxDistance = 100;
    
    float3 lightDirection = normalize(float3(-1, -4, 6));
    
    SDFRecord r = sdf(ray, maxDistance, precision, time);
    if (r.t != INFINITY) {
        return out.write(float4(color(r.surface, ray.origin + ray.direction * r.t) * (dot(r.normal, -lightDirection) + 0.2) / 1.2, 1), tid);
//        return out.write(float4(r.normal, 1), tid);
//        return out.write(float4(color(r.surface, ray.origin + ray.direction * r.t), 1), tid);
//        return out.write(float4(r.normal * 0.5 + 0.5, 1), tid);
//        return out.write(1, tid);
    }
    
//    for (int i = 0; i < maxIterations && abs(distance) < maxDistance; i ++) {
//        ray.origin += ray.direction * distance;
//        distance = terrainSDF(ray);
////        distance = castRay(ray);
//        if (distance < precision) {
//            float3 normal = sceneNormal(ray, precision);
//            return out.write(1 * abs(dot(lightDirection, normal)), tid);
////            return out.write(float4(1), tid);
//
////            out.write(float4(materials[sdf.object.material].diffuse, 1), tid);
////            return float4(shade(sdf, materials[sdf.object.material], ray, lightDirection), 1);
//        }
//    }
    return out.write(float4(skyColor(ray, lightDirection), 1), tid);
//    return out.write(float4(float3(0), 1), tid);
}

