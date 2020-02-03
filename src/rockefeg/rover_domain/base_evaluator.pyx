cimport cython

@cython.auto_pickle(True)
cdef class BaseEvaluator:
    cpdef double eval(
            self,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint domain_is_done
            ) except *:
        raise NotImplementedError()
            
    cpdef double[:] rover_evals_copy(
            self,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint domain_is_done
            ) except *:
        raise NotImplementedError()
        
    cpdef double[:] rover_evals_via(
            self,
            double[:] store,
            object[:] state_history,
            const double[:, :, :] rover_actions_history, 
            bint domain_is_done
            ) except *:
        raise NotImplementedError()
        
    cpdef object copy(self):
        raise NotImplementedError()
        
    cpdef object copy_via(self, object store):
        raise NotImplementedError()