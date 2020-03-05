# cython: language_level=3

from .state cimport State
from .base_rover_observations_calculator cimport BaseRoverObservationsCalculator

from rockefeg.ndarray.double_array_1 cimport DoubleArray1
from rockefeg.ndarray.double_array_2 cimport DoubleArray2

cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    cdef public Py_ssize_t m_n_observation_sections
    cdef public Py_ssize_t m_n_rovers
    cdef public double m_min_dist
    
    cdef DoubleArray2 r_rover_positions
    cdef DoubleArray2 r_rover_orientations
    cdef DoubleArray2 r_poi_positions
    cdef DoubleArray1 r_poi_values
    
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
    
    