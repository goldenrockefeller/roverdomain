cimport cython
from .rover_observations_calculator cimport DefaultRoverObservationsCalculator
from .dynamics_processor cimport DefaultDynamicsProcessor
from .evaluator cimport DefaultEvaluator
 
from .state cimport new_State
from .dynamics_processor cimport new_DefaultDynamicsProcessor
from .evaluator cimport new_DefaultEvaluator
from .rover_observations_calculator cimport new_DefaultRoverObservationsCalculator
from .history cimport new_StateHistory, new_ActionsHistory

cdef RoverDomain new_RoverDomain():
    cdef RoverDomain new_domain
    
    new_domain = RoverDomain.__new__(RoverDomain)
    init_RoverDomain(new_domain)
    
    return new_domain


cdef void init_RoverDomain(RoverDomain domain) except *:
    if domain is None:
        raise TypeError("The domain (domain) cannot be None.")
        
    domain.__setting_state = new_State()
    domain.__current_state = domain.__setting_state.copy()
    domain.__dynamics_processor = new_DefaultDynamicsProcessor()
    domain.__evaluator = new_DefaultEvaluator()
    domain.__rover_observations_calculator = (
        new_DefaultRoverObservationsCalculator())
    domain.__n_steps = 1
    domain.__setting_n_steps = domain.__n_steps
    domain.__n_steps_elapsed = 0

    domain.__state_history = new_StateHistory()
    domain.__actions_history = new_ActionsHistory()
    

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverDomain:
    def __init__(self):
        init_RoverDomain(self)
    
    cpdef object copy(self, object copy_obj = None):
        cdef RoverDomain new_domain
        
        if copy_obj is None:
            new_domain = RoverDomain.__new__(RoverDomain)
        else:
            new_domain = copy_obj

        new_domain.__current_state = self.__current_state.copy()
        new_domain.__setting_state = self.__setting_state.copy()
        new_domain.__evaluator = self.__evaluator.copy()
        new_domain.__dynamics_processor = self.__dynamics_processor.copy()
    
        new_domain.__rover_observations_calculator = (
            self.__rover_observations_calculator.copy())
            
        new_domain.__state_history = self.__state_history.copy()
        new_domain.__actions_history = self.__actions_history.copy()
    
        new_domain.__n_steps_elapsed = self.__n_steps_elapsed
        new_domain.__n_steps = self.__n_steps
        new_domain.__setting_n_steps = self.__setting_n_steps
                    
        return new_domain

    cpdef bint episode_is_done(self) except *:
        return self.__n_steps_elapsed >= self.__n_steps

    cpdef list rover_observations(self):
        return (
            self.__rover_observations_calculator.observations(
                self.__current_state))
                
                
    cpdef double eval(self) except *:
        return (
            self.__evaluator.eval(
                self.__state_history, 
                self.__actions_history,
                self.episode_is_done()))
        
    
    cpdef DoubleArray rover_evals(self):
        return (
            self.__evaluator.rover_evals(
                self.__state_history, 
                self.__actions_history,
                self.episode_is_done()))
        
    
    
    cpdef void reset(self) except *:
        self.set_current_state(self.__setting_state.copy())
        self._set_n_steps(self.__setting_n_steps)
        self._set_n_steps_elapsed(0)
        
        self.__state_history.clear()
            
        self.__actions_history.clear()

        
    cpdef void step(self, list rover_actions) except *:
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        # Put current state in state history.
        self.__state_history.record(self.__current_state)
        
        # Put current actions in actions history.
        self.__actions_history.record(rover_actions)
                
        # Update state
        self.__dynamics_processor.process_state(
            self.__current_state, 
            rover_actions)
        
        self._set_n_steps_elapsed(self.__n_steps_elapsed + 1)
        
    cpdef State current_state(self):
        return self.__current_state
        
    cpdef void set_current_state(self, State state) except *:
        if state is None:
            raise TypeError("The current state (state) must not be None.")
            
        self.__current_state = state
    
    cpdef State setting_state(self):
        return self.__setting_state
    
    cpdef void set_setting_state(self, State state) except *:
        if state is None:
            raise TypeError("The setting state (state) must not be None.")
        self.__setting_state = state
        
    cpdef BaseEvaluator evaluator(self):
        return self.__evaluator
    
    cpdef void set_evaluator(self, BaseEvaluator evaluator) except *:
        if evaluator is None:
            raise TypeError("The evaluator (evaluator) must not be None.")
        self.__evaluator = evaluator
    
    cpdef BaseDynamicsProcessor dynamics_processor(self):
        return self.__dynamics_processor
    
    cpdef void set_dynamics_processor(
            self, 
            BaseDynamicsProcessor dynamics_processor 
            ) except *:
        if dynamics_processor is None:
            raise (
                TypeError(
                    "The dynamics processor (dynamics_processor) must "
                    "not be None."))
        self.__dynamics_processor = dynamics_processor
        
    cpdef BaseRoverObservationsCalculator rover_observations_calculator(self):
        return self.__rover_observations_calculator
    
    cpdef void set_rover_observations_calculator(
            self,
            BaseRoverObservationsCalculator rover_observations_calculator
            ) except *:
        if rover_observations_calculator is None:
            raise (
                TypeError(
                    "The rover observations calculator "
                    "(rover_observations_calculator) must not be None."))
        self.__rover_observations_calculator = rover_observations_calculator
    
    cpdef Py_ssize_t setting_n_steps(self):
        return self.__setting_n_steps
        
    cpdef void set_setting_n_steps(self, Py_ssize_t n_steps) except *:
        if n_steps <= 0:
            raise (
                ValueError(
                    "The number of settting steps (n_steps = {n_steps}) "
                    "must be positive. "
                    .format(**locals())))
                
        self.__setting_n_steps = n_steps
    
    cpdef Py_ssize_t n_steps_elapsed(self):
        return self.__n_steps_elapsed
    
    cpdef void _set_n_steps_elapsed(self, Py_ssize_t n_steps_elapsed) except *:
        if n_steps_elapsed < 0:
            raise (
                ValueError(
                    "The number of steps elapsed "
                    "(n_steps_elapsed = {n_steps_elapsed}) "
                    "must be non-negative. "
                    .format(**locals())))
                    
        self.__n_steps_elapsed = n_steps_elapsed
        
    cpdef Py_ssize_t n_steps(self):
        return self.__n_steps
    
    cpdef void _set_n_steps(self, Py_ssize_t n_steps) except *:
        if n_steps < 0:
            raise (
                ValueError(
                    "The number of steps "
                    "(n_steps = {n_steps}) must be positive. "
                    .format(**locals())))
                    
        self.__n_steps = n_steps
    
    cpdef StateHistory state_history(self):
        return self.__state_history
    
    cpdef void _set_state_history(self, StateHistory state_history) except *:
        if state_history is None:
            raise (
                TypeError( 
                    "The state history (state_history) must not be None."))
        self.__state_history = state_history
    
    cpdef ActionsHistory actions_history(self):
        return self.__actions_history
    
    cpdef void _set_actions_history(
            self,
            ActionsHistory actions_history
            ) except *:
        if actions_history is None:
            raise (
                TypeError(
                    "The actions history (actions_history) must "
                    "not be None."))
        self.__actions_history = actions_history

        
#    