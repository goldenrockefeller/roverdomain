cimport cython
from libc cimport math as cmath
from rockefeg.cyutil.array cimport DoubleArray, new_DoubleArray
from .state cimport RoverData, RoverDatum, PoiData, PoiDatum

from .state cimport State

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseRoverObservationsCalculator:
    cpdef copy(self, opy_obj = None):
        raise NotImplementedError("Abstract method.")

    cpdef list observations(self, state):
        raise NotImplementedError("Abstract method.")


cdef DefaultRoverObservationsCalculator new_DefaultRoverObservationsCalculator():
    cdef DefaultRoverObservationsCalculator observations_calculator

    observations_calculator = (
        DefaultRoverObservationsCalculator.__new__(
            DefaultRoverObservationsCalculator ))
    init_DefaultRoverObservationsCalculator(observations_calculator)

    return observations_calculator

cdef void init_DefaultRoverObservationsCalculator(
        DefaultRoverObservationsCalculator observations_calculator
        ) except *:
    if observations_calculator is None:
        raise (
            TypeError(
                "The observations calculator "
                "(observations_calculator) cannot be None." ))

    observations_calculator.__min_dist = 1.
    observations_calculator.__n_observation_sections = 4

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DefaultRoverObservationsCalculator(BaseRoverObservationsCalculator):
    def __init__(self):
        init_DefaultRoverObservationsCalculator(self)

    cpdef copy(self, copy_obj = None):
        cdef DefaultRoverObservationsCalculator new_observations_calculator

        if copy_obj is None:
            new_observations_calculator = (
                DefaultRoverObservationsCalculator.__new__(
                    DefaultRoverObservationsCalculator))
        else:
            new_observations_calculator = copy_obj

        new_observations_calculator.__min_dist = self.__min_dist
        new_observations_calculator.__n_observation_sections = (
            self.__n_observation_sections)

        return new_observations_calculator

    cpdef list observations(self, state):
        cdef State cy_state = <State?>state
        cdef list observations
        cdef RoverData rover_data
        cdef RoverDatum rover_datum
        cdef RoverDatum other_rover_datum
        cdef PoiData poi_data
        cdef PoiDatum poi_datum
        cdef DoubleArray observation
        cdef Py_ssize_t rover_id, poi_id, other_rover_id, sec_id, obs_id
        cdef Py_ssize_t n_rovers, n_pois
        cdef Py_ssize_t n_observation_dims
        cdef double gf_displ_x, gf_displ_y # global frame (gf)
        cdef double rf_displ_x, rf_displ_y # rover frame (rf)
        cdef double rotation_vector_x, rotation_vector_y
        cdef double dist
        cdef double rf_displ_angle

        rover_data = cy_state.rover_data()
        poi_data = cy_state.poi_data()

        n_rovers = len(rover_data)
        n_pois = len(poi_data)
        n_observation_dims = 2 * self.n_observation_sections()

        # Allocate observation arrays.
        observations = [None] * n_rovers
        for rover_id in range(n_rovers):
            observation = new_DoubleArray(n_observation_dims)
            observation.set_all_to(0.)
            observations[rover_id] = observation

        # Calculate observation for each rover.
        for rover_id in range(n_rovers):
            rover_datum = rover_data.datum(rover_id)
            observation = observations[rover_id]

            # Update rover type observations
            for other_rover_id in range(n_rovers):
                # Agents should not sense self, ergo skip self comparison.
                if rover_id == other_rover_id:
                    continue

                other_rover_datum = rover_data.datum(other_rover_id)

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
                if dist < self.__min_dist:
                    dist = self.__min_dist

                # Get arc tangent (angle) of displacement.
                rf_displ_angle = cmath.atan2(rf_displ_y, rf_displ_x)

                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (rf_displ_angle + cmath.pi)
                    / (2 * cmath.pi)
                    * self.__n_observation_sections)

                # Clip section index for pointer safety.
                obs_id = (
                    min(
                        max(0, sec_id),
                        self.__n_observation_sections - 1))

                observation.view[obs_id] += 1. / (dist*dist)


            # Update POI type observations.
            for poi_id in range(n_pois):
                poi_datum = poi_data.datum(poi_id)

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
                if dist < self.__min_dist:
                    dist = self.__min_dist

                # Get arc tangent (angle) of displacement.
                rf_displ_angle = cmath.atan2(rf_displ_y, rf_displ_x)

                #  Get intermediate Section Index by discretizing angle.
                sec_id = <Py_ssize_t>cmath.floor(
                    (rf_displ_angle + cmath.pi)
                    / (2 * cmath.pi)
                    * self.__n_observation_sections)

                # Clip section index for pointer safety and offset observations
                # index for POIs.
                obs_id = (
                    min(
                        max(0, sec_id),
                        self.__n_observation_sections - 1)
                    + self.__n_observation_sections)

                observation.view[obs_id] += poi_datum.value() / (dist*dist)

        return observations

    cpdef double min_dist(self) except *:
        return self.__min_dist

    cpdef void set_min_dist(self, double min_dist) except *:
        if min_dist <= 0.:
            raise (
                ValueError(
                    "The minimum distance (min_dist = {min_dist}) must be "
                    "positive. "
                    .format(**locals()) ))

        self.__min_dist = min_dist

    cpdef Py_ssize_t n_observation_sections(self) except *:
        return self.__n_observation_sections


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

        self.__n_observation_sections = n_observation_sections
