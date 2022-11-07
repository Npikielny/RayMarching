//
//  SDF.h
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

#ifndef SDF_h
#define SDF_h

enum ObjectType {
    SPHERE = 0
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

float sphereDistance(Object sphere, Ray ray) {
    return metal::distance(ray.origin, sphere.position) - sphere.scale.x;
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
                
            default:
                break;
        }
        if (dist < sdf.distance) {
            sdf.distance = dist;
            sdf.object = object;
        }
    }
    return sdf;
}

#endif /* SDF_h */
