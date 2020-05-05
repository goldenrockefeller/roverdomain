# distutils: language = c++

cpdef void ensure_state_history_is_not_empty(state_history) except *
cpdef void ensure_consistent_n_rovers_in_state_history(state_history) except *
cpdef void ensure_consistent_n_pois_in_state_history(state_history) except *

cdef class BaseEvaluator:
    cpdef copy(self, copy_obj = ?)

    cpdef double eval(
        self,
        state_history,
        actions_history,
        bint episode_is_done
        ) except *

    cpdef rover_evals(
        self,
        state_history,
        actions_history,
        bint episode_is_done)
    # DoubleArray[n_rovers]




cdef class DefaultEvaluator(BaseEvaluator):
    cdef double __capture_dist
    cdef Py_ssize_t __n_req

    cpdef Py_ssize_t n_req(self) except *
    cpdef void set_n_req(self, Py_ssize_t n_req) except *

    cpdef double capture_dist(self) except *
    cpdef void set_capture_dist(self, double capture_dist) except *

cdef DefaultEvaluator new_DefaultEvaluator()
cdef void init_DefaultEvaluator(
    DefaultEvaluator evaluator
    ) except *

cpdef double step_eval_from_poi_for_DefaultEvaluator(
    evaluator,
    state,
    Py_ssize_t poi_id
    ) except *

cdef class DifferenceEvaluator(DefaultEvaluator):
    cpdef double cfact_eval(
        self,
        state_history,
        actions_history,
        bint episode_is_done,
        Py_ssize_t excluded_rover_id
        ) except *

cdef DifferenceEvaluator new_DifferenceEvaluator()
cdef void init_DifferenceEvaluator(
    DifferenceEvaluator evaluator
    ) except *

cpdef double cfact_step_eval_from_poi_for_DifferenceEvaluator(
    evaluator,
    state,
    Py_ssize_t excluded_rover_id,
    Py_ssize_t poi_id
    )  except *

