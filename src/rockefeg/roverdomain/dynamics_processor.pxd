cdef class BaseDynamicsProcessor:
    cpdef copy(self, copy_obj = ?)

    cpdef void process_state(self, state, actions) except *


cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    pass

cdef DefaultDynamicsProcessor new_DefaultDynamicsProcessor()
cdef void init_DefaultDynamicsProcessor(
    DefaultDynamicsProcessor processor
    ) except *