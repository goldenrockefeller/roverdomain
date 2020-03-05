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
        self.m_setting_state_ref = State()
        self.m_current_state = self.m_setting_state_ref.copy(...)
        self.m_dynamics_processor_ref = DefaultDynamicsProcessor()
        self.m_evaluator_ref = DefaultEvaluator()
        self.m_rover_observations_calculator_ref = (
            DefaultRoverObservationsCalculator())
        self.m_n_steps = 1
        self.m_setting_n_steps = self.m_n_steps
        self.m_n_steps_elapsed = 0

        
        self.m_state_history = ObjectArray1(None)
        self.m_rover_actions_history = ObjectArray1(None)
                
    cpdef object copy(self, object store):
        cdef RoverDomain new_domain
        cdef Py_ssize_t state_id
        cdef Py_ssize_t actions_id
        cdef State state
        cdef DoubleArray2 rover_actions
        cdef object store_type
        
        if store is None or store is ...:
            new_domain = RoverDomain() 
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))        
        else:
            new_domain = <RoverDomain?> store
            
        new_domain.m_current_state = (
            self.m_current_state.copy(
                new_domain.m_current_state)) # store
                
        new_domain.m_setting_state_ref = self.m_setting_state_ref
        new_domain.m_evaluator_ref = self.m_evaluator_ref
        new_domain.m_dynamics_processor_ref = self.m_dynamics_processor_ref
        
        new_domain.m_rover_observations_calculator_ref = (
            self.m_rover_observations_calculator_ref)
        
        new_domain.m_n_steps_elapsed = self.m_n_steps_elapsed
            
        new_domain.m_n_steps = self.m_n_steps
        new_domain.m_setting_n_steps = self.m_setting_n_steps
        new_domain.m_n_rovers = self.m_n_rovers
        new_domain.m_n_rover_observation_dims = self.m_n_rover_observation_dims
        
        new_domain.m_state_history.repurpose(self.m_state_history.view.shape[0]) 
        for state_id in range(self.m_state_history.view.shape[0]):
            state = <State?> self.m_state_history.view[state_id]
            new_domain.m_state_history.view[state_id] = (
                state.copy(new_domain.m_state_history.view[state_id])) # store
        
        new_domain.m_rover_actions_history.repurpose(
            self.m_rover_actions_history.view.shape[0]) 
            
        for actions_id in range(self.m_rover_actions_history.view.shape[0]):
            rover_actions = (
                <DoubleArray2?> self.m_rover_actions_history.view[actions_id])
            new_domain.m_rover_actions_history.view[actions_id] = (
                rover_actions.copy(
                    new_domain.m_rover_actions_history.view[actions_id])) # store
        
        return new_domain

    cpdef State current_state(self, object store):
        return self.m_current_state.copy(store) # store
        
    cpdef void set_current_state(self, State state) except *:
        self.m_current_state = state.copy(self.m_current_state) # store
        
    cpdef State setting_state_ref(self):
        return self.m_setting_state_ref
        
    cpdef void set_setting_state_ref(self, State state) except *:
        self.m_setting_state_ref = state
        
    cpdef BaseEvaluator evaluator_ref(self):
        return self.m_evaluator_ref
        
    cpdef void set_evaluator_ref(self, BaseEvaluator evaluator) except *:
        self.m_evaluator_ref = evaluator
    
    cpdef BaseDynamicsProcessor dynamics_processor_ref(self):
        return self.m_dynamics_processor_ref
        
    cpdef void set_dynamics_processor_ref(
            self, 
            BaseDynamicsProcessor dynamics_processor
            ) except *:
        self.m_dynamics_processor_ref = dynamics_processor
        
    cpdef BaseRoverObservationsCalculator rover_observations_calculator_ref(
            self):
        return self.m_rover_observations_calculator_ref
        
    cpdef void set_rover_observations_calculator_ref(
            self,
            BaseRoverObservationsCalculator rover_observations_calculator
            ) except *:
        self.m_rover_observations_calculator_ref = (
            rover_observations_calculator)
        
    cpdef Py_ssize_t n_steps_elapsed(self) except *:
        return self.m_n_steps_elapsed
        
    cpdef ObjectArray1 state_history(self, object store):
        cdef ObjectArray1 state_history
        cdef Py_ssize_t state_id
        cdef State state
        
        if store is None or store is ...:
            state_history = ObjectArray1(None)
        else:
            state_history = <ObjectArray1?> store
        
        state_history.repurpose(self.m_state_history.view.shape[0]) 
        for state_id in range(self.m_state_history.view.shape[0]):
            state = <State?> self.m_state_history.view[state_id]
            state_history.view[state_id] = (
                state.copy(state_history.view[state_id])) # store
                        
        return state_history
    
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

    cpdef ObjectArray1 rover_actions_history(self, object store):
        cdef ObjectArray1 rover_actions_history
        cdef Py_ssize_t actions_id
        cdef DoubleArray2 rover_actions
        
        if store is None or store is ...:
            rover_actions_history = ObjectArray1(None)
        else:
            rover_actions_history = <ObjectArray1?> store
        
        rover_actions_history.repurpose(
            self.m_rover_actions_history.view.shape[0]) 
            
        for actions_id in range(self.m_rover_actions_history.view.shape[0]):
            rover_actions = (
                <DoubleArray2?> self.m_rover_actions_history.view[actions_id])
            rover_actions_history.view[actions_id] = (
                rover_actions.copy(
                    rover_actions_history.view[actions_id])) # store
                
        return rover_actions_history

    cpdef DoubleArray2 rover_observations(self, object store):
        if self.rover_observations_calculator_ref() is None:
            raise (
                TypeError(
                    "(self.rover_observations_calculator_ref()) "
                    "can not be None"))
        return (
            self.rover_observations_calculator_ref().observations(
                self.m_current_state, 
                store))
                
                
    cpdef double eval(self) except *:
        if self.evaluator_ref() is None:
            raise (
                TypeError(
                    "(self.evaluator_ref()) can not be None"))
        
        return (
            self.evaluator_ref().eval(
                self.m_state_history, 
                self.m_rover_actions_history,
                self.episode_is_done()))
        
    
    cpdef DoubleArray1 rover_evals(self, object store):
        if self.evaluator_ref() is None:
            raise (
                TypeError(
                    "(self.evaluator_ref()) can not be None"))
            
        return (
            self.evaluator_ref().rover_evals(
                self.m_state_history, 
                self.m_rover_actions_history,
                self.episode_is_done(),
                store = store))
        
    
    
    cpdef void reset(self) except *:
        if self.setting_state_ref() is None:
            raise (
                TypeError(
                    "(self.setting_state_ref()) can not be None"))
        
        self.m_current_state = self.setting_state_ref().copy(...)
        self.m_n_steps = self.m_setting_n_steps
        self.m_n_steps_elapsed = 0
        
        self.m_state_history.clear()
        self.m_rover_actions_history.clear()

        
    cpdef void step(self, DoubleArray2 rover_actions) except *:
        cdef BaseDynamicsProcessor dynamics_processor
        cdef Py_ssize_t step_id
        
        if self.dynamics_processor_ref() is None:
            raise (
                TypeError(
                    "(self.dynamics_processor_ref()) can not be None"))
        
        dynamics_processor = self.dynamics_processor_ref()
                    
        step_id = self.m_n_steps_elapsed
        
        
        if self.episode_is_done():
            raise ValueError(
                "The rover domain's episode is done, so it cannot step. Try "
                "resetting the domain.")

        # Put current state in state history.
        self.m_state_history.extend(1)
        self.m_state_history.view[-1] = (
            self.m_current_state.copy(
                self.m_state_history.view[-1])) # store
        
        # Put current rover actions in rover actions history.
        self.m_rover_actions_history.extend(1)
        self.m_rover_actions_history.view[-1] = (
            rover_actions.copy(
                self.m_rover_actions_history.view[-1]))
                
        # Update state
        self.m_current_state = (
            dynamics_processor.next_state(
                self.m_current_state,
                rover_actions,
                self.m_current_state)) # store
        
        self.m_n_steps_elapsed += 1
        

        
   