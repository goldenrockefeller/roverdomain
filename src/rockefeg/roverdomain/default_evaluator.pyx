from libcpp.algorithm cimport partial_sort
from numpy.math cimport INFINITY
from rockefeg.ndarray.object_array_1 cimport ObjectArray1

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
        self.r_rover_positions = DoubleArray2(None)
        
    cpdef object copy(self, object store):
        cdef DefaultEvaluator new_evaluator
        cdef object store_type
        
        if store is None or store is ...:
            new_evaluator = DefaultEvaluator() 
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))
        else:
            new_evaluator = <DefaultEvaluator?> store
        
        new_evaluator.m_capture_dist = self.m_capture_dist
        new_evaluator.m_n_req = self.m_n_req
        
        return new_evaluator
        
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
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_req = self.n_req()
        capture_dist = self.capture_dist()
        
        self.r_rover_positions = (
            state.rover_positions(
                self.r_rover_positions)) #store

        self.r_sqr_rover_dists_to_poi.resize(n_rovers)
        
        # If there isn't enough rovers to satify the coupling constraint 
        # (n_req), then return 0.
        if n_req > n_rovers:
            return 0.  

        # Get the rover square distances to POI.
        for rover_id in range(n_rovers):
            displ_x = (
                self.r_rover_positions.view[rover_id, 0]
                - state.m_poi_positions.view[poi_id, 0]) # Direct read
            displ_y = (
                self.r_rover_positions.view[rover_id, 1]
                - state.m_poi_positions.view[poi_id, 1])  # Direct read
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
        return state.m_poi_values.view[poi_id]  # Direct read 

    cpdef DoubleArray1 rover_evals(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done,
            object store):
        cdef DoubleArray1 rover_evals  
        cdef Py_ssize_t n_rovers  
        
        if state_history is None:
            raise (
                TypeError(
                    "(state_history) can not be None"))    
                    
        if rover_actions_history is None:
            raise (
                TypeError(
                    "(rover_actions_history) can not be None"))  
        
        n_rovers = rover_actions_history.view.shape[1]
        
        if store is None or store is ...:
            rover_evals = DoubleArray1(np.zeros(n_rovers))
        else:
            rover_evals = <DoubleArray1?> store
            rover_evals.repurpose(n_rovers)
        
        rover_evals.set_all_to(
            self.eval(
                state_history,
                rover_actions_history,
                episode_is_done))
                
        return rover_evals
        
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
        

        
        

       
    
        

    