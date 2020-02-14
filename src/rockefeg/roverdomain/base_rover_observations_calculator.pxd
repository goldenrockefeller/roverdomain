# cython: language_level=3


from .state cimport State

cdef class BaseRoverObservationsCalculator:
    cpdef double[:, :] observations(
        self,  
        State state,
        double[:, :] store = ?
        ) except *
    # double[n_rovers, n_rover_observation_dims]
    
    cpdef object copy(self, object store = ?)