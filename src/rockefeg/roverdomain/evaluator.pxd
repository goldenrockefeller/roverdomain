# distutils: language = c++

from .history cimport StateHistory, ActionsHistory
from rockefeg.cyutil.array cimport DoubleArray
from .state cimport State

cdef class BaseEvaluator:
    cpdef object copy(self, object copy_obj = ?)

    cpdef double eval(
        self,
        StateHistory state_history,
        ActionsHistory actions_history,
        bint episode_is_done
        ) except *

    cpdef DoubleArray rover_evals(
        self,
        StateHistory state_history,
        ActionsHistory actions_history,
        bint episode_is_done)
    # DoubleArray[n_rovers]



cdef DefaultEvaluator new_DefaultEvaluator()
cdef void init_DefaultEvaluator(
    DefaultEvaluator evaluator
    ) except *

cdef class DefaultEvaluator(BaseEvaluator):
    cdef double __capture_dist
    cdef Py_ssize_t __n_req

    cpdef void check_state_history(self, StateHistory state_history) except *

    cpdef double step_eval_from_poi(
        self,
        State state,
        Py_ssize_t poi_id
        ) except *


    cpdef Py_ssize_t n_req(self) except *
    cpdef void set_n_req(self, Py_ssize_t n_req) except *

    cpdef double capture_dist(self) except *
    cpdef void set_capture_dist(self, double capture_dist) except *

cdef DifferenceEvaluator new_DifferenceEvaluator()
cdef void init_DifferenceEvaluator(
    DifferenceEvaluator evaluator
    ) except *

cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef double cfact_step_eval_from_poi(
        self,
        State state,
        Py_ssize_t excluded_rover_id,
        Py_ssize_t poi_id
        )  except *


    cpdef double cfact_eval(
        self,
        StateHistory state_history,
        ActionsHistory actions_history,
        bint episode_is_done,
        Py_ssize_t excluded_rover_id
        ) except *

