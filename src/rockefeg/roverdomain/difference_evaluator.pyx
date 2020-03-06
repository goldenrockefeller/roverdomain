from libcpp.algorithm cimport partial_sort
from rockefeg.ndarray.double_array_1 cimport DoubleArray1
cimport cython

import numpy as np
from numpy.math cimport INFINITY
from rockefeg.ndarray.double_array_1 import DoubleArray1

@cython.warn.undeclared(True)
cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef DifferenceEvaluator other
        cdef object other_type
        
        if index is not ...:
            raise IndexError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = DifferenceEvaluator() 
        elif type(obj) is type(self):
            other = <DifferenceEvaluator?> obj
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
        cdef DifferenceEvaluator other
        cdef object other_type
        
        if obj is None:        
            other = DifferenceEvaluator() 
        elif type(obj) is type(self):
            other = <DifferenceEvaluator?> obj
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

    cpdef double cfact_step_eval_from_poi(
            self, 
            State state, 
            Py_ssize_t excluded_rover_id,
            Py_ssize_t poi_id
            ) except *:

        """ 
        Returns counterfactual step evaluation (cfact: evaluation without 
        excluded rover contribution) for a given POI.
        """     
        cdef double displ_x, displ_y
        cdef double capture_dist
        cdef double excluded_rover_sqr_dist
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t n_req
        cdef Py_ssize_t rover_id
        
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))    
                    
        if excluded_rover_id < 0:
            raise ValueError(
                "The excluded rover index (excluded_rover_id = "
                "{excluded_rover_id}) must be non-negative. "
                .format(**locals()))
                
        if poi_id < 0:
            raise ValueError(
                "The excluded rover index (poi_id = "
                "{poi_id}) must be non-negative. "
                .format(**locals()))
        
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_req = self.n_req()
        capture_dist = self.capture_dist()

        self.r_sqr_rover_dists_to_poi.resize(n_rovers)
        
        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if n_req > n_rovers - 1:
            return 0.
            
        # Get the rover square distances to POIs.
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
                > capture_dist * capture_dist
        ):
            # Not close enough?, then there is no reward for this POI
            return 0.
            
        # Check (n_req + 1)th closest rover instead if excluded rover would 
        # otherwise also be capturing if not exluded.
        displ_x = (
            state.rover_positions().view[excluded_rover_id, 0]
            - state.poi_positions().view[poi_id, 0]) 
        displ_y = (
            state.rover_positions().view[excluded_rover_id, 1]
            - state.poi_positions().view[poi_id, 1]) 
        excluded_rover_sqr_dist = displ_x*displ_x + displ_y*displ_y
        if (
                excluded_rover_sqr_dist 
                <= capture_dist * capture_dist
        ):
            if (
                    self.r_sqr_rover_dists_to_poi[n_req] 
                    > capture_dist * capture_dist
            ):
                # Not close enough?, then there is no reward for this POI
                return 0.
                
        # Close enough! Return evaluation.
        return state.poi_values().view[poi_id]  

    cpdef double cfact_eval(
            self, 
            ObjectArray1 state_history, 
            ObjectArray1 rover_actions_history,
            bint episode_is_done,
            Py_ssize_t excluded_rover_id
            ) except *:
        """
        Returns counterfactual evaluation (cfact: evaluation without excluded 
        rover contribution).
        """
        
        cdef double cfact_eval
        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_req 
        cdef Py_ssize_t n_pois 
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_steps

        if state_history is None:
            raise (
                TypeError(
                    "(state_history) can not be None")) 
        self.check_state_history(state_history)
                    
        if excluded_rover_id < 0:
            raise ValueError(
                "The excluded rover index (excluded_rover_id = "
                "{excluded_rover_id}) must be non-negative. "
                .format(**locals()))
                
        
        state = <State?> state_history.view[0]
        n_req = self.n_req()
        n_pois = state.n_pois()
        n_rovers = state.n_rovers()
        n_steps = state_history.view.shape[0]
        
        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if n_req > n_rovers - 1:
            return 0.
            
        # Give no reward until state is done.
        if not episode_is_done:
            return 0.
        
        # Check each state.
        self.check_state_history(state_history)
        
        self.r_sub_evals_given_poi.repurpose(n_pois)
        self.r_sub_evals_given_poi.set_all_to(-INFINITY)
        
        # Initialize evaluations to 0
        cfact_eval = 0.
        
        # Get evaluation for poi, for each step, storing the max
        for step_id in range(n_steps):
            state = <State?> state_history.view[step_id]
            # Keep best step evalualtion for each poi
            for poi_id in range(n_pois):
                self.r_sub_evals_given_poi.view[poi_id] = (
                    max(
                        self.r_sub_evals_given_poi.view[poi_id],
                        self.cfact_step_eval_from_poi(
                            state,
                            excluded_rover_id,
                            poi_id)))
        
        # Set evaluation to the sum of all POI-specific evaluations
        for poi_id in range(n_pois):
            cfact_eval += self.r_sub_evals_given_poi.view[poi_id]
        
        return cfact_eval      
        

    cpdef DoubleArray1 rover_evals(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done):
                
        cdef State state
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        
        
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
        
        self.o_rover_evals.repurpose(n_rovers)
        
        # Get global evaluation first.
        self.o_rover_evals.set_all_to(
            self.eval(
                state_history,
                rover_actions_history,
                episode_is_done))
        
        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            self.o_rover_evals.view[rover_id] -= (
                self.cfact_eval(
                    state_history,
                    rover_actions_history,
                    episode_is_done,
                    rover_id))
                    
        return self.o_rover_evals


        