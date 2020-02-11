from libc cimport math as cmath
import numpy as np
import inspect
cimport cython

@cython.warn.undeclared(True)    
cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    @cython.warn.undeclared(False)
    def __init__(self):
        self.m_n_observation_sections = 1
        self.m_min_dist = 1.
        self.m_n_rovers = 0
    
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
        
    cpdef Py_ssize_t n_rovers(self) except *:
        return self.m_n_rovers
        
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *:
        if n_rovers < 0:
            raise ValueError(
                "The number of rovers (n_rovers) must be non-negative. "
                + "The number of rovers received is %d."
                % n_rovers)
                
        self.m_n_rovers = n_rovers
        
        
    cpdef double min_dist(self) except *:
        return self.m_min_dist
        
    cpdef void set_min_dist(self, double min_dist) except *:
        if min_dist <= 0:
            raise ValueError("Minimum distance (min_dist) must be positive. "
                + "A value of %d was received"
                % min_dist)
                
        self.m_min_dist = min_dist
        
    cpdef Py_ssize_t n_observation_sections(self) except *:
        return self.m_n_observation_sections
    
    cpdef void set_n_observation_sections(
            self, 
            Py_ssize_t n_observation_sections
            ) except *:
        if n_observation_sections <= 0:
            raise ValueError("Number of rover_observation sections "
                + "(n_observations_sections) must be "
                + "positive. A value of %d was received"
                % n_observation_sections)
                
        self.m_n_observation_sections = n_observation_sections
                
    cpdef Py_ssize_t n_observation_dims(self) except *:
        return 2 * self.n_observation_sections()
    
    cpdef double[:, :] observations_copy(self, State state) except *:
        cdef Py_ssize_t n_rovers, n_pois 
        cdef Py_ssize_t n_observation_dims
        cdef double[:, :] observations
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_observation_dims = self.n_observation_dims()
        
        observations = np.zeros((n_rovers, n_observation_dims))
        return self.observations_via(observations, state)
    
    cpdef double[:, :] observations_via(self, 
            double [:, :] store,
            State state
            ) except *:
                
        # abbreviation: global frame (gf)
        # abbreviation: rover frame (rf)
        cdef Py_ssize_t rover_id, poi_id, other_rover_id, sec_id, obs_id
        cdef Py_ssize_t n_rovers, n_pois 
        cdef Py_ssize_t n_observation_dims
        cdef double gf_displ_x, gf_displ_y
        cdef double rf_displ_x, rf_displ_y, dist, angle
        cdef double[:, :] rover_positions
        cdef double[:, :] rover_orientations
        cdef double[:, :] poi_positions
        cdef double[:] poi_values
        cdef double[:, :] observations
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_observation_dims = self.n_observation_dims()
        
        observations = store[:n_rovers, :n_observation_dims]
        
        try:
            rover_positions = (
                state.rover_positions_via(self.r_rover_positions_store))
        except:
            self.r_rover_positions_store = state.rover_positions_copy()
            rover_positions = self.r_rover_positions_store
            
        try:
            rover_orientations = (
                state.rover_orientations_via(self.r_rover_orientations_store))
        except:
            self.r_rover_orientations_store = state.rover_orientations_copy()
            rover_orientations = self.r_rover_orientations_store
            
        try:
            poi_positions = state.poi_positions_via(self.r_poi_positions_store)
        except:
            self.r_poi_positions_store = state.poi_positions_copy()
            poi_positions = self.r_poi_positions_store
        
        try:
            poi_values = state.poi_values_via(self.r_poi_values_store)
        except:
            self.r_poi_values_store = state.poi_values_copy()
            poi_values = self.r_poi_values_store
        
        # Zero all observations.
        observations[...] = 0.
        
        # Calculate observation for each rover.
        for rover_id in range(n_rovers):
            
            # Update rover type observations
            for other_rover_id in range(n_rovers):
                # Agents should not sense self, ergo skip self comparison.
                if rover_id == other_rover_id:
                    continue
                    
                # Get global frame (gf) displacement.
                gf_displ_x = (
                    rover_positions[other_rover_id, 0]
                    - rover_positions[rover_id, 0])
                gf_displ_y = (
                    rover_positions[other_rover_id, 1] 
                    - rover_positions[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    rover_orientations[rover_id, 0] 
                    * gf_displ_x
                    + rover_orientations[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    rover_orientations[rover_id, 0]
                    * gf_displ_y
                    - rover_orientations[rover_id, 1]
                    * gf_displ_x)
                    
                dist = cmath.sqrt(rf_displ_x*rf_displ_x + rf_displ_y*rf_displ_y)
                
                # By bounding distance value we 
                # implicitly bound sensor values (1/dist^2) so that they 
                # don't explode when dist = 0.
                if dist < self.m_min_dist:
                    dist = self.m_min_dist
                    
                # Get arc tangent (angle) of displacement.
                angle = cmath.atan2(rf_displ_y, rf_displ_x) 
                
                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (angle + cmath.pi)
                    / (2 * cmath.pi) 
                    * self.m_n_observation_sections)
                    
                # Clip section index for pointer safety.
                obs_id = (
                    min(
                        max(0, sec_id), 
                        self.m_n_observation_sections - 1))
                    
                observations[rover_id, obs_id] += 1. / (dist*dist)

            # Update POI type observations.
            for poi_id in range(n_pois):
            
                # Get global (gf) frame displacement.
                gf_displ_x = (
                    poi_positions[poi_id, 0]
                    - rover_positions[rover_id, 0])
                gf_displ_y = (
                    poi_positions[poi_id, 1] 
                    - rover_positions[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    rover_orientations[rover_id, 0] 
                    * gf_displ_x
                    + rover_orientations[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    rover_orientations[rover_id, 0]
                    * gf_displ_y
                    - rover_orientations[rover_id, 1]
                    * gf_displ_x)
                    
                dist = cmath.sqrt(rf_displ_x*rf_displ_x + rf_displ_y*rf_displ_y)
                
                # By bounding distance value we 
                # implicitly bound sensor values (1/dist^2) so that they 
                # don't explode when dist = 0.
                if dist < self.m_min_dist:
                    dist = self.m_min_dist
                    
                # Get arc tangent (angle) of displacement.
                angle = cmath.atan2(rf_displ_y, rf_displ_x) 
                
                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (angle + cmath.pi)
                    / (2 * cmath.pi) 
                    * self.m_n_observation_sections)
                    
                # Clip section index for pointer safety and offset observations
                # index for POIs.
                obs_id = (
                    min(
                        max(0, sec_id), 
                        self.m_n_observation_sections - 1)
                    + self.m_n_observation_sections)
                    
                observations[rover_id, obs_id] += (
                    poi_values[poi_id] / (dist*dist))
                    
        return observations
        
        
    cpdef object copy(self):
        return DefaultRoverObservationsCalculator()
    
    cpdef object copy_via(self, object store):
        cdef DefaultRoverObservationsCalculator new_calculator
        cdef object store_type
        cdef object self_type
    
        if type(store) is not type(self):
            store_type = type(store)
            self_type = type(self)
            raise TypeError(
                "The type of the storage parameter "
                "(type(store) = {store_type}) must be exactly {self_type}."
                .format(**locals()))
        
        new_calculator = <DefaultRoverObservationsCalculator?> store
        
        return new_calculator
        