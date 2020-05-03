cimport cython

cdef class BaseRoverObservationsCalculator:
    cpdef copy(self, copy_obj = ?)

    cpdef list observations(self, state)
    # list<DoubleArray>[n_rovers][n_obs_dims]

cdef DefaultRoverObservationsCalculator new_DefaultRoverObservationsCalculator()
cdef void init_DefaultRoverObservationsCalculator(
    DefaultRoverObservationsCalculator observations_calculator
    ) except *

cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    cdef Py_ssize_t __n_observation_sections
    cdef Py_ssize_t __n_rovers
    cdef double __min_dist

    cpdef double min_dist(self) except *
    cpdef void set_min_dist(self, double min_dist) except *

    cpdef Py_ssize_t n_observation_sections(self) except *
    cpdef void set_n_observation_sections(
        self,
        Py_ssize_t n_observation_sections
        ) except *



