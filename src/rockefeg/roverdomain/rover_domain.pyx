cimport cython

from .state cimport State
from .rover_observations_calculator cimport BaseRoverObservationsCalculator
from .dynamics_processor cimport BaseDynamicsProcessor
from .evaluator cimport BaseEvaluator
from .history cimport StateHistory, ActionsHistory

from .rover_observations_calculator cimport DefaultRoverObservationsCalculator
from .dynamics_processor cimport DefaultDynamicsProcessor
from .evaluator cimport DefaultEvaluator
 
from .state cimport new_State
from .dynamics_processor cimport new_DefaultDynamicsProcessor
from .evaluator cimport new_DefaultEvaluator
from .rover_observations_calculator cimport new_DefaultRoverObservationsCalculator
from .history cimport new_StateHistory, new_ActionsHistory

from rockefeg.cyutil.array cimport DoubleArray


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

        new_domain.__current_state = (<State?>self.__current_state).copy()
        new_domain.__setting_state = (<State?>self.__setting_state).copy()
        new_domain.__evaluator = (<BaseEvaluator?>self.__evaluator).copy()
        new_domain.__dynamics_processor = (
            (<BaseDynamicsProcessor?>self.__dynamics_processor).copy())
    
        new_domain.__rover_observations_calculator = (
            (<BaseRoverObservationsCalculator?>
            self.__rover_observations_calculator)
            .copy())
            
        new_domain.__state_history = (
            <StateHistory?>self.__state_history).copy()
        new_domain.__actions_history = (
            <ActionsHistory?>self.__actions_history).copy()
    
        new_domain.__n_steps_elapsed = self.__n_steps_elapsed
        new_domain.__max_n_steps = self.__max_n_steps
        new_domain.__setting_max_n_steps = self.__setting_max_n_steps
                    
        return new_domain

    cpdef bint episode_is_done(self) except *:
        return self.__n_steps_elapsed >= self.__max_n_steps

    cpdef list rover_observations(self):
        return (
            (<BaseRoverObservationsCalculator?>
            self.__rover_observations_calculator)
            .observations(
                self.__current_state))
                
                
    cpdef double eval(self) except *:
        return (
            (<BaseEvaluator?>self.__evaluator).eval(
                self.__state_history, 
                self.__actions_history,
                self.episode_is_done()))
        
    
    cpdef rover_evals(self):
        return (
            (<BaseEvaluator?>self.__evaluator).rover_evals(
                self.__state_history, 
                self.__actions_history,
                self.episode_is_done()))
        
    
    
    cpdef void reset(self) except *:
        self.set_current_state((<State?>self.__setting_state).copy())
        self._set_max_n_steps(self.__setting_max_n_steps)
        self._set_n_steps_elapsed(0)
        
        (<StateHistory?>self.__state_history).clear()
            
        (<ActionsHistory?>self.__actions_history).clear()

        
    cpdef void step(self, list rover_actions) except *:
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        # Put current state in state history.
        (<StateHistory?>self.__state_history).record(self.__current_state)
        
        # Put current actions in actions history.
        (<ActionsHistory?>self.__actions_history).record(rover_actions)
                
        # Update state
        (<BaseDynamicsProcessor?>self.__dynamics_processor).process_state(
            self.__current_state, 
            rover_actions)
        
        self._set_n_steps_elapsed(self.__n_steps_elapsed + 1)
        
    cpdef current_state(self):
        return self.__current_state
        
    cpdef void set_current_state(self, state) except *:
        self.__current_state = <State?>state
    
    cpdef setting_state(self):
        return self.__setting_state
    
    cpdef void set_setting_state(self, state) except *:
        self.__setting_state = <State?>state
        
    cpdef evaluator(self):
        return self.__evaluator
    
    cpdef void set_evaluator(self, evaluator) except *:
        self.__evaluator = <BaseEvaluator?>evaluator
    
    cpdef dynamics_processor(self):
        return self.__dynamics_processor
    
    cpdef void set_dynamics_processor(self, dynamics_processor) except *:
        self.__dynamics_processor = <BaseDynamicsProcessor?>dynamics_processor
        
    cpdef rover_observations_calculator(self):
        return self.__rover_observations_calculator
    
    cpdef void set_rover_observations_calculator(
            self,
            rover_observations_calculator
            ) except *:
        self.__rover_observations_calculator = (
            <BaseRoverObservationsCalculator?>rover_observations_calculator)
    
    cpdef Py_ssize_t setting_max_n_steps(self):
        return self.__setting_max_n_steps
        
    cpdef void set_setting_max_n_steps(self, Py_ssize_t max_n_steps) except *:
        if max_n_steps <= 0:
            raise (
                ValueError(
                    "The settting maximum number of steps (max_n_steps = "
                    "{max_n_steps}) must be positive. "
                    .format(**locals())))
                
        self.__setting_max_n_steps = max_n_steps
    
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
        
    cpdef Py_ssize_t max_n_steps(self):
        return self.__max_n_steps
    
    cpdef void _set_max_n_steps(self, Py_ssize_t max_n_steps) except *:
        if max_n_steps < 0:
            raise (
                ValueError(
                    "The maximum number of steps "
                    "(max_n_steps = {max_n_steps}) must be positive. "
                    .format(**locals())))
                    
        self.__max_n_steps = max_n_steps
    
    cpdef state_history(self):
        return self.__state_history
    
    cpdef void _set_state_history(self, state_history) except *:
        self.__state_history = <StateHistory?>state_history
    
    cpdef actions_history(self):
        return self.__actions_history
    
    cpdef void _set_actions_history(self, actions_history) except *:
        self.__actions_history = <ActionsHistory?>actions_history

@cython.warn.undeclared(True)        
cdef RoverDomain new_RoverDomain():
    cdef RoverDomain new_domain
    
    new_domain = RoverDomain.__new__(RoverDomain)
    init_RoverDomain(new_domain)
    
    return new_domain

@cython.warn.undeclared(True)
cdef void init_RoverDomain(RoverDomain domain) except *:
    if domain is None:
        raise TypeError("The domain (domain) cannot be None.")
        
    domain.__setting_state = new_State()
    domain.__current_state = domain.__setting_state.copy()
    domain.__dynamics_processor = new_DefaultDynamicsProcessor()
    domain.__evaluator = new_DefaultEvaluator()
    domain.__rover_observations_calculator = (
        new_DefaultRoverObservationsCalculator())
    domain.__max_n_steps = 1
    domain.__setting_max_n_steps = domain.__max_n_steps
    domain.__n_steps_elapsed = 0

    domain.__state_history = new_StateHistory()
    domain.__actions_history = new_ActionsHistory()
 