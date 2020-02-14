cimport cython

@cython.auto_pickle(True)
cdef class BaseDynamicsProcessor:
    cpdef Py_ssize_t n_rover_action_dims(self) except *:
        raise NotImplementedError()
    
    cpdef State next_state(
            self,
            State state, 
            const double[:, :] rover_actions,
            State store = None):
        raise NotImplementedError()
        
    cpdef object copy(self, object store = None):
        raise NotImplementedError()