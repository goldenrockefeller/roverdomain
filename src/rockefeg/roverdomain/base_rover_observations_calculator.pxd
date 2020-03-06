# cython: language_level=3


from .state cimport State

from rockefeg.ndarray.double_array_2 cimport DoubleArray2

cdef class BaseRoverObservationsCalculator:
    cpdef DoubleArray2 observations(self, State state)
    # double[n_rovers, n_rover_observation_dims]
    
    cpdef object copy(self)
    
    cpdef object copy_to(self, object obj)