# cython: language_level=3

from .state cimport State
from .base_dynamics_processor cimport BaseDynamicsProcessor

from rockefeg.ndarray.double_array_2 cimport DoubleArray2

cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    cdef DoubleArray2 r_rover_positions
    cdef DoubleArray2 r_rover_orientations

    