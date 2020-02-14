# cython: language_level=3


from .state cimport State

cdef class BaseEvaluator:
    cpdef double eval(
        self,
        object[:] state_history,
        const double[:, :, :] rover_actions_history, 
        bint episode_is_done
        ) except *
    # double[n_rovers]
    # State[n_steps_elapsed]
    # double[n_steps_elapsed, n_rovers, n_rover_actions_history]
    
    cpdef double[:] rover_evals(
        self,
        object[:] state_history,
        const double[:, :, :] rover_actions_history, 
        bint episode_is_done,
        double[:] store = ?
        ) except *
    # double[n_rovers]
    # State[n_steps_elapsed]
    # double[n_steps_elapsed, n_rovers, n_rover_actions_history]
    
    cpdef object copy(self, object store = ?)
    