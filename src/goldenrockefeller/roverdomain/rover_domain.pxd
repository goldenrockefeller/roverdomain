# cython: language_level=3

import cython

from .state cimport State

from .rover_observations_calculator cimport BaseRoverObservationsCalculator
from .dynamics_processor cimport BaseDynamicsProcessor
from .evaluator cimport BaseEvaluator

from goldenrockefeller.cyutil.array cimport DoubleArray

cdef class RoverDomain:
    cdef State _current_state
    cdef State _setting_state
    cdef BaseEvaluator _evaluator
    cdef BaseDynamicsProcessor _dynamics_processor
    cdef BaseRoverObservationsCalculator _rover_observations_calculator
    cdef Py_ssize_t _n_steps_elapsed
    cdef Py_ssize_t _max_n_steps
    cdef Py_ssize_t _setting_max_n_steps
    cdef list _state_history
    # list<State>[max_n_steps]
    cdef list _actions_history
    # list<list<DoubleArray>>[max_n_steps, n_rovers, n_action_dims]
        
    cpdef RoverDomain copy(self, copy_obj = ?)
    
    cpdef bint episode_is_done(self) except *
     
    cpdef list rover_observations(self)
    # type: (...) -> List[DoubleArray]
    
    cpdef double eval(self) except *
    
    cpdef DoubleArray rover_evals(self)
    # DoubleArray[n_rovers]
    
    cpdef void reset(self) except *
        
    @cython.locals(rover_actions = list)
    cpdef void step(self, rover_actions: Seqeunce[DoubleArray]) except *
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
    
    cpdef list state_history(self)
    # type: (...) -> Seqeunce[State]

    
    @cython.locals(setting_state_history = list)
    cpdef void _set_state_history(self, setting_state_history: List[State]) except *

    cpdef list actions_history(self)
    # type: (...) -> Seqeunce[Seqeunce[DoubleArray]]
    
    @cython.locals(actions_history = list)
    cpdef void _set_actions_history(
        self, 
        actions_history: List[Seqeunce[DoubleArray]]
        ) except *

cdef RoverDomain new_RoverDomain()
cdef void init_RoverDomain(RoverDomain domain) except *

    
    
    
    
    