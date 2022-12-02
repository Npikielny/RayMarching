//
//  Rendering.metal
//  VRRenderingPipeline
//
//  Created by Noah Pikielny on 10/13/22.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared.h"
#include "SDF.h"

float2 flipUV(float2 in) {
    return float2(in.x, 1 - in.y);
}

[[vertex]]
Vert imageVert(uint vid [[vertex_id]]) {
    Vert vert;
    float2 textureVert = verts[vid];
    vert.position = float4(textureVert, 0, 1);
    vert.uv = textureVert * 0.5 + 0.5;
    vert.uv = flipUV(vert.uv);
    return vert;
}

constexpr metal::sampler sam(metal::min_filter::nearest, metal::mag_filter::nearest, metal::mip_filter::none);

constant float2 conversion = float2(60.f / 360.f, 60.f / 180.f);
[[fragment]]
float4 renderImages(Vert vert [[stage_in]],
                    texture2d<float> image,
                    constant float * angles,
                    constant int & eye) {
    float angle = angles[0];
    
    float2 uv = float2x2(
                         cos(angle), -sin(angle),
                         sin(angle), cos(angle)
                         ) * (vert.uv - 0.5) * conversion + 0.5;
    float2 offset = float2(angles[1], 0);
    uv += offset * conversion;
    float2 x = 1;
    uv = modf(uv, x);
    if (uv.x < 0) {
        uv.x += 1;
    }
    
    float4 color = image.sample(sam, uv);
//    return float4(1, 0, 0, 1);
    return float4(color.x, color.y, color.z, color.w);
}

struct Sphere {
    float4 position;
    float3 color;
};

struct Square {
    float3 position;
    float sideLength;
};

struct Circle {
    float2 position;
    float radius;
};

float getDistance(float2 position, Circle circle) {
    return length(circle.position - position) - circle.radius;
};

[[kernel]]
void rayMarch2D(uint2 tid [[thread_position_in_grid]],
                constant float & angle,
                texture2d<float, access::write> out) {
    
    float2 cameraPosition = float2(float(out.get_width()) / 2, float(out.get_height()) / 2);
    
    
    float2 circle1Position = float2(float(out.get_width()) / 4, float(out.get_height()) / 4);
    float circle1Radius = 20;
    
    Circle circle1;
    circle1.position = circle1Position;
    circle1.radius = circle1Radius;
    
    float2 circle2Position = float2(float(out.get_width()) / 4, float(out.get_height()) * 3 / 4);
    float circle2Radius = 20;
    Circle circle2;
    circle2.position = circle2Position;
    circle2.radius = circle2Radius;
    
    float2 circle3Position = float2(float(out.get_width()) * 3 / 4, float(out.get_height()) / 4);
    float circle3Radius = 20;
    Circle circle3;
    circle3.position = circle3Position;
    circle3.radius = circle3Radius;
    
    float2 circle4Position = float2(float(out.get_width()) * 3 / 4, float(out.get_height()) * 3 / 4);
    float circle4Radius = 20;
    Circle circle4;
    circle4.position = circle4Position;
    circle4.radius = circle4Radius;
    
    float2 circle5Position = float2(float(out.get_width()) / 4, float(out.get_height()) / 2);
    float circle5Radius = 20;
    Circle circle5;
    circle5.position = circle5Position;
    circle5.radius = circle5Radius;
    
    Circle circles[5] = {circle1, circle2, circle3, circle4, circle5};
    
    float dist = distance(float2(tid), cameraPosition);
    if (dist < 4) {
        out.write(float4(1), tid);
        return;
    }
    
    
    for (int i = 2; i < 5; i++) {
        if (getDistance(float2(tid), circles[i]) <= 0) {
            out.write(float4(1,0,0,1), tid);
            return;
        }
    }
    
//    sdf = sceneDistance(objects, objectCount, ray);
    
    float2 marchDirection = float2(cos(angle), sin(angle));
    
    for (int i = 0; i < 10; i++) {
//        float cameraToCircle = getDistance(cameraPosition, circles[i]);
        
        float cameraToCircle = 1000;
        for (int i = 2; i < 5; i++) {
            cameraToCircle = min(cameraToCircle, getDistance(cameraPosition, circles[i]));
        }
        Circle step;
        step.position = cameraPosition;
        step.radius = cameraToCircle;
        
        if (getDistance(float2(tid), step) <= 0 && getDistance(float2(tid), step) >= -1) {
            out.write(float4(0,0,1,1), tid);
            return;
        }
        
        cameraPosition = cameraPosition + normalize(marchDirection) * step.radius;
        float newDist = distance(float2(tid), cameraPosition);
        if (newDist < 4) {
            out.write(float4(1), tid);
            return;
        }
    }
    out.write(float4(float3(0), 1), tid);
}

[[fragment]]
float4 copyToDrawable(Vert vert [[stage_in]],
                      texture2d<float, access::sample>image) {
    return image.sample(sam, vert.uv);
}
