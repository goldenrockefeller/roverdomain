cimport cython

@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef DoubleArray2 observations(self, State state, object store):
        raise NotImplementedError()
        
        
    cpdef object copy(self, object store):
        raise NotImplementedError()