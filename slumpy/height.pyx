# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
# distutils: language=c++

import numpy as np
from tqdm import tqdm

from .types cimport DTYPE, LONGDTYPE, INTDTYPE

cimport numpy as np
from libc.stdlib cimport malloc, free

DEF child_nodes = 8
DEF max_hmap_height = 9000

cdef struct quadtree:
    quadtree * ne
    quadtree * se
    quadtree * sw
    quadtree * nw
    
    int tris[child_nodes]
    int filled

    DTYPE x_min
    DTYPE x_max
    DTYPE y_min
    DTYPE y_max

    DTYPE x_center
    DTYPE y_center


cdef quadtree * create_quadtree(DTYPE x_min, DTYPE y_min, DTYPE x_max, DTYPE y_max):
    cdef quadtree * node = <quadtree *> malloc(sizeof(quadtree))
    node.ne = NULL
    node.se = NULL
    node.sw = NULL
    node.nw = NULL
    node.filled = 0
    node.x_min = x_min
    node.y_min = y_min
    node.x_max = x_max
    node.y_max = y_max
    node.x_center = (x_max + x_min) / 2
    node.y_center = (y_max + y_min) / 2

    return node

#recursive delete
cdef void delete_quadtree(quadtree * node):
    if node.ne != NULL:
        delete_quadtree(node.ne)
    if node.se != NULL:
        delete_quadtree(node.se)
    if node.sw != NULL:
        delete_quadtree(node.sw)
    if node.nw != NULL:
        delete_quadtree(node.nw)
    free(node)


cdef void triangle_center(DTYPE * center, DTYPE[:,::1] vert, int tri_idx):
    cdef int i = 0, vert_id = tri_idx * 3
    
    for i in range(2):
        center[i] = (vert[vert_id, i] + vert[vert_id + 1, i] + vert[vert_id + 2, i]) / 3.0


cdef void build_up(quadtree * node, DTYPE[:,::1] vert, int tri_idx):
    cdef DTYPE center[2]
    triangle_center(center, vert, tri_idx)

    if center[0] > node.x_center:
        if center[1] > node.y_center:
            if node.ne == NULL:
                node.ne = create_quadtree(node.x_center, node.y_center, node.x_max, node.y_max)
            add_triangle(node.ne, vert, tri_idx)
        else:
            if node.se == NULL:
                node.se = create_quadtree(node.x_center, node.y_min, node.x_max, node.y_center)
            add_triangle(node.se, vert, tri_idx)
    else:
        if center[1] > node.y_center:
            if node.nw == NULL:
                node.nw = create_quadtree(node.x_min, node.y_center, node.x_center, node.y_max)
            add_triangle(node.nw, vert, tri_idx)
        else:
            if node.sw == NULL:
                node.sw = create_quadtree(node.x_min, node.y_min, node.x_center, node.y_center)
            add_triangle(node.sw, vert, tri_idx)


cdef void add_triangle(quadtree * node, DTYPE[:,::1] vert, int tri_idx):
    if node.filled < child_nodes - 1:
        node.tris[node.filled] = tri_idx
        node.filled += 1
    else:
        build_up(node, vert, tri_idx)


#cdef DTYPE triangle_bbdim(DTYPE a, DTYPE b, DTYPE c):
#    cdef DTYPE x_min = min(min(a, b), min(a, c))
#    cdef DTYPE x_max = max(max(a, b), max(a, c))
#
#    return x_max - x_min

cdef DTYPE intersection_height(DTYPE x, DTYPE y, DTYPE[:,::1] vert, int tri_idx):
    cdef int a = tri_idx * 3
    cdef int b = a + 1 
    cdef int c = a + 1 

    cdef DTYPE x1 = vert[a, 0]
    cdef DTYPE x2 = vert[b, 0]
    cdef DTYPE x3 = vert[c, 0]
    cdef DTYPE y1 = vert[a, 1]
    cdef DTYPE y2 = vert[b, 1]
    cdef DTYPE y3 = vert[c, 1]

    cdef DTYPE denom = ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
    cdef DTYPE bar_a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denom
    cdef DTYPE bar_b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denom
    cdef DTYPE bar_c = 1 - bar_a - bar_b

    cdef height = -max_hmap_height

    #inside triangle
    if bar_a > 0 and bar_a < 1 and bar_b > 0 and bar_b < 1 and bar_c > 0 and bar_c < 1:
        height = vert[a, 2] * bar_a + vert[b, 2] * bar_b + vert[c, 2] * bar_c
        print("found cross", height)

    return height



cdef DTYPE intersection(quadtree * node, DTYPE x, DTYPE y, DTYPE[:,::1] vert, DTYPE default, int depth):    
    #check intersection
    if x < node.x_min or x > node.x_max:
        return -max_hmap_height
    if y < node.y_min or y > node.y_max:
        return -max_hmap_height

    print(" " * depth, "passed")

    #now surely intersects quad
    cdef int i
    cdef DTYPE height = -max_hmap_height

    for i in range(node.filled):
        height = max(height, intersection_height(x, y, vert, node.tris[i]))
    
    if node.ne != NULL:
        height = max(height, intersection(node.ne, x, y, vert, default, depth + 1))
    if node.se != NULL:
        height = max(height, intersection(node.se, x, y, vert, default, depth + 1))
    if node.sw != NULL:
        height = max(height, intersection(node.sw, x, y, vert, default, depth + 1))
    if node.nw != NULL:
        height = max(height, intersection(node.nw, x, y, vert, default, depth + 1))

    return height



cdef DTYPE[:,::1] cheight_map(DTYPE[:,::1] vert, DTYPE[::1] bmin, DTYPE[::1] bmax, INTDTYPE res):
    cdef int tri_count = vert.shape[0] // 3 
    cdef int i, j, x, y
    cdef DTYPE dc, xc, yc

    #build quadtree
    cdef quadtree * root = create_quadtree(bmin[0], bmin[1], bmax[0], bmax[1])

    for i in range(tri_count):
        add_triangle(root, vert, i)

    #create canvas
    cdef DTYPE x_size = bmax[0] - bmin[0]
    cdef DTYPE y_size = bmax[1] - bmin[1]
    
    if x_size < y_size:
        dc = y_size / res
        x = int(x_size / dc)
        y = res
    else:
        dc = x_size / res
        x = res
        y = int(y_size / dc)


    cdef DTYPE[:,::1] hmap = np.empty((x, y), dtype=np.float32)

    #trace pixels
    print("tracing height")
    #for i in tqdm(range(x)):
    for i in range(x):
        for j in range(y):
            xc = i * dc + bmin[0] + 0.5 * dc
            yc = j * dc + bmin[1] + 0.5 * dc
            hmap[i, j] = intersection(root, xc, yc, vert, bmax[2], 0)


    delete_quadtree(root)

    return hmap



def height_map(model, res):
    if 'vertices' not in model:
        raise Exception("No vertices in supplied data")

    if not isinstance(model['vertices'],  np.ndarray):
        raise Exception("Vertices in spplied data are not instance of numpy array")

    hmap = cheight_map(model['vertices'].reshape((model['vertices'].shape[0] // 3, 3)), 
                model['stats']['min'], model['stats']['max'], res)

    return np.asarray(hmap)


