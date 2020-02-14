# distutils: language = c++
# cython: language_level=3

from .default_evaluator cimport DefaultEvaluator
from .state cimport State

cdef class DifferenceEvaluator(DefaultEvaluator):
    
    cpdef double cfact_step_eval_from_poi(
        self, 
        State state,
        Py_ssize_t excluded_rover_id,
        Py_ssize_t poi_id
        )  except *
        

    cpdef double cfact_eval(
        self, 
        object[:] state_history, 
        const double[:, :, :] rover_actions_history,
        bint episode_is_done,
        Py_ssize_t excluded_rover_id
        ) except *
    # State[n_steps_elapsed]
    # double[n_steps_elapsed, n_rovers, n_rover_actions_history]

