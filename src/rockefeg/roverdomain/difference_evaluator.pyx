from libcpp.algorithm cimport partial_sort
from rockefeg.ndarray.double_array_1 cimport DoubleArray1
cimport cython

import numpy as np
from numpy.math cimport INFINITY
from rockefeg.ndarray.double_array_1 import DoubleArray1

@cython.warn.undeclared(True)
cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef object copy(self, object store):
        cdef DifferenceEvaluator new_evaluator
        cdef object store_type
        
        if store is None or store is ...:
            new_evaluator = DifferenceEvaluator() 
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))
        else:
            new_evaluator = <DifferenceEvaluator?> store
            
        new_evaluator.m_capture_dist = self.m_capture_dist
        new_evaluator.m_n_req = self.m_n_req
        
        return new_evaluator
    
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
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_req = self.n_req()
        capture_dist = self.capture_dist()
        
        
        
        self.r_rover_positions = (
            state.rover_positions(
                self.r_rover_positions)) # store
        
        
        self.r_sqr_rover_dists_to_poi.resize(n_rovers)
        
        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if n_req > n_rovers - 1:
            return 0.
            
        # Get the rover square distances to POIs.
        for rover_id in range(n_rovers):
            displ_x = (
                self.r_rover_positions.view[rover_id, 0]
                - self.m_poi_positions.view[poi_id, 0]) # Direct read
            displ_y = (
                self.r_rover_positions.view[rover_id, 1]
                - self.m_poi_positions.view[poi_id, 1]) # Direct read
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
            self.r_rover_positions.view[excluded_rover_id, 0]
            - self.m_poi_positions.view[poi_id, 0]) # Direct read
        displ_y = (
            self.r_rover_positions.view[excluded_rover_id, 1]
            - self.m_poi_positions.view[poi_id, 1]) # Direct read
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
        return state.m_poi_values[poi_id]   # Direct read. 

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
                    
        if rover_actions_history is None:
            raise (
                TypeError(
                    "(rover_actions_history) can not be None"))  
        
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
            bint episode_is_done,
            object store):
                
        cdef State state
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        cdef DoubleArray1 rover_evals
        
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
        
        if store is None or store is ...:
            rover_evals = DoubleArray1(np.zeros(n_rovers))
        else:
            rover_evals = <DoubleArray1?> store
            rover_evals.repurpose(n_rovers)
        
        # Get global evaluation first.
        rover_evals.set_all_to(
            self.eval(
                state_history,
                rover_actions_history,
                episode_is_done))
        
        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            rover_evals.view[rover_id] -= (
                self.cfact_eval(
                    state_history,
                    rover_actions_history,
                    episode_is_done,
                    rover_id))
                    
        return rover_evals


        