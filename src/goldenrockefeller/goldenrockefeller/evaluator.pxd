# distutils: language = c++
import cython

from rockefeg.cyutil.array cimport DoubleArray
from .state cimport State, RoverDatum, PoiDatum

@cython.locals(state_history=list)
cpdef void ensure_consistent_n_rovers_in_state_history(
    state_history: Sequence[State]
    ) except *

@cython.locals(state_history=list)
cpdef void ensure_consistent_n_pois_in_state_history(
    state_history: Sequence[State]
    ) except *

cdef class BaseEvaluator:
    cpdef BaseEvaluator copy(self, copy_obj = ?)

    @cython.locals(state_history = list, actions_history = list)
    cpdef double eval(
        self,
        state_history: Sequence[State],
        actions_history: Seqence[Sequence[DoubleArray]],
        bint episode_is_done
        ) except *

    @cython.locals(state_history = list, actions_history = list)
    cpdef DoubleArray rover_evals(
        self,
        state_history: Sequence[State],
        actions_history: Seqence[Sequence[DoubleArray]],
        bint episode_is_done)

cdef class DefaultEvaluator(BaseEvaluator):
    cdef double _capture_dist
    cdef Py_ssize_t _n_req

    cpdef DefaultEvaluator copy(self, copy_obj = ?)

    cpdef Py_ssize_t n_req(self) except *
    cpdef void set_n_req(self, Py_ssize_t n_req) except *

    cpdef double capture_dist(self) except *
    cpdef void set_capture_dist(self, double capture_dist) except *

cdef DefaultEvaluator new_DefaultEvaluator()
cdef void init_DefaultEvaluator(
    DefaultEvaluator evaluator
    ) except *

@cython.locals(rover_data = list)
cpdef double step_eval_from_poi_for_DefaultEvaluator(
    DefaultEvaluator evaluator,
    PoiDatum poi_datum,
    rover_data: Sequence[RoverDatum]
    ) except *

cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef DifferenceEvaluator copy(self, copy_obj = ?)

    @cython.locals(state_history = list, actions_history = list)
    cpdef double cfact_eval(
        self,
        state_history: Sequence[State],
        actions_history: Sequence[Sequence[DoubleArray]],
        bint episode_is_done,
        Py_ssize_t factual_rover_id
        ) except *

cdef DifferenceEvaluator new_DifferenceEvaluator()
cdef void init_DifferenceEvaluator(
    DifferenceEvaluator evaluator
    ) except *

@cython.locals(rover_data = list)
cpdef double cfact_step_eval_from_poi_for_DifferenceEvaluator(
    DifferenceEvaluator evaluator,
    PoiDatum poi_datum,
    rover_data: Sequence[RoverDatum],
    Py_ssize_t factual_rover_id
    )  except *

