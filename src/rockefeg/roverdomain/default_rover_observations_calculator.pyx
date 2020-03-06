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
        
        self.o_observations = DoubleArray2(None)
        
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef DefaultRoverObservationsCalculator other
        cdef object other_type
        
        if index is not ...:
            raise IndexError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = DefaultRoverObservationsCalculator()  
        elif type(obj) is type(self):
            other = <DefaultRoverObservationsCalculator?> obj
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
        cdef DefaultRoverObservationsCalculator other
        cdef object other_type
        
        if obj is None:        
            other = DefaultRoverObservationsCalculator() 
        elif type(obj) is type(self):
            other = <DefaultRoverObservationsCalculator?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, None"
                    .format(**locals())))
                
        return other

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
    
    cpdef DoubleArray2 observations(self, State state):
                
        # abbreviation: global frame (gf)
        # abbreviation: rover frame (rf)
        cdef Py_ssize_t rover_id, poi_id, other_rover_id, sec_id, obs_id
        cdef Py_ssize_t n_rovers, n_pois 
        cdef Py_ssize_t n_observation_dims
        cdef double gf_displ_x, gf_displ_y
        cdef double rf_displ_x, rf_displ_y, dist, angle
        
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))    
        
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_observation_dims = self.n_observation_dims()
        
        self.o_observations.repurpose(n_rovers, n_observation_dims)

        # Zero all observations.
        self.o_observations.set_all_to(0.)
        
        # Calculate observation for each rover.
        for rover_id in range(n_rovers):
            
            # Update rover type observations
            for other_rover_id in range(n_rovers):
                # Agents should not sense self, ergo skip self comparison.
                if rover_id == other_rover_id:
                    continue
                    
                # Get global frame (gf) displacement.
                gf_displ_x = (
                    state.rover_positions().view[other_rover_id, 0]
                    - state.rover_positions().view[rover_id, 0])
                gf_displ_y = (
                    state.rover_positions().view[other_rover_id, 1] 
                    - state.rover_positions().view[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    state.rover_orientations().view[rover_id, 0] 
                    * gf_displ_x
                    + state.rover_orientations().view[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    state.rover_orientations().view[rover_id, 0]
                    * gf_displ_y
                    - state.rover_orientations().view[rover_id, 1]
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
                    
                self.o_observations.view[rover_id, obs_id] += 1. / (dist*dist)

            # Update POI type observations.
            for poi_id in range(n_pois):
            
                # Get global (gf) frame displacement.
                gf_displ_x = (
                    state.poi_positions().view[poi_id, 0]
                    - state.rover_positions().view[rover_id, 0])
                gf_displ_y = (
                    state.poi_positions().view[poi_id, 1] 
                    - state.rover_positions().view[rover_id, 1])
                    
                # Get rover frame (rf) displacement.
                rf_displ_x = (
                    state.rover_orientations().view[rover_id, 0] 
                    * gf_displ_x
                    + state.rover_orientations().view[rover_id, 1]
                    * gf_displ_y)
                rf_displ_y = (
                    state.rover_orientations().view[rover_id, 0]
                    * gf_displ_y
                    - state.rover_orientations().view[rover_id, 1]
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
                    
                self.o_observations.view[rover_id, obs_id] += (
                    state.poi_values().view[poi_id] / (dist*dist))
                    
        return self.o_observations
        

        