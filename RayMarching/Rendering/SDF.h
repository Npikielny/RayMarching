//
//  SDF.h
//  RayMarching
//
//  Created by Noah Pikielny on 11/4/22.
//

#ifndef SDF_h
#define SDF_h

#include "Shared.h"

enum ObjectType {
    WATER = -2,
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

struct SDFRecord {
    float distance = INFINITY;
    Object object;
};

metal::float3x3 rotationMatrix(float3 rotation);

float3 toCoordinates(float3 p, float3 rotation);

float planeDistance(Object plane, Ray ray);

float waterHeight(float3 position);


float waterDistance(Ray ray);

float sphereDistance(Object sphere, Ray ray);

float max(float3 vals);

float boxDistance(Object object, Ray ray);
float distanceToObject(Object object, Ray ray);

SDFRecord sceneDistance(constant Object * objects, int objectCount, Ray ray);

float gradient(Ray ray, Object object, float3 direction, float precision);
float3 calculateNormal(Ray ray, Object object, float precision);

float3 shade(SDFRecord sdf, Material material, Ray ray, float3 lightDirection, float precision);


#endif /* SDF_h */
