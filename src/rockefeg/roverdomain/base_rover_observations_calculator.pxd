# cython: language_level=3


from .state cimport State

cdef class BaseRoverObservationsCalculator:
    cpdef double[:, :] observations_copy(self, State state) except *
    # double[n_rovers, n_rover_observation_dims]
    
    cpdef double[:, :] observations_via(
        self, 
        double[:, :] store, 
        State state
        ) except *
    # double[n_rovers, n_rover_observation_dims]
    
    cpdef object copy(self)
    cpdef object copy_via(self, object store)