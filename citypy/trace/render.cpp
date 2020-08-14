#include "vec3.hpp"
#include "primitives.hpp"
#include "bvh.hpp"
#include "utils.hpp"

#include <iostream>

using namespace std;

inline void validate_add(float low, float high, float & factor, float & out, float & value) {
    if (value >= low && value <= high) {
        factor += 1.0f;
        out += value;
    }
}

void denoise(float * height, unsigned int x, unsigned int y, float low, float high) {
    
    float value;
    float factor;
    bool t, b, r, l;
    for (size_t j = 0; j < y; j++)
    {
        for (size_t i = 0; i < x; i++)
        {
            if (height[j * x + i] < low || height[j * x + i] > high) {
                value = 0;
                factor = 0;

                t = (j == 0);
                b = (j == y - 1);
                r = (i == x - 1);
                l = (i == 0);
                
                //top row
                if (!t) {
                    if (!l)
                        validate_add(low, high, factor, value, height[(j - 1) * x + (i - 1)]);
                    validate_add(low, high, factor, value, height[(j - 1) * x + i]);
                    if (!r)
                        validate_add(low, high, factor, value, height[(j - 1) * (x + 1) + i]);
                }

                //mid row
                if (!l)
                    validate_add(low, high, factor, value, height[j * x + (i - 1)]);
                if (!r)
                    validate_add(low, high, factor, value, height[j * x + (i + 1)]);

                //bottom row
                if (!b) {
                    if (!l)
                        validate_add(low, high, factor, value, height[(j + 1) * x + (i - 1)]);
                    validate_add(low, high, factor, value, height[(j + 1) * x + i]);     
                    if (!r)
                        validate_add(low, high, factor, value, height[(j + 1) * x + (i + 1)]);
                }   

                height[j * x + i] = value / factor; 
            }
        }
    }
}


void height_map(float * vertices, unsigned int vsize, float * height, unsigned int x, unsigned int y, float defau) {

    size_t num_tri = vsize / 9;
    Triangle ** triangles = new Triangle*[num_tri];
    size_t filled = 0;

    for (size_t i = 0; i < vsize; i += 9)
    {
        triangles[filled++] = new Triangle(vec3(vertices[i], vertices[i + 1], vertices[i + 2]),
                                         vec3(vertices[i + 3], vertices[i + 4], vertices[i + 5]),
                                         vec3(vertices[i + 6], vertices[i + 7], vertices[i + 8]));
    }
    

    TDBVH bvh;
    BBox bounds = bvh.build(triangles, num_tri);
    float step = (bounds.high.x - bounds.low.x) / (float) x;
    //float stepy = (bounds.high.y - bounds.low.y) / (float) y;
    Ray ray;

    //always point down
    ray.dir = vec3(0, 0, -1);

    for (size_t j = 0; j < y; j++)
    {
        for (size_t i = 0; i < x; i++)
        {
            ray.origin = vec3(bounds.low.x + (i + 0.5f) * step, 
                              bounds.low.y + (j + 0.5f) * step, 
                              TOP_HEIGHT);

            bvh.traceRegualarRay(ray, false);

            if (fabs(ray.t - RTINFINITY) < RTEPSILON)
                height[j * x + i] =  defau;
            else
                height[j * x + i] = TOP_HEIGHT - ray.t;
        }
    }

    denoise(height, x, y, bounds.low.z, bounds.high.z);

    for (size_t i = 0; i < num_tri; ++i)
        delete triangles[i];
    delete [] triangles;
}