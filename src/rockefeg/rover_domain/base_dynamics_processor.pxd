# cython: language_level=3


from .state cimport State

cdef class BaseDynamicsProcessor:
    cpdef Py_ssize_t n_rover_action_dims(self) except *
    
    cpdef State next_state_copy(
        self, 
        State state, 
        const double[:, :] rover_actions
        ) 
    cpdef State next_state_via(
        self, 
        State store, 
        State state, 
        const double[:, :] rover_actions
        ) 
    # double[n_rovers, n_rover_action_dims]
    
    cpdef object copy(self)
    
    cpdef object copy_via(self, object store)