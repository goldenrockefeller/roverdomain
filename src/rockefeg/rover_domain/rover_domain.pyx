
import csv
import os
import errno
import numpy as np
import inspect

from .state import State
from .default_rover_observations_calculator \
    import DefaultRoverObservationsCalculator
from .default_dynamics_processor import DefaultDynamicsProcessor
from .default_evaluator import DefaultEvaluator

cimport cython

@cython.warn.undeclared(True)
cdef class RoverDomain:
    @cython.warn.undeclared(False)
    def __init__(self):
        self.m_setting_state_ref = State()
        self.m_current_state = <State?> self.m_setting_state_ref.copy()
        self.m_dynamics_processor_ref = DefaultDynamicsProcessor()
        self.m_evaluator_ref = DefaultEvaluator()
        self.m_rover_observations_calculator_ref = (
            DefaultRoverObservationsCalculator())
        self.m_n_steps = 1
        self.m_setting_n_steps = self.m_n_steps
        self.m_n_steps_elapsed = 0
        
        n_rover_action_dims = (
            self.m_dynamics_processor_ref.n_rover_action_dims())
        self.m_n_rover_action_dims =  n_rover_action_dims
        
        self.m_state_history_store = (
            np.array([
                <State?> self.m_current_state.copy() 
                for step_id 
                in range(self.m_n_steps)]))
           
        self.m_rover_actions_history_store = (
            np.zeros(
                (
                self.m_n_steps, 
                self.m_current_state.n_rovers(), 
                self.m_n_rover_action_dims)))
                
    @cython.warn.undeclared(False)     
    def __setstate__(self, state):
        
        for attr in state.keys():
            try:
                self.__setattr__(attr, state[attr])
            except AttributeError:
                pass

    @cython.warn.undeclared(False) 
    def __reduce__(self):
        cdef double[:] basic_memoryview = np.zeros(1)
        
        state = {}
        for attr in dir(self):
            try:
                val = self.__getattribute__(attr)
                if (
                        not (attr[:2] == "__" and attr[-2:] == "__")
                        and not inspect.isbuiltin(val)
                ):
                    if type(val) is type(basic_memoryview):
                        val = np.asarray(val)
                    state[attr] = val
            except AttributeError:
                pass

        return self.__class__, (),  state
        
    @cython.warn.undeclared(False)        
    cpdef object copy(self):
        cdef RoverDomain new_domain
        
        new_domain = RoverDomain()
        new_domain.m_current_state = <State?> self.m_current_state.copy()
        
        
        new_domain.m_state_history_store = (
            np.array([
                <State?> self.m_current_state.copy() 
                for step_id 
                in range(self.m_n_steps)]))
                
        
        self.m_rover_actions_history_store = (
            np.zeros(
                (
                self.m_n_steps, 
                self.n_rovers(), 
                self.m_n_rover_action_dims)))
        
        return self.copy_via(new_domain)
        
    cpdef object copy_via(self, object store):
        cdef Py_ssize_t step_id
        cdef State state_in_history_store
        cdef RoverDomain new_domain
        cdef object store_type
        cdef object self_type
        
        if type(store) is not type(self):
            store_type = type(store)
            self_type = type(self)
            raise TypeError(
                "The type of the storage parameter "
                "(type(store) = {store_type}) must be exactly {self_type}."
                .format(**locals()))
                
        new_domain = <RoverDomain?> store
                
        new_domain.m_setting_state_ref = self.m_setting_state_ref
        new_domain.m_current_state = (
            <State?> self.m_current_state.copy_via(new_domain.m_current_state))
        new_domain.m_dynamics_processor_ref = self.m_dynamics_processor_ref
        new_domain.m_evaluator_ref = self.m_evaluator_ref
        new_domain.m_rover_observations_calculator_ref = (
            self.m_rover_observations_calculator_ref )
        new_domain.m_n_steps = self.m_n_steps 
        new_domain.m_setting_n_steps = self.m_setting_n_steps
        new_domain.m_n_steps_elapsed = self.m_n_steps_elapsed 
        
        new_domain.m_n_rover_action_dims =  self.m_n_rover_action_dims
        

        for step_id in range(self.m_n_steps):
            # Assign (and implicit convert) indexed object to a cdef State 
            # before calling its functions to allow optimization.
            state_in_history_store = (
                <State?> self.m_state_history_store[step_id])
            new_domain.m_state_history_store[step_id] = (
                <State?> state_in_history_store.copy_via(
                    new_domain.m_state_history_store[step_id]))
         
        new_domain.m_rover_actions_history_store[...] = (
            self.m_rover_actions_history_store)
        
        return store
    
        
    cpdef State current_state_copy(self):
        return <State?> self.m_current_state.copy()
        
    cpdef State current_state_via(self, State store):
        return <State?> self.m_current_state.copy_via(store)
        
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
        cdef Py_ssize_t n_rover_action_dims

        n_rover_action_dims = dynamics_processor.n_rover_action_dims()
            
        if n_rover_action_dims <= 0:
            raise ValueError(
                "The dynamics processor's number of rover action dimensions "
                "(dynamics_processor_ref.n_rover_action_dims() "
                "= {n_rover_action_dims}) must be positive. "
                .format(**locals()))
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
        
    cpdef Py_ssize_t n_rover_action_dims(self) except *:
        return self.m_n_rover_action_dims
        
    @cython.warn.undeclared(False)
    cpdef object[:] state_history_copy(self) except *:
        cdef object[:] state_history
        
        state_history = (
            np.array([
                <State?> self.m_state_history_store[step_id].copy() 
                for step_id 
                in range(self.n_steps_elapsed())]))
        
        return state_history
        
        
    cpdef object[:] state_history_via(self, object[:] store) except *:
        cdef Py_ssize_t step_id
        cdef Py_ssize_t n_steps_elapsed
        cdef object[:] state_history
        cdef State state_in_history
        
        n_steps_elapsed = self.n_steps_elapsed()
        
        state_history = store[:n_steps_elapsed]
        for step_id in range(n_steps_elapsed):
            # Assign (and implicit convert) indexed object to a cdef State 
            # before calling its functions to allow optimization.
            state_in_history = <State?> self.m_state_history_store[step_id]
            state_history[step_id] = (
                <State?> self.m_state_in_history_store.copy_via(
                    state_history[step_id]))
        
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
        
    cpdef Py_ssize_t n_rovers(self) except *:
        return self.m_current_state.n_rovers()
        
    cpdef Py_ssize_t n_pois(self) except *:
        return self.m_current_state.n_pois()
        
    cpdef double[:, :] rover_positions_copy(self) except *:
        return self.m_current_state.rover_positions_copy()
        
    cpdef double[:, :] rover_positions_via(self, double[:, :] store) except *:
        return self.m_current_state.rover_positions_via(store)
        
    cpdef void set_rover_positions(
            self, 
            const double[:, :] rover_positions
            ) except *:
        self.m_current_state.set_rover_positions(rover_positions)
        
    cpdef double[:, :] rover_orientations_copy(self) except *:
        return self.m_current_state.rover_orientations_copy()
        
    cpdef double[:, :] rover_orientations_via(
            self, 
            double[:, :] store
            ) except *:
        return self.m_current_state.rover_orientations_via(store)
        
    cpdef void set_rover_orientations(
            self, 
            const double[:, :] rover_orientations
            ) except *:
        self.m_current_state.set_rover_orientations(rover_orientations)
        
    cpdef double[:] poi_values_copy(self) except *:
        return self.m_current_state.poi_values_copy()
        
    cpdef double[:] poi_values_via(self, double[:] store) except *:
        return self.m_current_state.poi_values_via(store)
        
    cpdef void set_poi_values(self, const double[:] poi_values) except *:
        self.m_current_state.set_poi_values(poi_values)
        
    cpdef double[:, :] poi_positions_copy(self) except *:
        return self.m_current_state.poi_positions_copy()
        
    cpdef double[:, :] poi_positions_via(self, double[:, :] store) except *:
        return self.m_current_state.poi_positions_via(store)
        
    cpdef void set_poi_positions(
            self, 
            const double[:, :] poi_positions
            ) except *:
        self.m_current_state.set_poi_positions(poi_positions)
        
    cpdef bint done(self) except *:
        return self.n_steps_elapsed() >= self.n_steps()
        
    cpdef double[:, :, :] rover_actions_history_copy(self) except *:
        cdef double[:, :, :] rover_actions_history
        
        rover_actions_history = (
            np.zeros(
                (
                self.n_steps_elapsed(), 
                self.n_rovers(), 
                self.n_rover_action_dims()
                )))
                
        return self.rover_actions_history_via(rover_actions_history)
        
        
    cpdef double[:, :, :] rover_actions_history_via(
            self, 
            double[:, :, :] store
            ) except *:
        cdef double[:, :, :] rover_actions_history
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_steps_elapsed
        cdef Py_ssize_t n_rover_actions_dims
        
        n_rovers = self.n_rovers()
        n_steps_elapsed = self.n_steps_elapsed()
        n_rover_actions_dims = self.n_rover_action_dims()
        
        rover_actions_history = (
            store[:n_steps_elapsed,:n_rovers, :n_rover_actions_dims])
                
        rover_actions_history[...] = (
            self.m_rover_actions_history_store[
                :n_steps_elapsed,
                :n_rovers,
                :n_rover_actions_dims])
                
        return rover_actions_history
        
     
    cpdef double[:, :] rover_observations_copy(self) except *:
        return (
            self.rover_observations_calculator_ref().observations_copy(
                self.m_current_state))
        
    cpdef double[:, :] rover_observations_via(
            self,
            double[:, :] store
            ) except *:
        return (
            self.rover_observations_calculator_ref().observations_via(
                store, 
                self.m_current_state))
                
                
    cpdef double eval(self) except *:
        cdef object[:] state_history
        cdef double[:, :, :] rover_actions_history
        
        state_history = self.m_state_history_store[:self.n_steps_elapsed()]
        rover_actions_history = (
            self.m_rover_actions_history_store[:self.n_steps_elapsed(), :, :])
        
        return (
            self.evaluator_ref().eval(
                state_history, 
                rover_actions_history,
                self.done()))
        
    
    cpdef double[:] rover_evals_copy(self) except *:
        cdef object[:] state_history
        cdef double[:, :, :] rover_actions_history
        
        state_history = self.m_state_history_store[:self.n_steps_elapsed()]
        rover_actions_history = (
            self.m_rover_actions_history_store[:self.n_steps_elapsed(), :, :])
        
        return (
            self.evaluator_ref().rover_evals_copy(
                state_history, 
                rover_actions_history,
                self.done()))
        
    cpdef double[:] rover_evals_via(self, double[:] rover_evals) except *:
        cdef object[:] state_history
        cdef double[:, :, :] rover_actions_history
        
        state_history = self.m_state_history_store[:self.n_steps_elapsed()]
        rover_actions_history = (
            self.m_rover_actions_history_store[:self.n_steps_elapsed(), :, :])
        
        return (
            self.evaluator_ref().rover_evals_via(
                rover_evals,
                state_history, 
                rover_actions_history,
                self.done()))
    
    
    cpdef void reset(self) except *:
        cdef State setting_state
        cdef list state_history_store_list
        cdef Py_ssize_t step_id
        cdef Py_ssize_t old_n_rover_action_dims, new_n_rover_action_dims
        cdef Py_ssize_t old_n_steps, new_n_steps
        cdef Py_ssize_t old_n_rovers, new_n_rovers
        
        setting_state = self.setting_state_ref()
        self.m_n_steps_elapsed = 0
        
        old_n_rover_action_dims = self.n_rover_action_dims()
        new_n_rover_action_dims = (
            self.dynamics_processor_ref().n_rover_action_dims())
            
        old_n_steps = self.n_steps()
        new_n_steps = self.setting_n_steps()
        
        old_n_rovers = self.m_current_state.n_rovers()
        new_n_rovers = setting_state.n_rovers()
            
        if (
                old_n_rover_action_dims == new_n_rover_action_dims
                and old_n_steps == new_n_steps
                and old_n_rovers == new_n_rovers
        ):
            # Reset, but avoid allocation.
            self.m_current_state = (
                <State?> setting_state.copy_via(self.m_current_state))
        else:
            self.m_current_state = <State?> setting_state.copy()
            self.m_n_steps = new_n_steps
            self.m_n_rover_action_dims = new_n_rover_action_dims
            
            state_history_store_list = [None] * new_n_steps
            for step_id in range(new_n_steps):
                state_history_store_list[step_id] = (
                    <State?> self.m_current_state.copy())
            self.m_state_history_store = np.array(state_history_store_list)
            
            self.m_rover_actions_history_store = (
                np.zeros(
                    (
                    new_n_steps, 
                    new_n_rovers, 
                    new_n_rover_action_dims)))
            
        
        
    cpdef void step(self, const double[:, :] rover_actions) except *:
        cdef BaseDynamicsProcessor dynamics_processor
        cdef Py_ssize_t step_id
        
        dynamics_processor = self.dynamics_processor_ref()
        step_id = self.m_n_steps_elapsed
        
        if self.done():
            raise ValueError(
                "The rover domain is done, so it cannot step. Try "
                "resetting the domain.")
        
        if (
                self.n_rover_action_dims() 
                != dynamics_processor.n_rover_action_dims()
        ):
            raise ValueError(
                "The domain's number of rover action dimensions "
                "(n_rover_action_dims = {self.n_rover_action_dims()}) "
                "must be equal to"
                "the dynamics processor's number of rover action dimensions "
                "(dynamics_processor_ref.n_rover_action_dims() "
                "= {dynamics_processor.n_rover_action_dims()}). "
                "Cannot step. Try resetting the domain."
                .format(**locals()))
        
        self.m_state_history_store[step_id] = (
            <State?> self.m_current_state.copy_via(
                self.m_state_history_store[step_id]))
                
        self.m_rover_actions_history_store[step_id, :, :] = rover_actions
                
        self.m_current_state = (
            dynamics_processor.next_state_via(
                self.m_current_state, 
                self.m_current_state,
                rover_actions))
        
        self.m_n_steps_elapsed += 1
        

        
   