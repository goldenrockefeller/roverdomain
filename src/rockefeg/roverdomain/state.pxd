# cython: language_level=3


cdef class State:
    cdef public Py_ssize_t m_n_rovers
    cdef public Py_ssize_t m_n_pois
    cdef public double[:, ::1] m_rover_positions
    # double[n_rovers, 2]
    cdef public double[:, ::1] m_rover_orientations
    # double[n_rovers, 2]
    cdef public double[::1] m_poi_values
    # double[n_pois]
    cdef public double[:, ::1] m_poi_positions
    # double[n_pois, 2]
    
    cpdef Py_ssize_t n_rovers(self) except *
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *
    
    cpdef Py_ssize_t n_pois(self) except *
    cpdef void set_n_pois(self, Py_ssize_t n_pois) except *
    
    cpdef double[:, :] rover_positions(self, double[:, :] store = ?) except *
    cpdef void set_rover_positions(
        self, 
        const double[:, :] rover_positions
        ) except *
                
    cpdef double[:, :] rover_orientations(
        self, 
        double[:, :] store = ?
        ) except *
    cpdef void set_rover_orientations(
        self, 
        const double[:, :] rover_orientations
        ) except *
        
    cpdef double[:] poi_values(self, double[:] store = ?) except *
    cpdef void set_poi_values(self, const double[:] poi_values) except *
    
    cpdef double[:, :] poi_positions(self, double[:, :] store = ?) except *
    cpdef void set_poi_positions(
        self, 
        const double[:, :] poi_positions
        ) except *

    cpdef object copy(self, object store = ?)
        
        