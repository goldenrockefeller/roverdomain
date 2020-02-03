cimport cython

@cython.auto_pickle(True)
cdef class BaseDynamicsProcessor:
    cpdef Py_ssize_t n_rover_action_dims(self) except *:
        raise NotImplementedError()
    
    cpdef State next_state_copy(
            self, 
            State state, 
            const double[:, :] rover_actions):
        raise NotImplementedError()
        
    cpdef State next_state_via(
            self, 
            State store, 
            State state, 
            const double[:, :] rover_actions):
        raise NotImplementedError()
        
    cpdef object copy(self):
        raise NotImplementedError()
    
    cpdef object copy_via(self, object store):
        raise NotImplementedError()