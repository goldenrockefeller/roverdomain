cimport cython

@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef double eval(
            self,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint episode_is_done
            ) except *:
        raise NotImplementedError()
        
    cpdef double[:] rover_evals(
            self,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint episode_is_done,
            double[:] store = None
            ) except *:
        raise NotImplementedError()
    
    cpdef object copy(self, object store = None):
        raise NotImplementedError()