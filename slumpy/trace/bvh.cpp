#include "bvh.hpp"

using namespace std;


BBox TDBVH::build(Triangle ** triangles, size_t count)
{
    boxes = new BBox[count];
    BBox rootBox;

    for (size_t i = 0; i < count; i++)
    {
        boxes[i].include(triangles[i]);
        rootBox.include(boxes[i]);
    }


    tri = triangles;
    root = (BVHInternalNode * ) buildRecursive(rootBox, 0, count, 0, 0);

    delete [] boxes;
    return rootBox;
}

BVHNode * TDBVH::buildRecursive(BBox & parent_box, size_t from, size_t to, unsigned char axis, size_t depth){

    //leaf
    if (from == to - 1)
    {
        BVHNode * leaf = new BVHNode();
        leaf->axes = 3;
        leaf->tri = tri[from];
        return leaf;
    }

    //only two primitives left
    if (from == to - 2)
    {
        BVHInternalNode * node = new BVHInternalNode();
        node->axes = axis;
        node->box = parent_box;

        if (boxes[from].midpoint(axis) < boxes[from + 1].midpoint(axis))
        {
            node->childL = buildRecursive(boxes[from], from, from + 1, axis, depth + 1);
            node->childR = buildRecursive(boxes[from + 1], from + 1, to, axis, depth + 1);
        } else {
            node->childL = buildRecursive(boxes[from + 1], from + 1, to, axis, depth + 1);
            node->childR = buildRecursive(boxes[from], from, from + 1, axis, depth + 1);
        }

        return node;
    }

    //internal
    BVHInternalNode * node = new BVHInternalNode();
    node->axes = axis;
    node->box = parent_box;

    //sort my part of array
    float midpoint = parent_box.midpoint(axis);
    float boxcenter;

    size_t lastInLeft = from - 1;
    BBox left, right;

    for (size_t i = from; i < to; i++)
    {
        boxcenter = boxes[i].midpoint(axis);
        if (boxcenter < midpoint) 
        {
            left.include(tri[i]);
            lastInLeft++;
            swap(boxes[i], boxes[lastInLeft]); 
            swap(tri[i], tri[lastInLeft]); 
        } else {
            right.include(tri[i]);
        }
    }

    //test for empty sides
    if (from - 1 == lastInLeft || to - 1 == lastInLeft)
    {
        left.reset();
        right.reset();

        float mid, min_mid = RTINFINITY;
        for (size_t i = from; i < to; i++)
        {
            mid = boxes[i].midpoint(axis);
            if (mid < min_mid)
            {
                swap(boxes[i], boxes[from]); 
                swap(tri[i], tri[from]); 
                min_mid = mid;
            }
        }

        left.include(boxes[from]);
        lastInLeft = from;
        for (size_t i = from + 1; i < to; i++)
        {
            right.include(boxes[i]);
        }
    }

    axis = (axis + 1) % 3;

    //build left subtree
    node->childL = buildRecursive(left, from, lastInLeft + 1, axis, depth + 1);
    //build right subtree
    node->childR = buildRecursive(right, lastInLeft + 1, to, axis, depth + 1);

    return node;
}


struct BVHStack {
    float tmin;
    float tmax;
    BVHNode * node;
};


void TDBVH::traceRegualarRay(Ray & ray, bool culling)
{
    //iteration vs recursion

    BVHStack stack[10000];
    size_t stack_index = 1;
    float tmin, tmax;


    ray.hit = nullptr; //nic jsem neprotnul
    ray.t = RTINFINITY;

    if (root == nullptr || !root->box.intersects(ray, tmin, tmax))
        return;


    BVHNode * node = root;

    //init stack
    stack[0].node = root;
    stack[0].tmax = RTINFINITY;
    stack[0].tmin = 0;

    float best_t = RTINFINITY;
    Triangle * tri = nullptr; // bug - nebylo inicializovano
    float t, lb1, lb2, b1, b2;
    while (stack_index > 0)
    {
        while (node)
        { 
            if (node->axes == 3) // is leaf
            {
                //intersection of ray and triangle in leaf
                t = node->tri->intersect(ray, culling, lb1, lb2);
                

                if (t >= RTTRACEEPSILON && t < best_t)
                {
                    best_t = t;
                    tri = node->tri;
                    b1 = lb1;
                    b2 = lb2;
                }

                break;
            } else { // is internal
                if (((BVHInternalNode * ) node)->box.intersects(ray, tmin, tmax))
                {
                    BVHNode * near, *far;
                    if (ray.dir[node->axes] > 0)
                    {
                        near = ((BVHInternalNode * ) node)->childL;
                        far = ((BVHInternalNode * ) node)->childR;
                    } else {
                        near = ((BVHInternalNode * ) node)->childR;
                        far = ((BVHInternalNode * ) node)->childL;
                    }

                    stack[stack_index].node = far;
                    stack[stack_index].tmin = tmin;
                    stack[stack_index].tmax = tmax; // tu byl bug
                    stack_index++;

                    node = near;
                } else 
                    break;
            }

        }

        //pop from stack
        stack_index--;
        tmin = stack[stack_index].tmin;
        tmax = stack[stack_index].tmax;
        node = stack[stack_index].node;
        
        //pop from stack far -> node
        if (tri != nullptr)
        {
            if (tmin > best_t)
            {
                while (stack_index > 0) //pop from stack
                {
                    stack_index--;
                    tmin = stack[stack_index].tmin;

                    if (tmin < best_t)
                        break; //there is a chance that the ray intersects the triangle
                }

                tmax = stack[stack_index].tmax;
                node = stack[stack_index].node;
            }
        }
    }
    

    if (tri)
    {
        ray.hit = tri;
        ray.t = best_t;
        ray.barX = b1;
        ray.barY = b2;
    }
}

