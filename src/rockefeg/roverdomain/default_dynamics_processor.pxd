# cython: language_level=3

from .state cimport State
from .base_dynamics_processor cimport BaseDynamicsProcessor


cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    cdef double[:, :] r_rover_positions
    cdef double[:, :] r_rover_orientations

    