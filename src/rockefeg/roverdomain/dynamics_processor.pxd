from .state cimport State
from rockefeg.cyutil.typed_list cimport BaseReadableTypedList

cdef class BaseDynamicsProcessor:
    cpdef BaseDynamicsProcessor copy(self, copy_obj = ?)

    cpdef void process_state(
        self,
        State state,
        BaseReadableTypedList actions
        ) except *


cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    cpdef DefaultDynamicsProcessor copy(self, copy_obj = ?)

cdef DefaultDynamicsProcessor new_DefaultDynamicsProcessor()
cdef void init_DefaultDynamicsProcessor(
    DefaultDynamicsProcessor processor
    ) except *