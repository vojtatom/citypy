# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
# distutils: language=c++

cimport numpy as np
from .types cimport DTYPE, LONGDTYPE, INTDTYPE

from libc.math cimport sqrt

np.import_array()


cdef extern from "numpy/arrayobject.h":
        void PyArray_ENABLEFLAGS(np.ndarray arr, int flags)


cdef np.ndarray[INTDTYPE, ndim=1] create_1d_int32_numpy(void * ptr, INTDTYPE d1):
    """
    Creates 1D np.ndarray by encapsulating INTDTYPE * pointer.
        
        :param void *        ptr:  INTDTYPE pointer pointing to beginning
        :param np.npy_intp * size: pointer to 1D array containg info:   
            size[0] - number of points 
    """
    cdef np.npy_intp size[1]
    size[0] = d1

    cdef np.ndarray[INTDTYPE, ndim=1] arr = np.PyArray_SimpleNewFromData(1, size, np.NPY_INT32, ptr)
    PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
    return arr


cdef np.ndarray[DTYPE, ndim=1] create_1d_float_numpy(void * ptr, INTDTYPE d1):
    cdef np.npy_intp size[1]
    size[0] = d1

    cdef np.ndarray[DTYPE, ndim=1] arr = np.PyArray_SimpleNewFromData(1, size, np.NPY_FLOAT32, ptr)
    PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
    return arr


cdef np.ndarray[DTYPE, ndim=2] create_2d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2):
    cdef np.npy_intp size[2]
    size[0] = d1
    size[1] = d2

    cdef np.ndarray[DTYPE, ndim=2] arr = np.PyArray_SimpleNewFromData(2, size, np.NPY_FLOAT32, ptr)
    PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
    return arr

cdef np.ndarray[DTYPE, ndim=3] create_3d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2, INTDTYPE d3):
    cdef np.npy_intp size[4]
    size[0] = d1
    size[1] = d2
    size[2] = d3

    cdef np.ndarray[DTYPE, ndim=3] arr = np.PyArray_SimpleNewFromData(3, size, np.NPY_FLOAT32, ptr)
    PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
    return arr

cdef np.ndarray[DTYPE, ndim=4] create_4d_float_numpy(void * ptr, INTDTYPE d1, INTDTYPE d2, INTDTYPE d3, INTDTYPE d4):
    cdef np.npy_intp size[4]
    size[0] = d1
    size[1] = d2
    size[2] = d3
    size[3] = d4

    cdef np.ndarray[DTYPE, ndim=4] arr = np.PyArray_SimpleNewFromData(4, size, np.NPY_FLOAT32, ptr)
    PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
    return arr

