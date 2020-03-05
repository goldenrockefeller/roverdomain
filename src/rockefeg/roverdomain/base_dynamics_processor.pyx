cimport cython

@cython.auto_pickle(True)
cdef class BaseDynamicsProcessor:
    cpdef State next_state(
            self,
            State state, 
            DoubleArray2 rover_actions,
            object store):
        raise NotImplementedError()
        
    cpdef object copy(self, object store):
        raise NotImplementedError()