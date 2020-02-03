# cython: language_level=3

from .state cimport State

from .base_rover_observations_calculator cimport BaseRoverObservationsCalculator

cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    cdef public Py_ssize_t m_n_observation_sections
    cdef public Py_ssize_t m_n_rovers
    cdef public double m_min_dist
    
    cdef double[:, :] r_rover_positions_store
    cdef double[:, :] r_rover_orientations_store
    cdef double[:, :] r_poi_positions_store
    cdef double[:] r_poi_values_store
    
    cpdef Py_ssize_t n_observation_dims(self) except *

    cpdef double min_dist(self) except *
    cpdef void set_min_dist(self, double min_dist) except *
    
    cpdef Py_ssize_t n_observation_sections(self) except *
    cpdef void set_n_observation_sections(
        self, 
        Py_ssize_t n_observation_sections
        ) except *
        
    cpdef Py_ssize_t n_rovers(self) except *
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *
    
    