# cython: language_level=3


from .state cimport State
from rockefeg.ndarray.double_array_2 cimport DoubleArray2

cdef class BaseDynamicsProcessor:
    cpdef State next_state(self, 
        State state, 
        DoubleArray2 rover_actions,
        object store) 
    # double[n_rovers, n_rover_action_dims]
    
    cpdef object copy(self, object store)