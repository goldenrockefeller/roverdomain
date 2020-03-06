cimport cython

@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef DoubleArray2 observations(self, State state):
        raise NotImplementedError()
        
    cpdef object copy(self):
        raise NotImplementedError()
        
    cpdef object copy_to(self, object obj):
        raise NotImplementedError()