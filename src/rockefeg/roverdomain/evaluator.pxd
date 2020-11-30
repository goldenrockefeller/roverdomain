# distutils: language = c++

from rockefeg.cyutil.typed_list cimport BaseReadableTypedList
from rockefeg.cyutil.array cimport DoubleArray
from .state cimport State, RoverDatum, PoiDatum

cpdef void ensure_consistent_n_rovers_in_state_history(
    BaseReadableTypedList state_history
    ) except *

cpdef void ensure_consistent_n_pois_in_state_history(
    BaseReadableTypedList state_history
    ) except *

cdef class BaseEvaluator:
    cpdef BaseEvaluator copy(self, copy_obj = ?)

    cpdef double eval(
        self,
        BaseReadableTypedList state_history,
        BaseReadableTypedList actions_history,
        bint episode_is_done
        ) except *

    cpdef DoubleArray rover_evals(
        self,
        BaseReadableTypedList state_history,
        BaseReadableTypedList actions_history,
        bint episode_is_done)
    # DoubleArray[n_rovers]

cdef class DefaultEvaluator(BaseEvaluator):
    cdef double __capture_dist
    cdef Py_ssize_t __n_req

    cpdef DefaultEvaluator copy(self, copy_obj = ?)

    cpdef Py_ssize_t n_req(self) except *
    cpdef void set_n_req(self, Py_ssize_t n_req) except *

    cpdef double capture_dist(self) except *
    cpdef void set_capture_dist(self, double capture_dist) except *

cdef DefaultEvaluator new_DefaultEvaluator()
cdef void init_DefaultEvaluator(
    DefaultEvaluator evaluator
    ) except *

cpdef double step_eval_from_poi_for_DefaultEvaluator(
    DefaultEvaluator evaluator,
    PoiDatum poi_datum,
    BaseReadableTypedList rover_data
    ) except *

cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef DifferenceEvaluator copy(self, copy_obj = ?)

    cpdef double cfact_eval(
        self,
        BaseReadableTypedList state_history,
        BaseReadableTypedList actions_history,
        bint episode_is_done,
        RoverDatum factual_rover_datum
        ) except *

cdef DifferenceEvaluator new_DifferenceEvaluator()
cdef void init_DifferenceEvaluator(
    DifferenceEvaluator evaluator
    ) except *

cpdef double cfact_step_eval_from_poi_for_DifferenceEvaluator(
    DifferenceEvaluator evaluator,
    PoiDatum poi_datum,
    BaseReadableTypedList rover_data,
    RoverDatum factual_rover_datum
    )  except *

