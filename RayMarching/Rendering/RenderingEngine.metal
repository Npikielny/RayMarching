//
//  RenderingEngine.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/27/22.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared.h"

enum SurfaceType {
    WATER,
    TERRAIN,
    NONE
};

float hash(float2 xz) {
    xz = fract(30 * xz / M_PI_F);
    return fract(dot(xz, xz) + dot(xz, float2(xz.y, xz.x)));
}

float hash2(float2 xz) {
    xz = fract(17 * xz * 0.9072452);
    return fract(dot(xz, xz) + dot(xz, float2(xz.y, xz.x)));
}


float smoothInterpolate(float a, float b, float c, float d, float2 min, float2 max, float2 xz) {
    float sx = smoothstep(min.x, max.x, xz.x);
    float sz = smoothstep(min.y, max.y, xz.y);
    return a +
    (b - a) * sx +
    (c - a) * sz +
    (a - b - c + d) * sx * sz;
    
//    float p = (xz.x - min.x) / (max.x - min.x);
//    float ab = mix(a, b, p);
//    float cd = mix(c, d, p);
//    return mix(ab, cd, (xz.y - min.y) / (max.y - min.y));
}

float3 color(SurfaceType surface, float3 position, float3 normal) {
    switch (surface) {
        case WATER:
            return float3(0, 0, 1);
        case TERRAIN:
            float f = smoothstep(-5, -1.75, position.y);
            return f * float3(0.15, 0.85, 0.32) + (1 - f) * float3(1, 0.62, 0.35);
    }
    return 0.;
}


struct MapRecord {
    SurfaceType surface;
    float height;
};

struct SDFRecord {
    SurfaceType surface = NONE;
    float t = INFINITY;
    float3 normal = 0.;
};

float randomTerrain(float2 xz) {
    float2 m = floor(xz);
    return smoothInterpolate(hash(m), hash(m + float2(1, 0)), hash(m + float2(0, 1)), hash(m + 1), m, m + 1, xz);
}

float randomOveraly(float2 xz) {
    float2 m = floor(xz);
    return smoothInterpolate(hash2(m), hash2(m + float2(1, 0)), hash2(m + float2(0, 1)), hash2(m + 1), m, m + 1, xz);
}

constant float2x2 rotation = float2x2 {
    8. / 17., -15. / 17.,
    15. / 17., 8. / 17.
};

float terrainHeight(float2 xz) {
    
//    float2 center = floor(xz) + 0.5;
    float base = -dot(xz / 12, xz / 12) + 0.25;
    float f = randomTerrain(xz / 3) + randomOveraly(xz * 1.342 + float2(M_PI_F * M_PI_F, M_E_F * M_PI_F)) / 2;
    return smoothstep(-5, 0.25, base) * f + base;
}

float waterHeight(float2 xz, float time) {
    float y = -5;
    float t = terrainHeight(xz);
    float spread = 4.f;
    float x = (sin(xz.x / spread - time) + sin(M_PI_F * xz.x / spread - 2 * time) / 2) / 3 * 2;
    float z = (cos(xz.y / spread) + sin(M_PI_F * xz.y / spread - 2 * time) / 2) / 3 * 2;
    float water = clamp(sqrt(abs(t - y)), 0.f, 1.f) * x * z + y;
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

MapRecord min(MapRecord a, MapRecord b) {
    return b.height < a.height ? b : a;
}

MapRecord max(MapRecord a, MapRecord b) {
    return b.height > a.height ? b : a;
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
        case WATER: return waterHeight(position.xz, time);
        case TERRAIN: return terrainHeight(position.xz);
        case NONE: return -INFINITY;
    }
}

MapRecord mapHeights(Ray ray, float time) {
    MapRecord water = { WATER, mapHeight(ray.origin, WATER, time) };
    MapRecord terrain = { TERRAIN, mapHeight(ray.origin, TERRAIN, time) };
    return max(water, terrain);
}

float3 pack(float2 xz, float y) {
    return float3(xz.x, y, xz.y);
}

float gradient(Ray ray, float3 direction, float precision, SurfaceType surface, float time) {
    float3 position = ray.origin;
    float3 dt = direction * precision;
    float d1 = mapHeight(position - dt, surface, time);
    float d2 = mapHeight(position + dt, surface, time);
    return (d2 - d1) / (2 * precision);
}

float3 mapNormal(Ray ray, float precision, SurfaceType surface, float time) {
    float3 n = float3(gradient(ray, float3(1, 0, 0), precision, surface, time),
                      1,
                      gradient(ray, float3(0, 0, 1), precision, surface, time)
                      );
    return normalize(n);
}

SDFRecord sdf(Ray parent, float maxT, float precision, float time) {
    Ray ray = parent;
    float d = 0;
    for (float t = 0; t < maxT; t += max(precision, d / 2)) {
        ray.origin = parent.origin + ray.direction * t;
        MapRecord temp = mapHeights(ray, time);
//        dist = temp.t / 4;
        if (ray.origin.y <= temp.height) {
            return SDFRecord {
                temp.surface,
                t,
                mapNormal(ray, precision, temp.surface, time)
            };
        }
        d += temp.height - ray.origin.y;
    }
    return SDFRecord();
}

float3 environment(float3 direction, float3 p, float time, float3 lightDirection) {
    float3 sky = float3(0.3,0.5,0.85) - direction.y * direction.y * 0.5;
    sky = mix(sky, 0.85 * float3(0.7, 0.75, 0.85), pow(1.0 - max(direction.y, 0.0), 4.0));
    
    float dToSky = 2500 / direction.y;
    p += direction * dToSky;
    sky += smoothstep(0, 1, randomTerrain(p.xz / 10000 + time)) * 0.1;
    
    float sundot = clamp(dot(direction, lightDirection * float3(1, -1, 1)), 0.f, 1.f);
    
    sky += 0.25 * float3(1.0, 0.7, 0.4) * pow(sundot, 5.0);
    sky += 0.25 * float3(1.0, 0.8, 0.6) * pow(sundot, 64.0);
    sky += 0.2 * float3(1.0, 0.8, 0.6) * pow(sundot, 512.0);
    
    
    return sky;
}

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
    
    float maxDistance = 150;
    
    float3 lightDirection = normalize(float3(sin(time), -0.25, cos(time)));
    
    SDFRecord r = sdf(ray, maxDistance, precision, time);
    
    float3 env = environment(ray.direction, ray.origin, time, lightDirection);
    
    if (r.t != INFINITY) {
        float3 p = ray.origin + ray.direction * r.t;
        float3 result = color(r.surface, p, r.normal) * (saturate(dot(r.normal, -lightDirection)) + env * 0.2) / 1.2;
        if (r.surface == WATER) {
            float3 dir = reflect(ray.direction, r.normal);
            dir *= dir.y < 0 ? -1 : 1;
            float3 reflection = environment(dir, p, time, lightDirection);
            result = reflection * 0.75 + result * 0.25;
        }
        float attenuation = exp(-0.0125f / 2 * r.t);
        
        return out.write(float4(result * attenuation + (1 - attenuation) * float3(0.25, 0.5, 1), 1), tid);
        
    }
    
    return out.write(float4(float3(env), 1), tid);
}

