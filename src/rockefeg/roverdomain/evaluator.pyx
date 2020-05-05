cimport cython
from .state cimport State, RoverDatum, PoiDatum
from .history cimport StateHistory, ActionsHistory
from libc.math cimport INFINITY
from rockefeg.cyutil.array cimport DoubleArray, new_DoubleArray

@cython.warn.undeclared(True)
cpdef void ensure_state_history_is_not_empty(state_history) except *:
    cdef StateHistory cy_state_history = <StateHistory?> state_history
    if len(cy_state_history) == 0:
        raise (
            ValueError(
                "The length of the state history (len(state_history) = 0) "
                "must be positive." ))

@cython.warn.undeclared(True)
cpdef void ensure_consistent_n_rovers_in_state_history(state_history) except *:
    cdef StateHistory cy_state_history = <StateHistory?> state_history
    cdef State state
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t step_n_rovers

    if len(cy_state_history) == 0:
        return

    state = cy_state_history.entry(0)
    n_rovers = state.n_rovers()

    for state in cy_state_history.history_shallow_copy():
        step_n_rovers = state.n_rovers()

        if n_rovers != step_n_rovers:
            raise (
                ValueError(
                    "All states in the state history (state_history) must "
                    "have the same number of rovers. "
                    "(state_history.entry(0).n_rovers() "
                    "= {n_rovers}) and "
                    "(state_history.entry({step_id}).n_rovers() "
                    "= {step_n_rovers})."
                    .format(**locals())))

@cython.warn.undeclared(True)
cpdef void ensure_consistent_n_pois_in_state_history(state_history) except *:
    cdef StateHistory cy_state_history = <StateHistory?> state_history
    cdef State state
    cdef Py_ssize_t step_n_pois
    cdef Py_ssize_t n_pois

    if len(cy_state_history) == 0:
        return

    state = cy_state_history.entry(0)
    n_pois = state.n_pois()

    for state in cy_state_history.history_shallow_copy():
        step_n_pois = state.n_pois()

        if n_pois != step_n_pois:
            raise (
                ValueError(
                    "All states in the state history (state_history) must "
                    "have the same number of POIs. "
                    "(state_history.entry(0).n_pois() "
                    "= {n_pois}) and "
                    "(state_history.entry({step_id}).n_pois() "
                    "= {step_n_pois})."
                    .format(**locals())))

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef copy(self, copy_obj = None):
        raise NotImplementedError("Abstract method.")

    cpdef double eval(
            self,
            state_history,
            actions_history,
            bint episode_is_done
            ) except *:
        raise NotImplementedError("Abstract method.")

    cpdef rover_evals(
            self,
            state_history,
            actions_history,
            bint episode_is_done):
        raise NotImplementedError("Abstract method.")


@cython.warn.undeclared(True)
cpdef double step_eval_from_poi_for_DefaultEvaluator(
        evaluator,
        state,
        Py_ssize_t poi_id
        ) except *:
    cdef DefaultEvaluator cy_evaluator = <DefaultEvaluator?>evaluator
    cdef State cy_state = <State?>state
    cdef double displ_x, displ_y
    cdef double sqr_dist
    cdef double capture_dist
    cdef RoverDatum rover_datum
    cdef PoiDatum poi_datum
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t n_req
    cdef Py_ssize_t n_rovers_at_poi
    cdef bint poi_is_captured

    capture_dist = cy_evaluator.capture_dist()
    n_req = cy_evaluator.n_req()

    poi_datum = cy_state.poi_datum(poi_id)
    n_rovers = cy_state.n_rovers()

    # If there isn't enough rovers to satify the coupling constraint
    # (n_req), then return 0.
    if n_req > n_rovers:
        return 0.

    poi_is_captured = False
    n_rovers_at_poi = 0

    # See if the rovers capture the POIs if the number of rovers at the POI
    # (n_rovers_at_poi) is greater than or equal to the number of rovers
    # required to capture the POI (n_req).
    for rover_datum in cy_state.rover_data_shallow_copy():
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
@cython.auto_pickle(True)
cdef class DefaultEvaluator(BaseEvaluator):
    def __init__(self):
        init_DefaultEvaluator(self)

    cpdef object copy(self, object copy_obj = None):
        cdef DefaultEvaluator new_evaluator

        if copy_obj is None:
            new_evaluator = DefaultEvaluator.__new__(DefaultEvaluator)
        else:
            new_evaluator = copy_obj

        new_evaluator.__capture_dist = self.__capture_dist
        new_evaluator.__n_req = self.__n_req

        return new_evaluator

    cpdef double eval(
            self,
            state_history,
            actions_history,
            bint episode_is_done
            ) except *:
        cdef StateHistory cy_state_history
        cdef State state
        cdef Py_ssize_t step_id, poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t n_rovers
        cdef double eval
        cdef DoubleArray sub_evals_given_poi

        cy_state_history = state_history

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        ensure_state_history_is_not_empty(state_history)
        ensure_consistent_n_rovers_in_state_history(state_history)
        ensure_consistent_n_pois_in_state_history(state_history)

        if len(cy_state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = cy_state_history.entry(0)
        n_rovers = state.n_rovers()
        n_pois = state.n_pois()
        n_steps = len(cy_state_history)

        sub_evals_given_poi = new_DoubleArray(n_pois)
        sub_evals_given_poi.set_all_to(-INFINITY)

        # Initialize evaluations.
        eval = 0.

        # Get evaluation for poi, for each step, storing the max.
        for step_id in range(n_steps):
            state = cy_state_history.entry(step_id)
            # Keep best step evaluation for each poi.
            for poi_id in range(n_pois):
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        step_eval_from_poi_for_DefaultEvaluator(
                            self,
                            state,
                            poi_id)))

        # Set evaluation to the sum of all POI-specific evaluations.
        for poi_id in range(n_pois):
            eval += sub_evals_given_poi.view[poi_id]

        return eval


    cpdef rover_evals(
            self,
            state_history,
            actions_history,
            bint episode_is_done):
        cdef StateHistory cy_state_history
        cdef State state
        cdef Py_ssize_t n_rovers
        cdef DoubleArray rover_evals

        cy_state_history = state_history

        if cy_state_history is None:
            raise (
                TypeError(
                    "The state history (state_history) must not be None" ))

        if len(cy_state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = cy_state_history.entry(0)
        n_rovers = state.n_rovers()
        rover_evals = new_DoubleArray(n_rovers)

        rover_evals.set_all_to(
            self.eval(
                cy_state_history,
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
cpdef double cfact_step_eval_from_poi_for_DifferenceEvaluator(
        evaluator,
        state,
        Py_ssize_t excluded_rover_id,
        Py_ssize_t poi_id
        )  except *:
    cdef DefaultEvaluator cy_evaluator = <DifferenceEvaluator?>evaluator
    cdef State cy_state = <State?>state
    cdef double displ_x, displ_y
    cdef double sqr_dist
    cdef double capture_dist
    cdef RoverDatum rover_datum
    cdef RoverDatum excluded_rover_datum
    cdef PoiDatum poi_datum
    cdef Py_ssize_t n_rovers
    cdef Py_ssize_t n_req
    cdef Py_ssize_t n_rovers_at_poi
    cdef bint poi_is_captured

    capture_dist = cy_evaluator.capture_dist()
    n_req = cy_evaluator.n_req()

    poi_datum = cy_state.poi_datum(poi_id)
    excluded_rover_datum = cy_state.rover_datum(excluded_rover_id)
    n_rovers = cy_state.n_rovers()

    # If there isn't enough rovers to satify the coupling constraint
    # (n_req), then return 0.
    if n_req > n_rovers:
        return 0.

    poi_is_captured = False
    n_rovers_at_poi = 0

    # See if the rovers capture the POIs if the number of rovers at the POI
    # (n_rovers_at_poi) is greater than or equal to the number of rovers
    # required to capture the POI (n_req).
    for rover_datum in cy_state.rover_data_shallow_copy():
        if rover_datum is not excluded_rover_datum:
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

    cpdef double cfact_eval(
            self,
            state_history,
            actions_history,
            bint episode_is_done,
            Py_ssize_t excluded_rover_id
            ) except *:
        """
        Returns counterfactual evaluation (cfact: evaluation without excluded
        rover contribution).
        """
        cdef StateHistory cy_state_history = <StateHistory?> state_history

        cdef State state
        cdef Py_ssize_t poi_id
        cdef Py_ssize_t n_steps
        cdef Py_ssize_t n_pois
        cdef double cfact_eval
        cdef DoubleArray sub_evals_given_poi

        # Return reward only at the end of the episode
        if not episode_is_done:
            return 0.

        ensure_state_history_is_not_empty(state_history)
        ensure_consistent_n_rovers_in_state_history(state_history)
        ensure_consistent_n_pois_in_state_history(state_history)

        if len(cy_state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = cy_state_history.entry(0)
        n_pois = state.n_pois()
        n_steps = len(cy_state_history)

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
        for state in cy_state_history.history_shallow_copy():
            # Keep best step evalualtion for each poi
            for poi_id in range(n_pois):
                sub_evals_given_poi.view[poi_id] = (
                    max(
                        sub_evals_given_poi.view[poi_id],
                        cfact_step_eval_from_poi_for_DifferenceEvaluator(
                            self,
                            state,
                            excluded_rover_id,
                            poi_id)))

        # Set evaluation to the sum of all POI-specific evaluations
        for poi_id in range(n_pois):
            cfact_eval += sub_evals_given_poi.view[poi_id]

        return cfact_eval


    cpdef rover_evals(
            self,
            state_history,
            actions_history,
            bint episode_is_done):

        cdef StateHistory cy_state_history = <StateHistory?> state_history
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t rover_id
        cdef DoubleArray rover_evals
        cdef State state


        if len(cy_state_history) == 0:
            raise (
                ValueError(
                    "The length of the state history (len(state_history) = 0) "
                    "must be positive." ))

        state = cy_state_history.entry(0)
        n_rovers = state.n_rovers()
        rover_evals = new_DoubleArray(n_rovers)

        rover_evals.set_all_to(
            self.eval(
                cy_state_history,
                actions_history,
                episode_is_done))

        # Subtract counterfactual evalution to get difference evaluation.
        for rover_id in range(n_rovers):
            rover_evals.view[rover_id] -= (
                self.cfact_eval(
                    cy_state_history,
                    actions_history,
                    episode_is_done,
                    rover_id))

        return rover_evals




