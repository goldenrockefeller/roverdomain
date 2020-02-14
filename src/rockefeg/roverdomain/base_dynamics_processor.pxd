# cython: language_level=3


from .state cimport State

cdef class BaseDynamicsProcessor:
    cpdef Py_ssize_t n_rover_action_dims(self) except *
    

    cpdef State next_state(
        self, 
        State state, 
        const double[:, :] rover_actions,
        State store = ?
        ) 
    # double[n_rovers, n_rover_action_dims]
    
    cpdef object copy(self, object store = ?)