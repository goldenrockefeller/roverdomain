from .state cimport State
import cython

cdef class BaseDynamicsProcessor:
    cpdef BaseDynamicsProcessor copy(self, copy_obj = ?)

    @cython.locals(actions=list)
    cpdef void process_state(
        self,
        State state,
        actions: Sequence[DoubleArray]
        ) except *


cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    cpdef DefaultDynamicsProcessor copy(self, copy_obj = ?)

cdef DefaultDynamicsProcessor new_DefaultDynamicsProcessor()
cdef void init_DefaultDynamicsProcessor(
    DefaultDynamicsProcessor processor
    ) except *