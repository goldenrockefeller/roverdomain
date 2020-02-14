cimport cython

@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef double[:, :] observations(
            self,  
            State state,
            double[:, :] store = None
            ) except *:
        raise NotImplementedError()
        
        
    cpdef object copy(self, object store = None):
        raise NotImplementedError()