cimport cython
import cython
from libc cimport math as cmath
from goldenrockefeller.cyutil.array cimport DoubleArray, new_DoubleArray
from .state cimport RoverDatum, PoiDatum

from typing import List, Sequence

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef BaseRoverObservationsCalculator copy(self, copy_obj = None):
        pass

    cpdef list observations(self, State state):
        # type: (...) -> List[DoubleArray]
        raise NotImplementedError("Abstract method.")

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    def __init__(self):
        init_DefaultRoverObservationsCalculator(self)

    cpdef DefaultRoverObservationsCalculator copy(self, copy_obj = None):
        cdef DefaultRoverObservationsCalculator new_observations_calculator

        if copy_obj is None:
            new_observations_calculator = (
                DefaultRoverObservationsCalculator.__new__(
                    DefaultRoverObservationsCalculator))
        else:
            new_observations_calculator = copy_obj

        new_observations_calculator._min_dist = self._min_dist
        new_observations_calculator._n_observation_sections = (
            self._n_observation_sections)

        return new_observations_calculator

    @cython.locals(observations=list, rover_data=list)
    cpdef list observations(self, State state):
        # type: (...) -> List[DoubleArray]
        observations: List[DoubleArray]
        cdef RoverDatum rover_datum
        cdef RoverDatum other_rover_datum
        cdef PoiDatum poi_datum
        cdef DoubleArray observation
        rover_data: Sequence[RoverDatum]
        cdef Py_ssize_t rover_id, poi_id, other_rover_id, sec_id, obs_id
        cdef Py_ssize_t n_rovers, n_pois
        cdef Py_ssize_t n_observation_dims
        cdef double gf_displ_x, gf_displ_y # global frame (gf)
        cdef double rf_displ_x, rf_displ_y # rover frame (rf)
        cdef double rotation_vector_x, rotation_vector_y
        cdef double dist
        cdef double rf_displ_angle
        cdef double min_dist
        cdef Py_ssize_t n_observation_sections

        rover_data = state.rover_data()
        n_rovers = len(rover_data)
        n_pois = len(state.poi_data())
        n_observation_dims = 2 * self.n_observation_sections()
        min_dist = self.min_dist()
        n_observation_sections = self.n_observation_sections()

        # Allocate observation arrays.
        observations = [None] * n_rovers
        for rover_id in range(n_rovers):
            observation = new_DoubleArray(n_observation_dims)
            observation.set_all_to(0.)
            observations[rover_id] = observation

        # Calculate observation for each rover.
        for rover_id in range(n_rovers):
            rover_datum = rover_data[rover_id]
            observation = observations[rover_id]

            # Update rover type observations
            for other_rover_datum in rover_data:
                # Agents should not sense self, ergo skip self comparison.
                if rover_datum is other_rover_datum:
                    continue

                # Get global frame (gf) displacement between the two rovers.
                gf_displ_x = (
                    other_rover_datum.position_x()
                    - rover_datum.position_x())
                gf_displ_y = (
                    other_rover_datum.position_y()
                    - rover_datum.position_y())

                # Transform global frame displacement between the two rovers to
                # rover frame (rf) displacement.
                rotation_vector_x = cmath.cos(rover_datum.direction())
                rotation_vector_y = cmath.sin(rover_datum.direction())
                rf_displ_x = (
                    rotation_vector_x * gf_displ_x
                    + rotation_vector_y * gf_displ_y)
                rf_displ_y = (
                    rotation_vector_x * gf_displ_y
                    - rotation_vector_y * gf_displ_x)

                dist = cmath.sqrt(rf_displ_x*rf_displ_x + rf_displ_y*rf_displ_y)

                # By bounding distance value we
                # implicitly bound sensor values (1/dist^2) so that they
                # don't explode when dist = 0.
                if dist < min_dist:
                    dist = min_dist

                # Get arc tangent (angle) of displacement.
                rf_displ_angle = cmath.atan2(rf_displ_y, rf_displ_x)

                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (rf_displ_angle + cmath.pi)
                    / (2 * cmath.pi)
                    * n_observation_sections)

                # Clip section index for pointer safety.
                obs_id = (
                    min(
                        max(0, sec_id),
                        n_observation_sections - 1))

                observation.view[obs_id] += 1. / (dist*dist)

            # Update POI type observations.
            for poi_datum in state.poi_data():

                # Get global frame (gf) displacement between the rover and POI.
                gf_displ_x = (
                    poi_datum.position_x() - rover_datum.position_x())
                gf_displ_y = (
                    poi_datum.position_y() - rover_datum.position_y())

                # Transform global frame displace to rover frame (rf) "
                # displacement.
                rotation_vector_x = cmath.cos(rover_datum.direction())
                rotation_vector_y = cmath.sin(rover_datum.direction())
                rf_displ_x = (
                    rotation_vector_x * gf_displ_x
                    + rotation_vector_y * gf_displ_y)
                rf_displ_y = (
                    rotation_vector_x * gf_displ_y
                    - rotation_vector_y * gf_displ_x)

                dist = cmath.sqrt(rf_displ_x*rf_displ_x + rf_displ_y*rf_displ_y)

                # By bounding distance value we
                # implicitly bound sensor values (1/dist^2) so that they
                # don't explode when dist = 0.
                if dist < min_dist:
                    dist = min_dist

                # Get arc tangent (angle) of displacement.
                rf_displ_angle = cmath.atan2(rf_displ_y, rf_displ_x)

                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (rf_displ_angle + cmath.pi)
                    / (2 * cmath.pi)
                    * n_observation_sections)

                # Clip section index for pointer safety and offset observations
                # index for POIs.
                obs_id = (
                    min(
                        max(0, sec_id),
                        n_observation_sections - 1)
                    + n_observation_sections)

                observation.view[obs_id] += poi_datum.value() / (dist*dist)

        return observations

    cpdef double min_dist(self) except *:
        return self._min_dist

    cpdef void set_min_dist(self, double min_dist) except *:
        if min_dist <= 0.:
            raise (
                ValueError(
                    "The minimum distance (min_dist = {min_dist}) must be "
                    "positive. "
                    .format(**locals()) ))

        self._min_dist = min_dist

    cpdef Py_ssize_t n_observation_sections(self) except *:
        return self._n_observation_sections


    cpdef void set_n_observation_sections(
            self,
            Py_ssize_t n_observation_sections
            ) except *:
        if n_observation_sections <= 0:
            raise (
                ValueError(
                    "The number of rover observation sections "
                    "(n_observations_sections = {n_observations_sections}) "
                    "must be positive."
                    .format(**locals()) ))

        self._n_observation_sections = n_observation_sections

@cython.warn.undeclared(True)
cdef DefaultRoverObservationsCalculator new_DefaultRoverObservationsCalculator():
    cdef DefaultRoverObservationsCalculator observations_calculator

    observations_calculator = (
        DefaultRoverObservationsCalculator.__new__(
            DefaultRoverObservationsCalculator ))
    init_DefaultRoverObservationsCalculator(observations_calculator)

    return observations_calculator

@cython.warn.undeclared(True)
cdef void init_DefaultRoverObservationsCalculator(
        DefaultRoverObservationsCalculator observations_calculator
        ) except *:
    if observations_calculator is None:
        raise (
            TypeError(
                "The observations calculator "
                "(observations_calculator) cannot be None." ))

    observations_calculator._min_dist = 1.
    observations_calculator._n_observation_sections = 4