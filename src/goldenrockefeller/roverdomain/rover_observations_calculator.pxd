from .state cimport State

cdef class BaseRoverObservationsCalculator:
    cpdef BaseRoverObservationsCalculator copy(self, copy_obj = ?)

    cpdef list observations(self, State state)
    # type: (...) -> List[DoubleArray]


cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    cdef Py_ssize_t _n_observation_sections
    cdef Py_ssize_t _n_rovers
    cdef double _min_dist

    cpdef DefaultRoverObservationsCalculator copy(self, copy_obj = ?)

    cpdef double min_dist(self) except *
    cpdef void set_min_dist(self, double min_dist) except *

    cpdef Py_ssize_t n_observation_sections(self) except *
    cpdef void set_n_observation_sections(
        self,
        Py_ssize_t n_observation_sections
        ) except *

cdef DefaultRoverObservationsCalculator new_DefaultRoverObservationsCalculator()
cdef void init_DefaultRoverObservationsCalculator(
    DefaultRoverObservationsCalculator observations_calculator
    ) except *


