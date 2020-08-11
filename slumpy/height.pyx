# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
# distutils: language=c++

import numpy as np

from .decl cimport height_map
from .types cimport DTYPE, LONGDTYPE, INTDTYPE
cimport numpy as np



cdef DTYPE[::1] cheight_map(DTYPE[::1] vert, DTYPE[::1] bmin, DTYPE[::1] bmax, INTDTYPE res):
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


    cdef np.ndarray[DTYPE, ndim=1] hmap = np.empty((x * y,), dtype=np.float32)
    print(vert.shape[0])
    height_map(&vert[0], vert.shape[0], &hmap[0], x, y, bmax[2])
    return hmap



def render_height_map(model, res):
    if 'vertices' not in model:
        raise Exception("No vertices in supplied data")

    if not isinstance(model['vertices'],  np.ndarray):
        raise Exception("Vertices in spplied data are not instance of numpy array")

    hmap = cheight_map(model['vertices'], model['stats']['min'], model['stats']['max'], res)

    return np.asarray(hmap)


