# cython: language_level=3
from rockefeg.ndarray.double_array_1 cimport DoubleArray1
from rockefeg.ndarray.double_array_2 cimport DoubleArray2

cdef class State:
    cdef public Py_ssize_t m_n_rovers
    cdef public Py_ssize_t m_n_pois
    cdef public DoubleArray2 m_rover_positions
    # double[n_rovers, 2]
    cdef public DoubleArray2 m_rover_orientations
    # double[n_rovers, 2]
    cdef public DoubleArray1 m_poi_values
    # double[n_pois]
    cdef public DoubleArray2 m_poi_positions
    # double[n_pois, 2]

    cpdef object copy(self)
    cpdef object copy_to(self, object obj)
    
    cpdef Py_ssize_t n_rovers(self) except *
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *
    
    cpdef Py_ssize_t n_pois(self) except *
    cpdef void set_n_pois(self, Py_ssize_t n_pois) except *
    
    
    cpdef DoubleArray2 rover_positions(self)
    cpdef void set_rover_positions(
        self, 
        DoubleArray2 rover_positions
        ) except *
                
    cpdef DoubleArray2 rover_orientations(self)
    cpdef void set_rover_orientations(
        self, 
        DoubleArray2 rover_orientations
        ) except *
        
    cpdef DoubleArray1 poi_values(self)
    cpdef void set_poi_values(self, DoubleArray1 poi_values) except *
    
    cpdef DoubleArray2 poi_positions(self)
    cpdef void set_poi_positions(self, DoubleArray2 poi_positions) except *

        
        