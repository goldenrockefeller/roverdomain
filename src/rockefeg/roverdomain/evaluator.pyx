cimport cython
import cython

from libc.math cimport INFINITY
from rockefeg.cyutil.array cimport new_DoubleArray

from typing import Sequence

@cython.locals(state_history=list)
@cython.warn.undeclared(True)
cpdef void ensure_consistent_n_rovers_in_state_history(
        state_history: Sequence[State]
        ) except *:

    cdef State state
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t step_n_rovers

    if len(state_history) == 0:
        return

    state = state_history[0]
    n_rovers = len(state.rover_data())

    for state in state_history:
        step_n_rovers = len(state.rover_data())

        if n_rovers != step_n_rovers:
            raise (
                ValueError(
                    "All states in the state history (state_history) must "
                    "have the same number of rovers. "
                    "(len(state_history[0].rover_data()) "
                    "= {n_rovers}) and "
                    "(len(state_history[step_id].rover_data()) "
                    "= {step_n_rovers})."
                    .format(**locals())))

@cython.warn.undeclared(True)
@cython.locals(state_history=list)
cpdef void ensure_consistent_n_pois_in_state_history(
        state_history: Sequence[State]
        ) except *:

    cdef State state
    cdef Py_ssize_t n_pois
    cdef Py_ssize_t step_n_pois


    if len(state_history) == 0:
        return

    state = state_history[0]
    n_pois = len(state.poi_data())

    for state in state_history:
        step_n_pois = len(state.poi_data())

        if n_pois != step_n_pois:
            raise (
                ValueError(
                    "All states in the state history (state_history) must "
                    "have the same number of POIs. "
                    "(len(state_history[0].poi_data()) "
                    "= {n_pois}) and "
                    "(len(state_history[step_id].poi_data()) "
                    "= {step_n_pois})."
                    .format(**locals())))

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef BaseEvaluator copy(self, copy_obj = None):
        pass

    @cython.locals(state_history = list, actions_history = list)
    cpdef double eval(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done
            ) except *:
        raise NotImplementedError("Abstract method.")

    @cython.locals(state_history = list, actions_history = list)
    cpdef DoubleArray rover_evals(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done):
        raise NotImplementedError("Abstract method.")

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DefaultEvaluator(BaseEvaluator):
    def __init__(self):
        init_DefaultEvaluator(self)

    cpdef DefaultEvaluator copy(self, copy_obj = None):
        cdef DefaultEvaluator new_evaluator

        if copy_obj is None:
            new_evaluator = DefaultEvaluator.__new__(DefaultEvaluator)
        else:
            new_evaluator = copy_obj

        new_evaluator.__capture_dist = self.__capture_dist
        new_evaluator.__n_req = self.__n_req

        return new_evaluator

    @cython.locals(state_history = list, actions_history = list)
    cpdef double eval(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done
            ) except *:

        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef double eval
        cdef DoubleArray sub_evals_given_poi
        cdef PoiDatum poi_datum

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        # More (expensive) error checking.
        ensure_consistent_n_rovers_in_state_history(state_history)
        ensure_consistent_n_pois_in_state_history(state_history)

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))


        state = state_history[0]
        n_pois = len(state.poi_data())
        n_steps = len(state_history)

        sub_evals_given_poi = new_DoubleArray(n_pois)
        sub_evals_given_poi.set_all_to(-INFINITY)

        # Initialize evaluations.
        eval = 0.

        # Get evaluation for poi, for each step, storing the max.
        for step_id in range(n_steps):
            state = state_history[step_id]
            # Keep best step evaluation for each poi.
            for poi_id in range(n_pois):
                poi_datum = state.poi_data()[poi_id]
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        step_eval_from_poi_for_DefaultEvaluator(
                            self,
                            poi_datum,
                            state.rover_data() )))

        # Set evaluation to the sum of all POI-specific evaluations.
        for poi_id in range(n_pois):
            eval += sub_evals_given_poi.view[poi_id]

        return eval

    @cython.locals(state_history = list, actions_history = list)
    cpdef DoubleArray rover_evals(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done):
        cdef State starting_state
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

        starting_state = state_history[0]
        n_rovers = len(starting_state.rover_data())
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

@cython.warn.undeclared(True)
cdef DefaultEvaluator new_DefaultEvaluator():
    cdef DefaultEvaluator evaluator

    evaluator = DefaultEvaluator.__new__(DefaultEvaluator)
    init_DefaultEvaluator(evaluator)

    return evaluator

@cython.warn.undeclared(True)
cdef void init_DefaultEvaluator(DefaultEvaluator evaluator) except *:
    if evaluator is None:
        raise TypeError("The evaluator (evaluator) cannot be None.")

    evaluator.__capture_dist = 1.
    evaluator.__n_req = 1

@cython.warn.undeclared(True)
@cython.locals(rover_data = list)
cpdef double step_eval_from_poi_for_DefaultEvaluator(
        DefaultEvaluator evaluator,
        PoiDatum poi_datum,
        rover_data: Sequence[RoverDatum]
        ) except *:
    cdef double displ_x, displ_y
    cdef double sqr_dist
    cdef double capture_dist
    cdef RoverDatum rover_datum
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t n_req
    cdef Py_ssize_t n_rovers_at_poi
    cdef bint poi_is_captured

    capture_dist = evaluator.capture_dist()
    n_req = evaluator.n_req()

    n_rovers = len(rover_data)

    # If there isn't enough rovers to satify the coupling constraint
    # (n_req), then return 0.
    if n_req > n_rovers:
        return 0.

    poi_is_captured = False
    n_rovers_at_poi = 0

    # See if the rovers capture the POIs if the number of rovers at the POI
    # (n_rovers_at_poi) is greater than or equal to the number of rovers
    # required to capture the POI (n_req).
    for rover_datum in rover_data:
        displ_x = rover_datum.position_x() - poi_datum.position_x()
        displ_y = rover_datum.position_y() - poi_datum.position_y()
        sqr_dist = displ_x*displ_x + displ_y*displ_y

        if sqr_dist <= capture_dist * capture_dist:
            n_rovers_at_poi += 1

        if n_rovers_at_poi >= n_req:
            poi_is_captured = True
            break

    if poi_is_captured:
        return poi_datum.value()
    else:
        return 0.



@cython.warn.undeclared(True)
@cython.locals(rover_data =list)
cpdef double cfact_step_eval_from_poi_for_DifferenceEvaluator(
        DifferenceEvaluator evaluator,
        PoiDatum poi_datum,
        rover_data: Sequence[RoverDatum],
        Py_ssize_t factual_rover_id
        )  except *:
    cdef double displ_x, displ_y
    cdef double sqr_dist
    cdef double capture_dist
    cdef RoverDatum rover_datum
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t n_req
    cdef Py_ssize_t n_rovers_at_poi
    cdef Py_ssize_t other_rover_id
    cdef bint poi_is_captured

    capture_dist = evaluator.capture_dist()
    n_req = evaluator.n_req()

    n_rovers = len(rover_data)

    # If there isn't enough rovers to satify the coupling constraint
    # (n_req), then return 0.
    if n_req > n_rovers:
        return 0.

    poi_is_captured = False
    n_rovers_at_poi = 0

    # See if the rovers capture the POIs if the number of rovers at the POI
    # (n_rovers_at_poi) is greater than or equal to the number of rovers
    # required to capture the POI (n_req).
    other_rover_id = 0
    for rover_datum in rover_data:
        if other_rover_id != factual_rover_id:
            displ_x = rover_datum.position_x() - poi_datum.position_x()
            displ_y = rover_datum.position_y() - poi_datum.position_y()
            sqr_dist = displ_x*displ_x + displ_y*displ_y

            if sqr_dist <= capture_dist * capture_dist:
                n_rovers_at_poi += 1

            if n_rovers_at_poi >= n_req:
                poi_is_captured = True
                break
        other_rover_id += 1

    if poi_is_captured:
        return poi_datum.value()
    else:
        return 0.

@cython.warn.undeclared(True)
cdef DifferenceEvaluator new_DifferenceEvaluator():
    cdef DifferenceEvaluator evaluator

    evaluator = DifferenceEvaluator.__new__(DifferenceEvaluator)
    init_DifferenceEvaluator(evaluator)

    return evaluator

@cython.warn.undeclared(True)
cdef void init_DifferenceEvaluator(DifferenceEvaluator evaluator) except *:
    init_DefaultEvaluator(evaluator)

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DifferenceEvaluator(DefaultEvaluator):
    def __init__(self):
        init_DifferenceEvaluator(self)

    cpdef DifferenceEvaluator copy(self, copy_obj = None):
        cdef DifferenceEvaluator new_evaluator

        if copy_obj is None:
            new_evaluator = DifferenceEvaluator.__new__(DifferenceEvaluator)
        else:
            new_evaluator = copy_obj

        DefaultEvaluator.copy(self, new_evaluator)

        return new_evaluator

    @cython.locals(state_history = list, actions_history = list)
    cpdef double cfact_eval(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done,
            Py_ssize_t factual_rover_id
            ) except *:
        """
        Returns counterfactual evaluation (cfact: evaluation without excluded
        rover contribution).
        """

        cdef State state
        cdef PoiDatum poi_datum
        cdef Py_ssize_t poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef double cfact_eval
        cdef DoubleArray sub_evals_given_poi

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        ensure_consistent_n_rovers_in_state_history(state_history)
        ensure_consistent_n_pois_in_state_history(state_history)

        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = state_history[0]
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
        for state in state_history:
            # Keep best step evalualtion for each poi
            for poi_id in range(n_pois):
                poi_datum = state.poi_data()[poi_id]
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        cfact_step_eval_from_poi_for_DifferenceEvaluator(
                            self,
                            poi_datum,
                            state.rover_data(),
                            factual_rover_id)))

        # Set evaluation to the sum of all POI-specific evaluations
        for poi_id in range(n_pois):
            cfact_eval += sub_evals_given_poi.view[poi_id]

        return cfact_eval

    @cython.locals(state_history=list, actions_history=list)
    cpdef DoubleArray rover_evals(
            self,
            state_history: Sequence[State],
            actions_history: Sequence[Sequence[DoubleArray]],
            bint episode_is_done):

        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        cdef DoubleArray rover_evals
        cdef State starting_state
        cdef RoverDatum factual_rover_datum


        if len(state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        starting_state = state_history[0]
        n_rovers = len(starting_state.rover_data())
        rover_evals = new_DoubleArray(n_rovers)

        rover_evals.set_all_to(
            self.eval(
                state_history,
                actions_history,
                episode_is_done))

        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            factual_rover_datum = starting_state.rover_data()[rover_id]
            rover_evals.view[rover_id] -= (
                self.cfact_eval(
                    state_history,
                    actions_history,
                    episode_is_done,
                    rover_id))

        return rover_evals




