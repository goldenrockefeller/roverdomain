from .state cimport State

cdef class BaseDynamicsProcessor:
    cpdef object copy(self, object copy_obj = ?)

    cpdef void process_state(self, State state, list actions) except *
    # list<DoubleArray>[n_rovers][n_action_dims]

cdef DefaultDynamicsProcessor new_DefaultDynamicsProcessor()
cdef void init_DefaultDynamicsProcessor(
    DefaultDynamicsProcessor processor
    ) except *

cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    pass