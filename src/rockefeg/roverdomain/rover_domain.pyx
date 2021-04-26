cimport cython
import cython

from .rover_observations_calculator cimport DefaultRoverObservationsCalculator
from .dynamics_processor cimport DefaultDynamicsProcessor
from .evaluator cimport DefaultEvaluator
 
from .state cimport new_State
from .dynamics_processor cimport new_DefaultDynamicsProcessor
from .evaluator cimport new_DefaultEvaluator
from .rover_observations_calculator cimport new_DefaultRoverObservationsCalculator

from typing import Sequence

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverDomain:
    def __init__(self):
        init_RoverDomain(self)
    
    @cython.locals(state_history=list, actions_history=list)
    cpdef RoverDomain copy(self, copy_obj = None):

        cdef RoverDomain new_domain
        state_history: List[State]
        actions_history: List[Sequence[DoubleArray]]
        
        if copy_obj is None:
            new_domain = RoverDomain.__new__(RoverDomain)
        else:
            new_domain = copy_obj
        
         
        new_domain._current_state = self._current_state.copy()
        new_domain._setting_state = self._setting_state.copy()
        new_domain._evaluator = self._evaluator.copy()
        
        new_domain._dynamics_processor = (
            self._dynamics_processor.copy())
        
        new_domain._rover_observations_calculator = (
            self._rover_observations_calculator.copy())
            
            
        new_domain._state_history = self._state_history.copy()
        new_domain._actions_history = self._actions_history.copy()
    
        new_domain._n_steps_elapsed = self._n_steps_elapsed
        new_domain._max_n_steps = self._max_n_steps
        new_domain._setting_max_n_steps = self._setting_max_n_steps
                    
        return new_domain

    cpdef bint episode_is_done(self) except *:
        return self.n_steps_elapsed() >= self.max_n_steps()

    cpdef list rover_observations(self):
    # type: (...) -> List[DoubleArray]
        return (
            self.rover_observations_calculator().observations(
                self.current_state() ))
                
    cpdef double eval(self) except *:
        return (
            self.evaluator().eval(
                self.state_history(), 
                self.actions_history(),
                self.episode_is_done()))
        
    
    cpdef DoubleArray rover_evals(self):
        return (
            self.evaluator().rover_evals(
                self.state_history(), 
                self.actions_history(),
                self.episode_is_done()))
        
    
    cpdef void reset(self) except *:
        cdef State setting_state
        
        setting_state = self.setting_state()
        
        self.set_current_state(setting_state.copy())
        self._set_max_n_steps(self.setting_max_n_steps())
        self._set_n_steps_elapsed(0)
        
        self._set_state_history([])
        self._set_actions_history([])

    @cython.locals(rover_actions = list)
    cpdef void step(self, rover_actions: Sequence[DoubleArray]) except *:
        cdef State current_state
        
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        current_state = self.current_state()

        # Put current state in state history.
        self._state_history().append(current_state.copy())
        
        # Put current actions in actions history.
        self._actions_history().append(rover_actions)
                
        # Update state
        self.dynamics_processor().process_state(current_state, rover_actions)
        
        self._set_n_steps_elapsed(self.n_steps_elapsed() + 1)
        
    cpdef State current_state(self):
        return self._current_state
        
    cpdef void set_current_state(self, State state) except *:
        self._current_state = state
    
    cpdef State setting_state(self):
        return self._setting_state
    
    cpdef void set_setting_state(self, State state) except *:
        self._setting_state = state
        
    cpdef BaseEvaluator evaluator(self):
        return self._evaluator
    
    cpdef void set_evaluator(self, BaseEvaluator evaluator) except *:
        self._evaluator = evaluator
    
    cpdef BaseDynamicsProcessor dynamics_processor(self):
        return self._dynamics_processor
    
    cpdef void set_dynamics_processor(
            self, 
            BaseDynamicsProcessor dynamics_processor
            ) except *:
        self._dynamics_processor = dynamics_processor
        
    cpdef BaseRoverObservationsCalculator rover_observations_calculator(self):
        return self._rover_observations_calculator
    
    cpdef void set_rover_observations_calculator(
            self,
            BaseRoverObservationsCalculator rover_observations_calculator
            ) except *:
        self._rover_observations_calculator = rover_observations_calculator
    
    cpdef Py_ssize_t setting_max_n_steps(self):
        return self._setting_max_n_steps
        
    cpdef void set_setting_max_n_steps(self, Py_ssize_t max_n_steps) except *:
        if max_n_steps <= 0:
            raise (
                ValueError(
                    "The settting maximum number of steps (max_n_steps = "
                    "{max_n_steps}) must be positive. "
                    .format(**locals())))
                
        self._setting_max_n_steps = max_n_steps
    
    cpdef Py_ssize_t n_steps_elapsed(self):
        return self._n_steps_elapsed
    
    cpdef void _set_n_steps_elapsed(self, Py_ssize_t n_steps_elapsed) except *:
        if n_steps_elapsed < 0:
            raise (
                ValueError(
                    "The number of steps elapsed "
                    "(n_steps_elapsed = {n_steps_elapsed}) "
                    "must be non-negative. "
                    .format(**locals())))
                    
        self._n_steps_elapsed = n_steps_elapsed
        
    cpdef Py_ssize_t max_n_steps(self):
        return self._max_n_steps
    
    cpdef void _set_max_n_steps(self, Py_ssize_t max_n_steps) except *:
        if max_n_steps < 0:
            raise (
                ValueError(
                    "The maximum number of steps "
                    "(max_n_steps = {max_n_steps}) must be positive. "
                    .format(**locals())))
                    
        self._max_n_steps = max_n_steps
    
    cpdef list state_history(self):
        # type: (...) -> Sequence[State]
        return self._state_history
    
    @cython.locals(setting_state_history = list)
    cpdef void _set_state_history(
            self, 
            setting_state_history: Sequence[State]
            ) except *:
        self._state_history = setting_state_history
     
    cpdef list actions_history(self):
        #type: (...) -> Sequence[Sequence[DoubleArray]]
        return self._actions_history

    
    @cython.locals(actions_history = list)
    cpdef void _set_actions_history(
            self, 
            actions_history: Sequence[Sequence[DoubleArray]]) except *:
        self._actions_history = actions_history
  
  
@cython.warn.undeclared(True)        
cdef RoverDomain new_RoverDomain():
    cdef RoverDomain new_domain
    
    new_domain = RoverDomain.__new__(RoverDomain)
    init_RoverDomain(new_domain)
    
    return new_domain

@cython.warn.undeclared(True)
cdef void init_RoverDomain(RoverDomain domain) except *:
    cdef State setting_state
    
    if domain is None:
        raise TypeError("The domain (domain) cannot be None.")
        
    domain._setting_state = new_State()
    setting_state = domain._setting_state
    domain._current_state = setting_state.copy()
    domain._dynamics_processor = new_DefaultDynamicsProcessor()
    domain._evaluator = new_DefaultEvaluator()
    domain._rover_observations_calculator = (
        new_DefaultRoverObservationsCalculator())
    domain._max_n_steps = 1
    domain._setting_max_n_steps = domain._max_n_steps
    domain._n_steps_elapsed = 0

    domain._state_history = []
    domain._actions_history = []
    

 