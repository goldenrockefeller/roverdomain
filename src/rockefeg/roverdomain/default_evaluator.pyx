from libcpp.algorithm cimport partial_sort
from numpy.math cimport INFINITY

from rockefeg.ndarray.double_array_1 import DoubleArray1
from rockefeg.ndarray.double_array_2 import DoubleArray2
import numpy as np

cimport cython
@cython.warn.undeclared(True)
cdef class DefaultEvaluator(BaseEvaluator):
        
    def __init__(self):
        self.m_capture_dist = 1.
        self.m_n_req = 1

        self.r_sqr_rover_dists_to_poi.resize(1)
        
        self.r_sub_evals_given_poi = DoubleArray1(None)
        self.o_rover_evals = DoubleArray1(None)
        
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef DefaultEvaluator other
        cdef object other_type
        
        if index is not ...:
            raise TypeError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = DefaultEvaluator()  
        elif type(obj) is type(self):
            other = <DefaultEvaluator?> obj
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
        cdef DefaultEvaluator other
        cdef object other_type
        
        if obj is None:        
            other = DefaultEvaluator() 
        elif type(obj) is type(self):
            other = <DefaultEvaluator?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, None"
                    .format(**locals())))
        
        other.m_capture_dist = self.m_capture_dist
        other.m_n_req = self.m_n_req
        
        return other
        
    cpdef Py_ssize_t n_req(self) except *:
        return self.m_n_req
        
    cpdef void set_n_req(self, Py_ssize_t n_req) except *:
        if n_req <= 0:
            raise ValueError(
                "The number of rovers required to capture a POI "
                " (n_req = {n_req}) must be positive."
                .format(**locals()))  
                
        self.m_n_req = n_req
        
    cpdef double capture_dist(self) except *:
        return self.m_capture_dist
        
    cpdef void set_capture_dist(self, double capture_dist) except *:
        if capture_dist < 0.:
            raise ValueError(
                "The POIs' capture distance (capture_dist = {capture_dist}) "
                "must be non-negative."
                .format(**locals())) 
                
        self.m_capture_dist = capture_dist
    
    cpdef double step_eval_from_poi(
            self, 
            State state, 
            Py_ssize_t poi_id
            ) except *:
        cdef double displ_x, displ_y
        cdef double capture_dist
        cdef DoubleArray2 rover_positions
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t n_req
        cdef Py_ssize_t rover_id
        
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))   
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_req = self.n_req()
        capture_dist = self.capture_dist()
        
        self.r_sqr_rover_dists_to_poi.resize(n_rovers)
        
        # If there isn't enough rovers to satify the coupling constraint 
        # (n_req), then return 0.
        if n_req > n_rovers:
            return 0.  

        # Get the rover square distances to POI.
        for rover_id in range(n_rovers):
            displ_x = (
                state.rover_positions().view[rover_id, 0]
                - state.poi_positions().view[poi_id, 0]) 
            displ_y = (
                state.rover_positions().view[rover_id, 1]
                - state.poi_positions().view[poi_id, 1])  
            self.r_sqr_rover_dists_to_poi[rover_id] = (
                displ_x*displ_x + displ_y*displ_y)
            
        
        # Sort first (n_req) closest rovers for evaluation.
        # Sqr_dists_to_poi is no longer in rover order!
        partial_sort(
            self.r_sqr_rover_dists_to_poi.begin(), 
            self.r_sqr_rover_dists_to_poi.begin()
            + min(n_req, <Py_ssize_t>(self.r_sqr_rover_dists_to_poi.size())), 
            self.r_sqr_rover_dists_to_poi.end())

        # Is there (n_req) rovers capturing? Only need to check the (n_req)th
        # closest rover.
        if (
                self.r_sqr_rover_dists_to_poi[n_req-1] 
                >  capture_dist * capture_dist
        ):
            # Not close enough?, then there is no reward for this POI.
            return 0.
        
        # Close enough! Return evaluation.
        return state.poi_values().view[poi_id]  
        
    cpdef void check_state_history(self, ObjectArray1 state_history) except *:
        cdef State state
        cdef Py_ssize_t step_id
        cdef Py_ssize_t n_pois 
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_steps
        
        cdef Py_ssize_t state_n_rovers
        cdef Py_ssize_t state_n_pois
        
        if state_history is None:
            raise (
                TypeError(
                    "(state_history) can not be None"))
        
        state = <State?> state_history.view[0]
        n_pois = state.n_pois()
        n_rovers = state.n_rovers()
        n_steps = state_history.view.shape[0]
        
        for step_id in range(n_steps):
            state = <State?> state_history.view[step_id]
            state_n_rovers = state.n_rovers() 
            state_n_pois = state.n_pois()
            
            if state_n_pois != n_pois:
                raise ValueError(
                    "The number of POIs for all states in the state history "
                    " must match. State {step_id}'s number of POIs "
                    "(state_history.view[step_id].n_pois() = "
                    "{state_n_pois}) "
                    "does not equal state 0's number of POIs "
                    "(state_history.view[0].n_pois() = "
                    "{n_pois}) "
                    .format(**locals()))
                    
            if state_n_rovers!= n_rovers:
                raise ValueError(
                    "The number of rovers for all states in the state history "
                    " must match. State {step_id}'s number of rovers "
                    "(state_history.view[step_id].n_rovers() = "
                    "{state_n_rovers}) "
                    "does not equal state 0's number of rovers "
                    "(state_history.view[0].n_rovers() = "
                    "{n_rovers}) "
                    .format(**locals()))

    cpdef DoubleArray1 rover_evals(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done):
        cdef Py_ssize_t n_rovers  
        
        if state_history is None:
            raise (
                TypeError(
                    "(state_history) can not be None"))    
        self.check_state_history(state_history)
                    
        if rover_actions_history is None:
            raise (
                TypeError(
                    "(rover_actions_history) can not be None"))  
        
        n_rovers = rover_actions_history.view.shape[1]
        
        self.o_rover_evals.repurpose(n_rovers)
        
        self.o_rover_evals.set_all_to(
            self.eval(
                state_history,
                rover_actions_history,
                episode_is_done))
                
        return self.o_rover_evals
        
    cpdef double eval(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done
            ) except *:
        
        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef double eval
        cdef DoubleArray1 sub_evals_given_poi
        
        if state_history is None:
            raise (
                TypeError(
                    "(state_history) can not be None")) 
        self.check_state_history(state_history)
                    
        if rover_actions_history is None:
            raise (
                TypeError(
                    "(rover_actions_history) can not be None"))  
        
        state = <State?> state_history.view[0]
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_steps = state_history.view.shape[0]
        
                
        if n_pois < 0:
            raise ValueError(
                "The state's number of POIs (n_pois = {n_pois}) must be "
                "non-negative. "
                .format(**locals()))
            
        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.
        
        self.r_sub_evals_given_poi.repurpose(n_pois)
        self.r_sub_evals_given_poi.set_all_to(-INFINITY)

        # Initialize evaluations.
        eval = 0.
        
        # Get evaluation for poi, for each step, storing the max.
        for step_id in range(n_steps):
            state = <State?> state_history.view[step_id]
            # Keep best step evaluation for each poi.
            for poi_id in range(n_pois):
                self.r_sub_evals_given_poi.view[poi_id] = (
                    max(
                        self.r_sub_evals_given_poi.view[poi_id],
                        self.step_eval_from_poi(state,poi_id)))
        
        # Set evaluation to the sum of all POI-specific evaluations.
        for poi_id in range(n_pois):
            eval += self.r_sub_evals_given_poi.view[poi_id]
        
        return eval     
        

        
        

       
    
        

    