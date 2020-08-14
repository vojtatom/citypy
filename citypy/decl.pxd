# cython: language_level=3
# distutils: language=c++

cimport numpy as np
from .types cimport DTYPE, INTDTYPE

cdef extern from "trace/render.hpp":
    void height_map(DTYPE * vertices, unsigned int vsize, DTYPE * height, unsigned int x, unsigned int y, DTYPE defau)
