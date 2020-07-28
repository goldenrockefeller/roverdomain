cimport cython

from .state cimport State
from .rover_observations_calculator cimport BaseRoverObservationsCalculator
from .dynamics_processor cimport BaseDynamicsProcessor
from .evaluator cimport BaseEvaluator

from .rover_observations_calculator cimport DefaultRoverObservationsCalculator
from .dynamics_processor cimport DefaultDynamicsProcessor
from .evaluator cimport DefaultEvaluator
 
from .state cimport new_State
from .dynamics_processor cimport new_DefaultDynamicsProcessor
from .evaluator cimport new_DefaultEvaluator
from .rover_observations_calculator cimport new_DefaultRoverObservationsCalculator

from rockefeg.cyutil.array cimport DoubleArray
from rockefeg.cyutil.typed_list cimport TypedList, new_TypedList
from rockefeg.cyutil.typed_list cimport is_sub_full_type

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverDomain:
    def __init__(self):
        init_RoverDomain(self)
    
    cpdef object copy(self, object copy_obj = None):
        cdef RoverDomain new_domain
        cdef State state
        cdef BaseEvaluator evaluator
        cdef BaseDynamicsProcessor dynamics_processor
        cdef BaseRoverObservationsCalculator rover_observations_calculator
        cdef TypedList state_history
        cdef TypedList actions_history
        
        if copy_obj is None:
            new_domain = RoverDomain.__new__(RoverDomain)
        else:
            new_domain = copy_obj

        state = self.__current_state
        new_domain.__current_state = state.copy()
        
        state = self.__setting_state
        new_domain.__setting_state = state.copy()
        
        evaluator = self.__evaluator
        new_domain.__evaluator = evaluator.copy()
        
        dynamics_processor = self.__dynamics_processor
        new_domain.__dynamics_processor = (
            dynamics_processor.copy())
        
        rover_observations_calculator = self.__rover_observations_calculator
        new_domain.__rover_observations_calculator = (
            rover_observations_calculator.copy())
            
            
        state_history = self.__state_history
        new_domain.__state_history = state_history.shallow_copy()
        
        actions_history = self.__actions_history
        new_domain.__actions_history = actions_history.shallow_copy()
    
        new_domain.__n_steps_elapsed = self.__n_steps_elapsed
        new_domain.__max_n_steps = self.__max_n_steps
        new_domain.__setting_max_n_steps = self.__setting_max_n_steps
                    
        return new_domain

    cpdef bint episode_is_done(self) except *:
        return self.n_steps_elapsed() >= self.max_n_steps()

    cpdef rover_observations(self):
        cdef BaseRoverObservationsCalculator rover_observations_calculator
        
        rover_observations_calculator = self.rover_observations_calculator()
        
        return rover_observations_calculator.observations(self.current_state())
                
                
    cpdef double eval(self) except *:
        cdef BaseEvaluator evaluator
        
        evaluator = self.evaluator()
        return (
            evaluator.eval(
                self.state_history(), 
                self.actions_history(),
                self.episode_is_done()))
        
    
    cpdef rover_evals(self):
        cdef BaseEvaluator evaluator
        
        evaluator = self.evaluator()
        return (
            evaluator.rover_evals(
                self.state_history(), 
                self.actions_history(),
                self.episode_is_done()))
        
    
    cpdef void reset(self) except *:
        cdef State setting_state
        cdef TypedList state_history 
        cdef TypedList actions_history
        
        setting_state = self.setting_state()
        
        self.set_current_state(setting_state.copy())
        self._set_max_n_steps(self.setting_max_n_steps())
        self._set_n_steps_elapsed(0)
        
        
        state_history = self.state_history()
        state_history.set_items([])
            
        actions_history = self.actions_history()
        actions_history.set_items([])

        
    cpdef void step(self, rover_actions) except *:
        cdef State current_state
        cdef TypedList state_history 
        cdef TypedList actions_history
        cdef BaseDynamicsProcessor dynamics_processor
        
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        current_state = self.current_state()

        # Put current state in state history.
        state_history = self.state_history()
        state_history.append(current_state.copy())
        
        # Put current actions in actions history.
        actions_history = self.actions_history()
        actions_history.append(rover_actions)
                
        # Update state
        dynamics_processor = self.dynamics_processor()
        dynamics_processor.process_state(current_state, rover_actions)
        
        self._set_n_steps_elapsed(self.n_steps_elapsed() + 1)
        
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
        cdef TypedList setting_state_history = <TypedList?> state_history
        
        if not is_sub_full_type(setting_state_history.item_type(), State):
            raise (
                TypeError(
                    "The state history's item type "
                    "(state_history.item_type() = {state_history_item_type}) "
                    "must be State."
                    .format(**locals())))

        self.__state_history = setting_state_history
     
    cpdef actions_history(self):
        return self.__actions_history
    
    cpdef void _set_actions_history(self, actions_history) except *:
        self.__actions_history = <TypedList?>actions_history
  
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
        
    domain.__setting_state = new_State()
    setting_state = domain.__setting_state
    domain.__current_state = setting_state.copy()
    domain.__dynamics_processor = new_DefaultDynamicsProcessor()
    domain.__evaluator = new_DefaultEvaluator()
    domain.__rover_observations_calculator = (
        new_DefaultRoverObservationsCalculator())
    domain.__max_n_steps = 1
    domain.__setting_max_n_steps = domain.__max_n_steps
    domain.__n_steps_elapsed = 0

    domain.__state_history = new_TypedList(State)
    domain.__actions_history = new_TypedList(object)
 