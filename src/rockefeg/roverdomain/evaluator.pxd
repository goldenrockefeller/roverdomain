# distutils: language = c++

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



cdef DefaultEvaluator new_DefaultEvaluator()
cdef void init_DefaultEvaluator(
    DefaultEvaluator evaluator
    ) except *

cdef class DefaultEvaluator(BaseEvaluator):
    cdef double __capture_dist
    cdef Py_ssize_t __n_req

    cpdef void check_state_history(self, state_history) except *

    cpdef double step_eval_from_poi(
        self,
        state,
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
        state,
        Py_ssize_t excluded_rover_id,
        Py_ssize_t poi_id
        )  except *


    cpdef double cfact_eval(
        self,
        state_history,
        actions_history,
        bint episode_is_done,
        Py_ssize_t excluded_rover_id
        ) except *

