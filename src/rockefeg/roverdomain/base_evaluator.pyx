cimport cython

@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef double eval(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done
            ) except *:
        raise NotImplementedError()
        
    cpdef DoubleArray1 rover_evals(
            self,
            ObjectArray1 state_history,
            ObjectArray1 rover_actions_history, 
            bint episode_is_done):
        raise NotImplementedError()
    
    cpdef object copy(self):
        raise NotImplementedError()
        
    cpdef object copy_to(self, object obj):
        raise NotImplementedError()