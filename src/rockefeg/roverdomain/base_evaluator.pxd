# cython: language_level=3


from .state cimport State

from rockefeg.ndarray.double_array_1 cimport DoubleArray1
from rockefeg.ndarray.object_array_1 cimport ObjectArray1

cdef class BaseEvaluator:
    cpdef double eval(
        self,
        ObjectArray1 state_history,
        ObjectArray1 rover_actions_history, 
        bint episode_is_done
        ) except *
    # double[n_rovers]
    # State[n_steps_elapsed]
    # double[n_steps_elapsed, n_rovers, n_rover_actions_history]
    
    cpdef DoubleArray1 rover_evals(
        self,
        ObjectArray1 state_history,
        ObjectArray1 rover_actions_history, 
        bint episode_is_done)
    # double[n_rovers]
    # State[n_steps_elapsed]
    # double[n_steps_elapsed, n_rovers, n_rover_actions_history]
    
    cpdef object copy(self)
    
    cpdef object copy_to(self, object obj)
    