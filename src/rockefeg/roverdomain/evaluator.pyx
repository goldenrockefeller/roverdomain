# distutils: language = c++

cimport cython
from .state cimport RoverData, RoverDatum, PoiData, PoiDatum
from libcpp.vector cimport vector
from libcpp.algorithm cimport partial_sort
from libc.math cimport INFINITY
from rockefeg.cyutil.array cimport new_DoubleArray

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef object copy(self):
        raise NotImplementedError("Abstract method.")

    cpdef double eval(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done
            ) except *:
        raise NotImplementedError("Abstract method.")

    cpdef DoubleArray rover_evals(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done):
        raise NotImplementedError("Abstract method.")

cdef DefaultEvaluator new_DefaultEvaluator():
    cdef DefaultEvaluator evaluator

    evaluator = DefaultEvaluator.__new__(DefaultEvaluator)
    init_DefaultEvaluator(evaluator)

    return evaluator

cdef void init_DefaultEvaluator(DefaultEvaluator evaluator) except *:
    if evaluator is None:
        raise TypeError("The evaluator (evaluator) cannot be None.")

    evaluator.__capture_dist = 1.
    evaluator.__n_req = 1

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DefaultEvaluator(BaseEvaluator):
    def __init__(self):
        init_DefaultEvaluator(self)

    cpdef void check_state_history(self, StateHistory state_history) except *:
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t step_id
        cdef Py_ssize_t step_n_rovers
        cdef Py_ssize_t step_n_pois
        cdef Py_ssize_t n_pois

        if state_history is None:
            raise (
                TypeError(
                    "The state history (state_history) must not be None" ))

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        n_rovers = len(state_history.entry(0).rover_data())
        n_pois = len(state_history.entry(0).poi_data())

        for step_id in range(len(state_history)):
            step_n_rovers = len(state_history.entry(step_id).rover_data())
            step_n_pois = len(state_history.entry(step_id).poi_data())

            if n_rovers != step_n_rovers:
                raise (
                    ValueError(
                        "All states in the state history (state_history) must "
                        "have the same number of rovers. "
                        "(len(state_history.entry(0).rover_data()) "
                        "= {n_rovers}) and "
                        "(len(state_history.entry({step_id}).rover_data() "
                        "= {step_n_rovers})."
                        .format(**locals())))

            if n_pois != step_n_pois:
                raise (
                    ValueError(
                        "All states in the state history (state_history) must "
                        "have the same number of POIs. "
                        "(len(state_history.entry(0).poi_data()) "
                        "= {n_pois}) and "
                        "(len(state_history.entry({step_id}).poi_data() "
                        "= {step_n_pois})."
                        .format(**locals())))

    cpdef object copy(self):
        cdef DefaultEvaluator new_evaluator

        new_evaluator = self.__class__.__new__(self.__class__)

        new_evaluator.__capture_dist = self.__capture_dist
        new_evaluator.__n_req = self.__n_req

        return new_evaluator

    cpdef double step_eval_from_poi(
            self,
            State state,
            Py_ssize_t poi_id
            ) except *:
        cdef double displ_x, displ_y
        cdef RoverData rover_data
        cdef RoverDatum rover_datum
        cdef PoiData poi_data
        cdef PoiDatum poi_datum
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t rover_id
        cdef vector[double] sqr_rover_dists_to_poi

        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))

        rover_data = state.rover_data()
        poi_data = state.poi_data()
        poi_datum = poi_data.datum(poi_id)
        n_rovers = len(rover_data)
        n_pois = len(poi_data)

        sqr_rover_dists_to_poi = vector[double](n_rovers)

        # If there isn't enough rovers to satify the coupling constraint
        # (n_req), then return 0.
        if self.__n_req > n_rovers:
            return 0.

        # Get the rover square distances to POI.
        for rover_id in range(n_rovers):
            rover_datum = rover_data.datum(rover_id)
            displ_x = rover_datum.position_x() - poi_datum.position_x()
            displ_y = rover_datum.position_y() - poi_datum.position_y()
            sqr_rover_dists_to_poi[rover_id] = (
                displ_x*displ_x + displ_y*displ_y)



        # Sort first (n_req) closest rovers for evaluation.
        # Sqr_dists_to_poi is no longer in rover order!
        partial_sort(
            sqr_rover_dists_to_poi.begin(),
            sqr_rover_dists_to_poi.begin()
            + min(self.__n_req, <Py_ssize_t>(sqr_rover_dists_to_poi.size())),
            sqr_rover_dists_to_poi.end())

        # Is there (n_req) rovers capturing? Only need to check the (n_req)th
        # closest rover.
        if (
                sqr_rover_dists_to_poi[self.__n_req-1]
                >  self.__capture_dist * self.__capture_dist
        ):
            # Not close enough?, then there is no reward for this POI.
            return 0.

        # Close enough! Return evaluation.
        return poi_datum.value()

    cpdef double eval(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done
            ) except *:
        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t n_rovers
        cdef double eval
        cdef DoubleArray sub_evals_given_poi

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        # The number of POIs and Rovers must be the same for all states.
        self.check_state_history(state_history)

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = state_history.entry(0)
        n_rovers = len(state.rover_data())
        n_pois = len(state.poi_data())
        n_steps = len(state_history)

        sub_evals_given_poi = new_DoubleArray(n_pois)
        sub_evals_given_poi.set_all_to(-INFINITY)

        # Initialize evaluations.
        eval = 0.

        # Get evaluation for poi, for each step, storing the max.
        for step_id in range(n_steps):
            state = state_history.entry(step_id)
            # Keep best step evaluation for each poi.
            for poi_id in range(n_pois):
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        self.step_eval_from_poi(state, poi_id)))

        # Set evaluation to the sum of all POI-specific evaluations.
        for poi_id in range(n_pois):
            eval += sub_evals_given_poi.view[poi_id]

        return eval


    cpdef DoubleArray rover_evals(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done):
        cdef Py_ssize_t n_rovers
        cdef DoubleArray rover_evals

        if state_history is None:
            raise (
                TypeError(
                    "The state history (state_history) must not be None" ))

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        n_rovers = len(state_history.entry(0).rover_data())
        rover_evals = new_DoubleArray(n_rovers)

        rover_evals.set_all_to(
            self.eval(
                state_history,
                actions_history,
                episode_is_done))

        return rover_evals

    cpdef Py_ssize_t n_req(self) except *:
        return self.__n_req

    cpdef void set_n_req(self, Py_ssize_t n_req) except *:
        if n_req <= 0:
            raise ValueError(
                "The number of rovers required to capture a POI "
                " (n_req = {n_req}) must be positive."
                .format(**locals()))

        self.__n_req = n_req

    cpdef double capture_dist(self) except *:
        return self.__capture_dist

    cpdef void set_capture_dist(self, double capture_dist) except *:
        if capture_dist < 0.:
            raise ValueError(
                "The POIs' capture distance (capture_dist = {capture_dist}) "
                "must be non-negative."
                .format(**locals()))

        self.__capture_dist = capture_dist


cdef DifferenceEvaluator new_DifferenceEvaluator():
    cdef DifferenceEvaluator evaluator

    evaluator = DifferenceEvaluator.__new__(DifferenceEvaluator)
    init_DifferenceEvaluator(evaluator)

    return evaluator

cdef void init_DifferenceEvaluator(DifferenceEvaluator evaluator) except *:
    init_DefaultEvaluator(evaluator)

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DifferenceEvaluator(DefaultEvaluator):
    def __init__(self):
        init_DifferenceEvaluator(self)

    cpdef double cfact_step_eval_from_poi(
            self,
            State state,
            Py_ssize_t excluded_rover_id,
            Py_ssize_t poi_id
            ) except *:

        """
        Returns counterfactual step evaluation (cfact: evaluation without
        excluded rover contribution) for a given POI.
        """
        cdef double displ_x, displ_y
        cdef RoverData rover_data
        cdef RoverDatum rover_datum
        cdef PoiData poi_data
        cdef PoiDatum poi_datum
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t rover_id
        cdef vector[double] sqr_rover_dists_to_poi
        cdef double excluded_rover_sqr_dist

        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))

        rover_data = state.rover_data()
        poi_data = state.poi_data()
        poi_datum = poi_data.datum(poi_id)
        n_rovers = len(rover_data)
        n_pois = len(poi_data)

        sqr_rover_dists_to_poi = vector[double](n_rovers)

        # If there isn't enough rovers without excluding rover to satify the
        # coupling constraint (n_req), then return 0.
        if self.__n_req > n_rovers - 1:
            return 0.

        # Get the rover square distances to POIs.
        for rover_id in range(n_rovers):
            rover_datum = rover_data.datum(rover_id)
            displ_x = rover_datum.position_x() - poi_datum.position_x()
            displ_y = rover_datum.position_y() - poi_datum.position_y()
            sqr_rover_dists_to_poi[rover_id] = (
                displ_x*displ_x + displ_y*displ_y)


        # Sort first (n_req) closest rovers for evaluation.
        # Sqr_dists_to_poi is no longer in rover order!
        partial_sort(
            sqr_rover_dists_to_poi.begin(),
            sqr_rover_dists_to_poi.begin()
            + min(self.__n_req + 1, <Py_ssize_t>(sqr_rover_dists_to_poi.size())),
            sqr_rover_dists_to_poi.end())

        # Is there (n_req) rovers capturing? Only need to check the (n_req)th
        # closest rover.
        if (
                sqr_rover_dists_to_poi[self.__n_req - 1]
                > self.__capture_dist * self.__capture_dist
        ):
            # Not close enough?, then there is no reward for this POI
            return 0.

        # Check (n_req + 1)th closest rover instead if excluded rover would
        # otherwise also be capturing if not exluded.
        rover_datum = rover_data.datum(excluded_rover_id)
        displ_x = rover_datum.position_x() - poi_datum.position_x()
        displ_y = rover_datum.position_y() - poi_datum.position_y()
        excluded_rover_sqr_dist = displ_x*displ_x + displ_y*displ_y
        if (
                excluded_rover_sqr_dist
                <= self.__capture_dist * self.__capture_dist
        ):
            if (
                    sqr_rover_dists_to_poi[self.__n_req]
                    > self.__capture_dist * self.__capture_dist
            ):
                # Not close enough?, then there is no reward for this POI
                return 0.

        # Close enough! Return evaluation.
        return poi_datum.value()

    cpdef double cfact_eval(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done,
            Py_ssize_t excluded_rover_id
            ) except *:
        """
        Returns counterfactual evaluation (cfact: evaluation without excluded
        rover contribution).
        """

        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t n_rovers
        cdef double cfact_eval
        cdef DoubleArray sub_evals_given_poi

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        # The number of POIs and Rovers must be the same for all states.
        self.check_state_history(state_history)

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = state_history.entry(0)
        n_rovers = len(state.rover_data())
        n_pois = len(state.poi_data())
        n_steps = len(state_history)

        sub_evals_given_poi = new_DoubleArray(n_pois)
        sub_evals_given_poi.set_all_to(-INFINITY)

        # Give no reward until state is done.
        if not episode_is_done:
            return 0.

        # Initialize evaluations to 0
        cfact_eval = 0.

        # Set evaluation to the sum of all POI-specific evaluations.
        for poi_id in range(n_pois):
            cfact_eval += sub_evals_given_poi.view[poi_id]

        # Get evaluation for poi, for each step, storing the max
        for step_id in range(n_steps):
            state = state_history.entry(step_id)
            # Keep best step evalualtion for each poi
            for poi_id in range(n_pois):
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        self.cfact_step_eval_from_poi(
                            state,
                            excluded_rover_id,
                            poi_id)))

        # Set evaluation to the sum of all POI-specific evaluations
        for poi_id in range(n_pois):
            cfact_eval += sub_evals_given_poi.view[poi_id]

        return cfact_eval


    cpdef DoubleArray rover_evals(
            self,
            StateHistory state_history,
            ActionsHistory actions_history,
            bint episode_is_done):
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        cdef DoubleArray rover_evals

        if state_history is None:
            raise (
                TypeError(
                    "The state history (state_history) must not be None" ))

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        n_rovers = len(state_history.entry(0).rover_data())
        rover_evals = new_DoubleArray(n_rovers)

        rover_evals.set_all_to(
            self.eval(
                state_history,
                actions_history,
                episode_is_done))

        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            rover_evals.view[rover_id] -= (
                self.cfact_eval(
                    state_history,
                    actions_history,
                    episode_is_done,
                    rover_id))

        return rover_evals




