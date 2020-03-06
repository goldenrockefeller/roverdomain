cimport cython

@cython.auto_pickle(True)
cdef class BaseDynamicsProcessor:
    cpdef State next_state(
            self,
            State state, 
            DoubleArray2 rover_actions):
        raise NotImplementedError()
        
    cpdef object copy(self):
        raise NotImplementedError()
        
    cpdef object copy_to(self, object obj):
        raise NotImplementedError()