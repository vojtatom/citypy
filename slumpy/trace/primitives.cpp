#include "vec3.hpp"
#include "primitives.hpp"
#include "utils.hpp"

static size_t triIdx = 0;

Triangle::Triangle(vec3 _a, vec3 _b, vec3 _c)
: a(_a), b(_b), c(_c), e1(_b - _a), e2(_c - _a), id(triIdx++)
{}

// Möller-Trumbore algorithm
// Find intersection point - from PBRT - www.pbrt.org
// from https://cent.felk.cvut.cz/courses/APG/triangle-pbrt.cpp
// the source is modified, inspired by above
float Triangle::intersect(Ray & ray, bool cullback,  float & b1, float & b2)
{
    vec3 pvec = ray.dir.cross(e2);
    float det = e1.dot(pvec);

    if (cullback)
    {
        if (det < RTEPSILON) // ray is parallel to triangle
            return RTINFINITY;
    }
    else
    {
        if (fabs(det) < RTEPSILON) // ray is parallel to triangle
            return RTINFINITY;
    }

    float invDet = 1.0f / det;

    // Compute first barycentric coordinate
    vec3 tvec = ray.origin - a;
    b1 = tvec.dot(pvec) * invDet;

    if (b1 < 0.0f || b1 > 1.0f)
        return RTINFINITY;

    // Compute second barycentric coordinate
    vec3 qvec = tvec.cross(e1);
    b2 = ray.dir.dot(qvec) * invDet;

    if (b2 < 0.0f || b1 + b2 > 1.0f)
        return RTINFINITY;

    // Compute t to intersection point
    float t = e2.dot(qvec) * invDet;

    return t;
}

