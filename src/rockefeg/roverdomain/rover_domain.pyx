cimport cython
from .state import State
from .default_rover_observations_calculator \
    import DefaultRoverObservationsCalculator
from .default_dynamics_processor import DefaultDynamicsProcessor
from .default_evaluator import DefaultEvaluator
from rockefeg.ndarray.object_array_1 cimport ObjectArray1
from rockefeg.ndarray.double_array_1 cimport DoubleArray1
from rockefeg.ndarray.double_array_2 cimport DoubleArray2

from rockefeg.ndarray.object_array_1 import ObjectArray1

@cython.warn.undeclared(True)
cdef class RoverDomain:
    def __init__(self):
        self.m_setting_state = State()
        self.m_current_state = <State?> self.m_setting_state.copy()
        self.m_dynamics_processor = DefaultDynamicsProcessor()
        self.m_evaluator = DefaultEvaluator()
        self.m_rover_observations_calculator = (
            DefaultRoverObservationsCalculator())
        self.m_n_steps = 1
        self.m_setting_n_steps = self.m_n_steps
        self.m_n_steps_elapsed = 0

        
        self.m_state_history = ObjectArray1(None)
        self.m_rover_actions_history = ObjectArray1(None)
        
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef RoverDomain other
        cdef object other_type
        
        if index is not ...:
            raise TypeError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = RoverDomain()  
        elif type(obj) is type(self):
            other = <RoverDomain?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, or None"
                    .format(**locals())))
            
        other.copy_to(self)
            
    cpdef object copy_to(self, object obj):
        cdef RoverDomain other
        cdef State state
        cdef DoubleArray2 rover_actions
        cdef Py_ssize_t state_id
        cdef Py_ssize_t actions_id
        cdef object other_type
        
        if obj is None:        
            other = RoverDomain()
        elif type(obj) is type(self):
            other = <RoverDomain?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, None"
                    .format(**locals())))
                
        other.m_current_state[...] = self.m_current_state
                
        other.m_setting_state[...] = self.m_setting_state
        other.m_evaluator[...] = self.m_evaluator
        other.m_dynamics_processor[...] = self.m_dynamics_processor
        
        other.m_rover_observations_calculator[...] = (
            self.m_rover_observations_calculator)
        
        other.m_n_steps_elapsed = self.m_n_steps_elapsed
            
        other.m_n_steps = self.m_n_steps
        other.m_setting_n_steps = self.m_setting_n_steps
        other.m_n_rovers = self.m_n_rovers
        other.m_n_rover_observation_dims = self.m_n_rover_observation_dims
        
        other.m_state_history.repurpose_like(self.m_state_history) 
        for state_id in range(self.m_state_history.view.shape[0]):
            try:
                state = <State?> other.m_state_history.view[state_id]
                state[...] = self.m_state_history.view[state_id]
            except (TypeError, NotImplementedError):
                other.m_state_history.view[state_id] = (
                    <State?> self.m_state_history.view[state_id].copy())
        
        
        other.m_rover_actions_history.repurpose_like(
            self.m_rover_actions_history) 
            
        for actions_id in range(self.m_rover_actions_history.view.shape[0]):
            try:
                rover_actions = (
                    <DoubleArray2?> other.m_rover_actions_history.view[
                        actions_id])
                        
                rover_actions[...] = (
                    self.m_rover_actions_history.view[actions_id])
                    
            except (TypeError, NotImplementedError):
                other.m_rover_actions_history.view[actions_id] = (
                    <DoubleArray2?> (
                        self.m_rover_actions_history.view[actions_id].copy()))
                    
        return other
                
    cpdef State current_state(self):
        return self.m_current_state
        
    cpdef void set_current_state(self, State state) except *:
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None")) 
        try:
            self.m_current_state[...] = state
        except (TypeError, NotImplementedError):
            self.m_current_state = <State?> state.copy()
        
    cpdef State setting_state(self):
        return self.m_setting_state
        
    cpdef void set_setting_state(self, State state) except *:
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None")) 
        try:
            self.m_setting_state[...] = state
        except (TypeError, NotImplementedError):
            self.m_setting_state = <State?> state.copy()
        
    cpdef BaseEvaluator evaluator(self):
        return self.m_evaluator
        
    cpdef void set_evaluator(self, BaseEvaluator evaluator) except *:
        if evaluator is None:
            raise (
                TypeError(
                    "(evaluator) can not be None")) 
                    
        try:
            self.m_evaluator[...] = evaluator
        except (TypeError, NotImplementedError):
            self.m_evaluator = <BaseEvaluator?> evaluator.copy()
    
    cpdef BaseDynamicsProcessor dynamics_processor(self):
        return self.m_dynamics_processor
        
    cpdef void set_dynamics_processor(
            self, 
            BaseDynamicsProcessor dynamics_processor
            ) except *:
        if dynamics_processor is None:
            raise (
                TypeError(
                    "(dynamics_processor) can not be None")) 
        try:
            self.m_dynamics_processor[...] = dynamics_processor
        except (TypeError, NotImplementedError):
            self.m_dynamics_processor = (
                <BaseDynamicsProcessor?> dynamics_processor.copy())
        
        
        
    cpdef BaseRoverObservationsCalculator rover_observations_calculator(
            self):
        return self.m_rover_observations_calculator
        
    cpdef void set_rover_observations_calculator(
            self,
            BaseRoverObservationsCalculator rover_observations_calculator
            ) except *:
        if rover_observations_calculator is None:
            raise (
                TypeError(
                    "(rover_observations_calculator) can not be None")) 
              
        try:
            self.m_rover_observations_calculator[...] = (
                rover_observations_calculator)
        except (TypeError, NotImplementedError):
            self.m_rover_observations_calculator = (
                <BaseRoverObservationsCalculator?> (
                    rover_observations_calculator.copy()))
        
    cpdef Py_ssize_t n_steps_elapsed(self) except *:
        return self.m_n_steps_elapsed
        
    cpdef ObjectArray1 state_history(self):
        return self.state_history
    
    cpdef Py_ssize_t n_steps(self) except *:
        return self.m_n_steps
    
    cpdef Py_ssize_t setting_n_steps(self) except *:
        return self.m_setting_n_steps
        
    cpdef void set_setting_n_steps(self, Py_ssize_t n_steps) except *:
        if n_steps <= 0:
            raise ValueError(
                "The number of steps (n_steps = {n_steps}) must be positive. "
                .format(**locals()))
                
        self.m_setting_n_steps = n_steps
        
    cpdef bint episode_is_done(self) except *:
        return self.n_steps_elapsed() >= self.n_steps()

    cpdef ObjectArray1 rover_actions_history(self):
        return self.m_rover_actions_history

    cpdef DoubleArray2 rover_observations(self):
        return (
            self.rover_observations_calculator().observations(
                self.m_current_state))
                
                
    cpdef double eval(self) except *:
        return (
            self.evaluator().eval(
                self.m_state_history, 
                self.m_rover_actions_history,
                self.episode_is_done()))
        
    
    cpdef DoubleArray1 rover_evals(self):
        return (
            self.evaluator().rover_evals(
                self.m_state_history, 
                self.m_rover_actions_history,
                self.episode_is_done()))
        
    
    
    cpdef void reset(self) except *:
        try:
            self.m_current_state[...] = self.setting_state()
        except (TypeError, NotImplementedError):
            self.m_current_state = <State?> self.setting_state().copy()
        self.m_n_steps = self.m_setting_n_steps
        self.m_n_steps_elapsed = 0
        
        self.m_state_history.empty()
        self.m_rover_actions_history.empty()

        
    cpdef void step(self, DoubleArray2 rover_actions) except *:
        cdef BaseDynamicsProcessor dynamics_processor
        cdef State history_state
        cdef DoubleArray2 history_rover_actions
        cdef Py_ssize_t step_id
        
        dynamics_processor = self.dynamics_processor()
                    
        step_id = self.m_n_steps_elapsed
        
        
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        # Put current state in state history.
        self.m_state_history.extend(1)
        try:
            history_state = <State?> self.m_state_history.view[-1]
            history_state[...] = self.m_current_state
        except (TypeError, NotImplementedError):
            self.m_state_history.view[-1] = <State?> self.m_current_state.copy()
        
        
        # Put current rover actions in rover actions history.
        self.m_rover_actions_history.extend(1)
        try:
            history_rover_actions = (
                <DoubleArray2?> self.m_rover_actions_history.view[-1])
                
            history_rover_actions[...] = rover_actions
            
        except (TypeError, NotImplementedError):
            self.m_rover_actions_history.view[-1] = (
                <DoubleArray2?> rover_actions.copy())
        
                
        # Update state
        self.m_current_state[...] = (
            dynamics_processor.next_state(self.m_current_state, rover_actions)) 
        
        self.m_n_steps_elapsed += 1
        

        
   