from libc cimport math as cmath
cimport cython
import numpy as np
import inspect

@cython.warn.undeclared(True)
cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    @cython.warn.undeclared(False)
    def __init__(self):
        self.r_rover_positions = None
        self.r_rover_orientations = None
    
    @cython.warn.undeclared(False)     
    def __setstate__(self, state):
        
        for attr in state.keys():
            try:
                self.__setattr__(attr, state[attr])
            except AttributeError:
                pass

    @cython.warn.undeclared(False) 
    def __reduce__(self):
        cdef double[:] basic_memoryview = np.zeros(1)
        
        state = {}
        for attr in dir(self):
            try:
                val = self.__getattribute__(attr)
                if (
                        not (attr[:2] == "__" and attr[-2:] == "__")
                        and not inspect.isbuiltin(val)
                ):
                    if type(val) is type(basic_memoryview):
                        val = np.asarray(val)
                    state[attr] = val
            except AttributeError:
                pass

        return self.__class__, (),  state
    
    cpdef Py_ssize_t n_rover_action_dims(self) except *:
        return 2
        
    cpdef State next_state(
            self, 
            State state, 
            const double[:, :] rover_actions,
            State store = None):
        cdef Py_ssize_t rover_id, n_rovers
        cdef next_state
        cdef double dx, dy, norm, clipped_action_x, clipped_action_y
        
        next_state = <State?> state.copy(store = store)
        
        n_rovers = store.n_rovers()            
        
        self.r_rover_orientations = (
            next_state.rover_orientations(store = self.r_rover_orientations))
                
        self.r_rover_positions = (
            next_state.rover_positions(store = self.r_rover_positions))
        
        # Translate and Reorient all rovers based on their actions
        for rover_id in range(n_rovers):
            
            # clip actions
            clipped_action_x = min(max(-1, rover_actions[rover_id, 0]), 1)
            clipped_action_y = min(max(-1, rover_actions[rover_id, 1]), 1)
    
            # turn action into global frame motion
            dx = (self.r_rover_orientations[rover_id, 0]
                * clipped_action_x
                - self.r_rover_orientations[rover_id, 1] 
                * clipped_action_y)
            dy = (self.r_rover_orientations[rover_id, 0] 
                * clipped_action_y
                + self.r_rover_orientations[rover_id, 1] 
                * clipped_action_x)
            
            # globally move and reorient agent
            self.r_rover_positions[rover_id, 0] += dx
            self.r_rover_positions[rover_id, 1] += dy
            
            
            # Reorient agent in the direction of movement in
            # the global frame.  Avoid divide by 0
            # (by skipping the reorientation step entirely).
            if not (dx == 0. and dy == 0.): 
                norm = cmath.sqrt(dx*dx +  dy*dy)
                self.r_rover_orientations[rover_id, 0] = dx / norm
                self.r_rover_orientations[rover_id, 1] = dy / norm
        
        next_state.set_rover_positions(self.r_rover_positions)
        next_state.set_rover_orientations(self.rrover_orientations)
        return next_state
    
    cpdef object copy(self, object store = None):
        cdef DefaultDynamicsProcessor new_processor
        cdef object store_type
        cdef object self_type
        
        try:
            if type(store) is not type(self):
                store_type = type(store)
                self_type = type(self)
                raise TypeError(
                    "The type of the storage parameter "
                    "(type(store) = {store_type}) must be exactly {self_type}."
                    .format(**locals()))
            
            new_processor = <DefaultDynamicsProcessor?> store
        except:
            new_processor = DefaultDynamicsProcessor()
        
        return new_processor
    

        


        