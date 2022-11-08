//
//  SDF.h
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

#ifndef SDF_h
#define SDF_h

enum ObjectType {
    PLANE = -1,
    SPHERE = 0,
    BOX = 1
};

struct Object {
    int type;
    float3 position;
    float3 rotation;
    float3 scale;
    int material;
};

struct Material {
    float3 diffuse;
    float3 specular;
};

struct Ray {
    float3 origin;
    float3 direction;
};

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
    float3 direction = (projectionMatrix * float4(uv - 0.5, 0.0f, 1.0f)).xyz;
    // Transform the direction from camera to world space and normalize
    direction = (modelMatrix * float4(direction, 0.0f)).xyz;
    direction = metal::normalize(direction);
    return createRay(origin, direction);
}

struct SDFRecord {
    float distance = INFINITY;
    Object object;
};

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
    return metal::abs(plane.position.y - ray.origin.y);
//    metal::float3x3 r = rotationMatrix(plane.rotation);
//    float3 rOrigin = r * (ray.origin - plane.position);
////    float3 rDir = r * ray.direction;
//
//    return metal::abs(rOrigin.y);
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

SDFRecord sceneDistance(constant Object * objects, int objectCount, Ray ray) {
    SDFRecord sdf;
    for (int i = 0; i < objectCount; i++) {
        Object object = objects[i];
        float dist = INFINITY;
        switch (object.type) {
            case SPHERE:
                dist = sphereDistance(object, ray);
                break;
            case PLANE:
                dist = planeDistance(object, ray);
                break;
            case BOX:
                dist = boxDistance(object, ray);
                break;
            default:
                break;
        }
        if (dist < sdf.distance) {
            sdf.distance = dist;
            sdf.object = object;
            if (dist == 0) {
                return sdf;
            }
        }
    }
    
    return sdf;
}

#endif /* SDF_h */
