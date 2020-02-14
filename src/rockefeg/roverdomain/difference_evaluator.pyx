from libcpp.algorithm cimport partial_sort
cimport cython

import numpy as np
import inspect
from numpy.math cimport INFINITY

@cython.warn.undeclared(True)
cdef class DifferenceEvaluator(DefaultEvaluator):
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
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_req = self.n_req()
        capture_dist = self.capture_dist()
        
        
        self.r_poi_positions = state.poi_positions(store = self.r_poi_positions)
        self.r_poi_values = state.poi_values(store = self.r_poi_values)
        self.r_rover_positions = (
            state.rover_positions(store = self.r_rover_positions))
        
        
        self.r_sqr_rover_dists_to_poi.resize(n_rovers)
        
        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if n_req > n_rovers - 1:
            return 0.
            
        # Get the rover square distances to POIs.
        for rover_id in range(n_rovers):
            displ_x = (
                self.r_rover_positions[rover_id, 0]
                - self.r_poi_positions[poi_id, 0])
            displ_y = (
                self.r_rover_positions[rover_id, 1]
                - self.r_poi_positions[poi_id, 1])
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
            self.r_rover_positions[excluded_rover_id, 0]
            - self.r_poi_positions[poi_id, 0])
        displ_y = (
            self.r_rover_positions[excluded_rover_id, 1]
            - self.r_poi_positions[poi_id, 1])
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
        return self.r_poi_values[poi_id]    

    cpdef double cfact_eval(
            self, 
            object[:] state_history, 
            const double[:, :, :] rover_actions_history,
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
        cdef double[:] sub_evals_given_poi
        
        state = <State?> state_history[0]
        n_req = self.n_req()
        n_pois = state.n_pois()
        n_rovers = state.n_rovers()
        n_steps = state_history.shape[0]
        
        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if n_req > n_rovers - 1:
            return 0.
            
        # Give no reward until state is done.
        if not episode_is_done:
            return 0.
        
        # Reallocate buffers for efficiency if necessary.
        if self.r_sub_evals_given_poi_store.shape[0] < n_pois:
            self.r_sub_evals_given_poi_store = np.zeros(n_pois)
        sub_evals_given_poi = self.r_sub_evals_given_poi_store[:n_pois]
        
        # Initialize evaluations to 0
        cfact_eval = 0.
        sub_evals_given_poi[...] = -INFINITY
        
        # Get evaluation for poi, for each step, storing the max
        for step_id in range(n_steps):
            state = <State?>state_history[step_id]
            # Keep best step evalualtion for each poi
            for poi_id in range(n_pois):
                sub_evals_given_poi[poi_id] = (
                    max(
                        sub_evals_given_poi[poi_id],
                        self.cfact_step_eval_from_poi(
                            state,
                            excluded_rover_id,
                            poi_id)))
        
        # Set evaluation to the sum of all POI-specific evaluations
        for poi_id in range(n_pois):
            cfact_eval += sub_evals_given_poi[poi_id]
        
        return cfact_eval      
        

    cpdef double[:] rover_evals(
            self,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint episode_is_done,
            double[:] store = None
            ) except *:
                
        cdef State state
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        cdef double[:] rover_evals
        
        state = <State?>state_history[0]
        n_rovers = state.n_rovers()
        
        try:
            rover_evals = store[:n_rovers]
        except:
            rover_evals = np.zeros(n_rovers)
        
        # Get global evaluation first.
        rover_evals[...] =  (
            self.eval(
                state_history,
                rover_actions_history,
                episode_is_done))
        
        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            rover_evals[rover_id] -= (
                self.cfact_eval(
                    state_history,
                    rover_actions_history,
                    episode_is_done,
                    rover_id))
                    
        return rover_evals

    cpdef object copy(self, object store = None):
        cdef DifferenceEvaluator new_evaluator
        cdef object store_type
        cdef object self_type
        
        try:
            if type(store) is not type(self):
                store_type = type(store)
                self_type = type(self)
                raise TypeError(
                    "The type of the storage parameter "
                    "(type(store) = {store_type}) must be exactly {self_type}."
                    .format(**locals()))
            
            new_evaluator = <DifferenceEvaluator?> store
        except:
            new_evaluator = DifferenceEvaluator()
            
        new_evaluator.m_capture_dist = self.m_capture_dist
        new_evaluator.m_n_req = self.m_n_req
        
        return new_evaluator
        