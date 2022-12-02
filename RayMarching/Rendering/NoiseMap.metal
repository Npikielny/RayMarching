//
//  NoiseMap.metal
//  RayMarching
//
//  Created by Noah Pikielny on 11/30/22.
//

#include <metal_stdlib>
using namespace metal;
#include "NoiseMap.h"

//float noiseHeight(float verts[4], float2 min, float2 max, float2 xz) {
//    float sx = smoothstep(min.x, max.x, xz.x);
//    float sz = smoothstep(min.y, max.y, xz.y);
//    return (verts[1] - verts[0]) * sx +
//    (verts[2] - verts[0]) * sz +
//    (verts[0] - verts[1] - verts[2] + verts[3]) * sx * sz;
//}
//
//
