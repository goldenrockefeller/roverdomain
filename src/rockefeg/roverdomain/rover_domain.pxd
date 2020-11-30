# cython: language_level=3

from .state cimport State

from .rover_observations_calculator cimport BaseRoverObservationsCalculator
from .dynamics_processor cimport BaseDynamicsProcessor
from .evaluator cimport BaseEvaluator

from rockefeg.cyutil.typed_list cimport TypedList, BaseReadableTypedList
from rockefeg.cyutil.array cimport DoubleArray

cdef class RoverDomain:
    cdef State __current_state
    cdef State __setting_state
    cdef BaseEvaluator __evaluator
    cdef BaseDynamicsProcessor __dynamics_processor
    cdef BaseRoverObservationsCalculator __rover_observations_calculator
    cdef Py_ssize_t __n_steps_elapsed
    cdef Py_ssize_t __max_n_steps
    cdef Py_ssize_t __setting_max_n_steps
    cdef TypedList __state_history
    # list<State>[max_n_steps]
    cdef TypedList __actions_history
    # list<list<DoubleArray>>[max_n_steps, n_rovers, n_action_dims]
        
    cpdef RoverDomain copy(self, copy_obj = ?)
    
    cpdef bint episode_is_done(self) except *
     
    cpdef TypedList rover_observations(self)
    # list<DoubleArray>[n_observation_dims, n_rovers]
    
    cpdef double eval(self) except *
    
    cpdef DoubleArray rover_evals(self)
    # DoubleArray[n_rovers]
    
    cpdef void reset(self) except *
        
    cpdef void step(self, BaseReadableTypedList rover_actions) except *
    # list<DoubleArray>[n_rovers, n_observation_dims]
    
    cpdef State current_state(self)
    cpdef void set_current_state(self, State state) except *
    
    cpdef State setting_state(self)    
    cpdef void set_setting_state(self, State state) except *
        
    cpdef BaseEvaluator evaluator(self)        
    cpdef void set_evaluator(self, BaseEvaluator evaluator) except *
    
    cpdef BaseDynamicsProcessor dynamics_processor(self)    
    cpdef void set_dynamics_processor(
        self, 
        BaseDynamicsProcessor dynamics_processor
        ) except *
    
    cpdef BaseRoverObservationsCalculator rover_observations_calculator(self)    
    cpdef void set_rover_observations_calculator(
        self,
        BaseRoverObservationsCalculator rover_observations_calculator
        ) except *
    
    cpdef Py_ssize_t setting_max_n_steps(self)
    cpdef void set_setting_max_n_steps(self, Py_ssize_t max_n_steps) except *
    
    cpdef Py_ssize_t n_steps_elapsed(self)
    
    cpdef void _set_n_steps_elapsed(self, Py_ssize_t n_steps_elapsed) except *
    # Protected
    
    cpdef Py_ssize_t max_n_steps(self)
    
    cpdef void _set_max_n_steps(self, Py_ssize_t max_n_steps) except *
    # Protected
    
    cpdef BaseReadableTypedList state_history(self)
    
    cpdef void _set_state_history(self, TypedList state_history) except *
    # Protected
    # 
    cpdef BaseReadableTypedList actions_history(self)
    
    cpdef void _set_actions_history(self, TypedList actions_history) except *
    # Protected

cdef RoverDomain new_RoverDomain()
cdef void init_RoverDomain(RoverDomain domain) except *

    
    
    
    
    