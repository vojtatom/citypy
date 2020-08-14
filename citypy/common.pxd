# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
# distutils: language=c++

cimport numpy as np
from .types cimport DTYPE, INTDTYPE

cdef np.ndarray[INTDTYPE, ndim=1] create_1d_int32_numpy(void * ptr, INTDTYPE d1)

cdef np.ndarray[DTYPE, ndim=1] create_1d_float_numpy(void * ptr, INTDTYPE d1)

cdef np.ndarray[DTYPE, ndim=2] create_2d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2)

cdef np.ndarray[DTYPE, ndim=3] create_3d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2, INTDTYPE d3)

cdef np.ndarray[DTYPE, ndim=4] create_4d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2, INTDTYPE d3, INTDTYPE d4)
