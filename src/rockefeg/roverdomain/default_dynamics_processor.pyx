from libc cimport math as cmath
cimport cython
import numpy as np
import inspect

@cython.warn.undeclared(True)
cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    
    def __init__(self):
        self.r_rover_positions = None
        self.r_rover_orientations = None
        
    cpdef object copy(self, object store):
        cdef DefaultDynamicsProcessor new_processor
        cdef object store_type
        
        if store is None or store is ...:
            new_processor = DefaultDynamicsProcessor()
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))
        else:
            new_processor = <DefaultDynamicsProcessor?> store
        
        return new_processor
        
    cpdef State next_state(
            self, 
            State state, 
            DoubleArray2 rover_actions,
            object store):
        cdef Py_ssize_t rover_id, n_rovers
        cdef State next_state
        cdef double dx, dy, norm, clipped_action_x, clipped_action_y
        
        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))    
        
        if rover_actions is None:
            raise (
                TypeError(
                    "(rover_actions) can not be None"))    
        
        n_rovers = state.n_rovers()            
        
        self.r_rover_orientations = (
            state.rover_orientations(self.r_rover_orientations)) # store
                
        self.r_rover_positions = (
            state.rover_positions(self.r_rover_positions)) # store
        
        # Translate and Reorient all rovers based on their actions
        for rover_id in range(n_rovers):
            
            # clip actions
            clipped_action_x = min(max(-1, rover_actions.view[rover_id, 0]), 1)
            clipped_action_y = min(max(-1, rover_actions.view[rover_id, 1]), 1)
    
            # turn action into global frame motion
            dx = (self.r_rover_orientations.view[rover_id, 0]
                * clipped_action_x
                - self.r_rover_orientations.view[rover_id, 1] 
                * clipped_action_y)
            dy = (self.r_rover_orientations.view[rover_id, 0] 
                * clipped_action_y
                + self.r_rover_orientations.view[rover_id, 1] 
                * clipped_action_x)
            
            # globally move and reorient agent
            self.r_rover_positions.view[rover_id, 0] += dx
            self.r_rover_positions.view[rover_id, 1] += dy
            
            
            # Reorient agent in the direction of movement in
            # the global frame.  Avoid divide by 0
            # (by skipping the reorientation step entirely).
            if not (dx == 0. and dy == 0.): 
                norm = cmath.sqrt(dx*dx +  dy*dy)
                self.r_rover_orientations.view[rover_id, 0] = dx / norm
                self.r_rover_orientations.view[rover_id, 1] = dy / norm
            else:
                self.r_rover_orientations.view[rover_id, 0] = 1.0
                self.r_rover_orientations.view[rover_id, 1] = 0.0
        
        next_state = state.copy(store)
        next_state.set_rover_positions(self.r_rover_positions)
        next_state.set_rover_orientations(self.r_rover_orientations)
        
        return next_state
    

    

        


        