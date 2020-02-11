cimport cython

@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef double[:, :] observations_copy(self, State state) except *:
        raise NotImplementedError()
    
    cpdef double[:, :] observations_via(
            self, 
            double[:, :] store, 
            State state
            ) except *:
        raise NotImplementedError()
        
    cpdef object copy(self):
        raise NotImplementedError()
        
    cpdef object copy_via(self, object store):
        raise NotImplementedError()