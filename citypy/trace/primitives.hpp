#pragma once
#include "vec3.hpp"

//#include "scene.hpp"

using namespace std;

struct Triangle;

struct alignas(16) AlignedPrimitive {
    inline void *operator new[](size_t x)
    {
        return _aligned_malloc(x, 16);
    }

    inline void *operator new(size_t x)
    {
        return _aligned_malloc(x, 16);
    }

    inline void operator delete[](void *x)
    {
        if (x)
            _aligned_free(x);
    }
};

struct Ray : public AlignedPrimitive
{
    vec3 origin;
    vec3 dir;
    Triangle * hit;
    float t;
    float barX, barY;
};

struct Triangle : public AlignedPrimitive
{
    Triangle(vec3 _a, vec3 _b, vec3 _c);
    float intersect(Ray & ray, bool cullback, float & b1, float & b2);

    vec3 a, b, c;
    vec3 e1, e2; 
    size_t id;
};