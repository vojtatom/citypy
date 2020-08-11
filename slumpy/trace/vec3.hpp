#pragma once
#include <cstdlib>
#include <cmath>
#include <cassert>
#include <iostream>
#include <smmintrin.h>
#include "utils.hpp"

//for linux
#define _aligned_malloc(size, alignment) aligned_alloc(alignment, size)
#define _aligned_free(ptr) free(ptr)

using namespace std;

#ifndef USESSE

struct vec3
{
    vec3() : x(0), y(0), z(0)
    {
    };

    vec3(float _x)
        : x(_x), y(_x), z(_x)
    {
    };

    vec3(float _x, float _y, float _z)
        : x(_x), y(_y), z(_z)
    {
    };

    inline float &operator[](size_t idx) const
    {
        return ((float *)this)[idx];
    }

    inline void operator+=(const vec3 &op)
    {
        x += op.x, y += op.y, z += op.z;
    }

    inline void operator*=(const vec3 &op)
    {
        x *= op.x, y *= op.y, z *= op.z;
    }

    inline void operator-=(const vec3 &op)
    {
        x -= op.x, y -= op.y, z -= op.z;
    }

    inline void operator/=(const float &op)
    {
        x /= op, y /= op, z /= op;
    }

    inline vec3 operator+(const vec3 &op) const
    {
        return vec3(x + op.x, y + op.y, z + op.z);
    }

    inline vec3 operator-(const vec3 &op) const
    {
        return vec3(x - op.x, y - op.y, z - op.z);
    }

    inline vec3 operator-() const
    {
        return vec3(-x, -y, -z);
    }

    inline vec3 operator*(const vec3 &op) const
    {
        return vec3(x * op.x, y * op.y, z * op.z);
    }

    inline vec3 operator*(const float &op) const
    {
        return vec3(x * op, y * op, z * op);
    }

    inline vec3 operator/(const vec3 &op) const
    {
        return vec3(x / op.x, y / op.y, z / op.z);
    }

    inline vec3 cross(const vec3 &op) const
    {
        return vec3(
            y * op.z - z * op.y,
            z * op.x - x * op.z,
            x * op.y - y * op.x);
    }

    inline float dot(const vec3 &op) const
    {
        return x * op.x + y * op.y + z * op.z;
    }

    inline void normalize()
    {
        float size = sqrtf(x * x + y * y + z * z);
        x /= size;
        y /= size;
        z /= size;
    }

    inline vec3 getNormalized() const
    {
        float size = sqrtf(x * x + y * y + z * z);
        return vec3(x / size, y / size, z / size);
    }

    inline float length() const
    {
        return sqrtf(x * x + y * y + z * z);
    }

    float x;
    float y;
    float z;
};

inline vec3 operator*(const float &op1, const vec3 &op2)
{
    return vec3(op2.x * op1, op2.y * op1, op2.z * op1);
}

//tu byl bug op1 / op2  a ne op2 / op1 jako výše 
inline vec3 operator/(const float &op1, const vec3 &op2)
{
    return vec3(op1 / op2.x, op1 / op2.y, op1 / op2.z);
}


#else



struct alignas(16) vec3
{
public:
    // constructors
    inline vec3() : mmvalue(_mm_setzero_ps()) {}
    inline vec3(float x, float y, float z) : mmvalue(_mm_set_ps(0, z, y, x)) {}
    inline vec3(float x) : mmvalue(_mm_set_ps(0, x, x, x)) {}
    inline vec3(__m128 m) : mmvalue(m) {}

    float &operator[](size_t idx) const
    {
        return ((float *)this)[idx];
    }

    inline vec3 operator-() const
    {
        return _mm_sub_ps(_mm_set_ps(0, 0, 0, 0), mmvalue);
    }

    // arithmetic operators with vec3
    inline vec3 operator+(const vec3 &b) const
    {
        return _mm_add_ps(mmvalue, b.mmvalue);
    }
    inline vec3 operator-(const vec3 &b) const
    {
        return _mm_sub_ps(mmvalue, b.mmvalue);
    }
    inline vec3 operator*(const vec3 &b) const
    {
        return _mm_mul_ps(mmvalue, b.mmvalue);
    }
    inline vec3 operator/(const vec3 &b) const
    {
        return _mm_div_ps(mmvalue, b.mmvalue);
    }

    // op= operators
    inline vec3 &operator+=(const vec3 &b)
    {
        mmvalue = _mm_add_ps(mmvalue, b.mmvalue);
        return *this;
    }
    inline vec3 &operator-=(const vec3 &b)
    {
        mmvalue = _mm_sub_ps(mmvalue, b.mmvalue);
        return *this;
    }
    inline vec3 &operator*=(const vec3 &b)
    {
        mmvalue = _mm_mul_ps(mmvalue, b.mmvalue);
        return *this;
    }
    inline vec3 &operator/=(const vec3 &b)
    {
        mmvalue = _mm_div_ps(mmvalue, b.mmvalue);
        return *this;
    }

    // arithmetic operators with float
    inline vec3 operator+(float b) const
    {
        return _mm_add_ps(mmvalue, _mm_set1_ps(b));
    }
    inline vec3 operator-(float b) const
    {
        return _mm_sub_ps(mmvalue, _mm_set1_ps(b));
    }
    inline vec3 operator*(float b) const
    {
        return _mm_mul_ps(mmvalue, _mm_set1_ps(b));
    }
    inline vec3 operator/(float b) const
    {
        return _mm_div_ps(mmvalue, _mm_set1_ps(b));
    }

    // op= operators with float
    inline vec3 &operator+=(float b)
    {
        mmvalue = _mm_add_ps(mmvalue, _mm_set1_ps(b));
        return *this;
    }
    inline vec3 &operator-=(float b)
    {
        mmvalue = _mm_sub_ps(mmvalue, _mm_set1_ps(b));
        return *this;
    }
    inline vec3 &operator*=(float b)
    {
        mmvalue = _mm_mul_ps(mmvalue, _mm_set1_ps(b));
        return *this;
    }
    inline vec3 &operator/=(float b)
    {
        mmvalue = _mm_div_ps(mmvalue, _mm_set1_ps(b));
        return *this;
    }

    // cross product
    inline vec3 cross(const vec3 &b) const
    {
        return _mm_sub_ps(
            _mm_mul_ps(_mm_shuffle_ps(mmvalue, mmvalue, _MM_SHUFFLE(3, 0, 2, 1)), _mm_shuffle_ps(b.mmvalue, b.mmvalue, _MM_SHUFFLE(3, 1, 0, 2))),
            _mm_mul_ps(_mm_shuffle_ps(mmvalue, mmvalue, _MM_SHUFFLE(3, 1, 0, 2)), _mm_shuffle_ps(b.mmvalue, b.mmvalue, _MM_SHUFFLE(3, 0, 2, 1))));
    }

    // dot product with another vector
    inline float dot(const vec3 &b) const
    {
        return _mm_cvtss_f32(_mm_dp_ps(mmvalue, b.mmvalue, 0x71));
    }

    // length of the vector
    inline float length() const
    {
        return _mm_cvtss_f32(_mm_sqrt_ss(_mm_dp_ps(mmvalue, mmvalue, 0x71)));
    }

    // returns the vector scaled to unit length
    inline void normalize()
    {
        mmvalue = _mm_div_ps(mmvalue, _mm_sqrt_ps(_mm_dp_ps(mmvalue, mmvalue, 0x7F)));
    }

    inline vec3 getNormalized() const
    {
        return _mm_div_ps(mmvalue, _mm_sqrt_ps(_mm_dp_ps(mmvalue, mmvalue, 0x7F)));
    }

    // overloaded operators that ensure alignment
    inline void *operator new[](size_t x)
    {
        return _aligned_malloc(x, 16);
    }
    inline void operator delete[](void *x)
    {
        if (x)
            _aligned_free(x);
    }

    // Member variables

    union {
        float xyz[4];
        __m128 mmvalue;
    };
};

inline vec3 operator+(float a, const vec3 &b) { return b + a; }
inline vec3 operator-(float a, const vec3 &b) { return vec3(_mm_set1_ps(a)) - b; }
inline vec3 operator*(float a, const vec3 &b) { return b * a; }
inline vec3 operator/(float a, const vec3 &b) { return vec3(_mm_set1_ps(a)) / b; }

#endif
ostream &operator<<(ostream &os, const vec3 &v);
