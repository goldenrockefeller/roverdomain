# distutils: language = c++
# cython: language_level=3

from .state cimport State
from .base_evaluator cimport BaseEvaluator
from libcpp.vector cimport vector

from .base_evaluator cimport BaseEvaluator

from rockefeg.ndarray.double_array_1 cimport DoubleArray1
from rockefeg.ndarray.double_array_2 cimport DoubleArray2
from rockefeg.ndarray.object_array_1 cimport ObjectArray1


cdef class DefaultEvaluator(BaseEvaluator):
    cdef public double m_capture_dist
    cdef public Py_ssize_t m_n_req
    
    cdef vector[double] r_sqr_rover_dists_to_poi
    cdef DoubleArray1 r_sub_evals_given_poi
    
    cdef DoubleArray1 o_rover_evals
    
    
    cpdef Py_ssize_t n_req(self) except *
    cpdef void set_n_req(self, Py_ssize_t n_req) except *
    
    cpdef double capture_dist(self) except *
    cpdef void set_capture_dist(self, double capture_dist) except *
    
    cpdef void check_state_history(self, ObjectArray1 state_history) except *
    
    cpdef double step_eval_from_poi(
        self, 
        State state, 
        Py_ssize_t poi_id
        ) except *



        
    