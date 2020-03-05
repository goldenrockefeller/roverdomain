from libc cimport math as cmath
cimport cython

from rockefeg.ndarray.double_array_1 import DoubleArray1
from rockefeg.ndarray.double_array_2 import DoubleArray2
import numpy as np

@cython.warn.undeclared(True)    
cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    
    def __init__(self):
        self.m_n_observation_sections = 1
        self.m_min_dist = 1.
        self.m_n_rovers = 0
        
        self.r_rover_positions = DoubleArray2(None)
        self.r_rover_orientations = DoubleArray2(None)
        self.r_poi_positions = DoubleArray2(None)
        self.r_poi_values = DoubleArray1(None)
        
    cpdef object copy(self, object store):
        cdef DefaultRoverObservationsCalculator new_calculator
        cdef object store_type
        
        if store is None or store is ...:
            new_calculator = DefaultRoverObservationsCalculator() 
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))
        else:
            new_calculator = <DefaultRoverObservationsCalculator?> store
        
        return new_calculator
        
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
    
    cpdef DoubleArray2 observations(self, State state, object store):
                
        # abbreviation: global frame (gf)
        # abbreviation: rover frame (rf)
        cdef Py_ssize_t rover_id, poi_id, other_rover_id, sec_id, obs_id
        cdef Py_ssize_t n_rovers, n_pois 
        cdef Py_ssize_t n_observation_dims
        cdef double gf_displ_x, gf_displ_y
        cdef double rf_displ_x, rf_displ_y, dist, angle
        cdef DoubleArray2 observations
        
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))    
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_observation_dims = self.n_observation_dims()
        
        if store is None or store is ...:
            observations = (
                DoubleArray2(np.zeros((n_rovers, n_observation_dims))) )
        else:
            observations = <DoubleArray2?> store
            observations.repurpose(n_rovers, n_observation_dims)
        
        self.r_rover_positions = (
            state.rover_positions(
                self.r_rover_positions)) # store

        self.r_rover_orientations = (
            state.rover_orientations(
                self.r_rover_orientations)) # store

        self.r_poi_positions = state.poi_positions(self.r_poi_positions) # store
        
        self.r_poi_values = state.poi_values(self.r_poi_values) # store
        
        
        # Zero all observations.
        observations.set_all_to(0.)
        
        # Calculate observation for each rover.
        for rover_id in range(n_rovers):
            
            # Update rover type observations
            for other_rover_id in range(n_rovers):
                # Agents should not sense self, ergo skip self comparison.
                if rover_id == other_rover_id:
                    continue
                    
                # Get global frame (gf) displacement.
                gf_displ_x = (
                    self.r_rover_positions.view[other_rover_id, 0]
                    - self.r_rover_positions.view[rover_id, 0])
                gf_displ_y = (
                    self.r_rover_positions.view[other_rover_id, 1] 
                    - self.r_rover_positions.view[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    self.r_rover_orientations.view[rover_id, 0] 
                    * gf_displ_x
                    + self.r_rover_orientations.view[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    self.r_rover_orientations.view[rover_id, 0]
                    * gf_displ_y
                    - self.r_rover_orientations.view[rover_id, 1]
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
                    
                observations.view[rover_id, obs_id] += 1. / (dist*dist)

            # Update POI type observations.
            for poi_id in range(n_pois):
            
                # Get global (gf) frame displacement.
                gf_displ_x = (
                    self.r_poi_positions.view[poi_id, 0]
                    - self.r_rover_positions.view[rover_id, 0])
                gf_displ_y = (
                    self.r_poi_positions.view[poi_id, 1] 
                    - self.r_rover_positions.view[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    self.r_rover_orientations.view[rover_id, 0] 
                    * gf_displ_x
                    + self.r_rover_orientations.view[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    self.r_rover_orientations.view[rover_id, 0]
                    * gf_displ_y
                    - self.r_rover_orientations.view[rover_id, 1]
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
                    
                observations.view[rover_id, obs_id] += (
                    self.r_poi_values.view[poi_id] / (dist*dist))
                    
        return observations
        

        