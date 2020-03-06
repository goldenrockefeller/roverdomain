from libc cimport math as cmath
cimport cython
import numpy as np
import inspect

@cython.warn.undeclared(True)
cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    
    def __init__(self):
        self.r_rover_positions = DoubleArray2(None)
        self.r_rover_orientations = DoubleArray2(None)
        
        self.o_next_state = State()
        
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef DefaultDynamicsProcessor other
        cdef object other_type
        
        if index is not ...:
            raise TypeError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = DefaultDynamicsProcessor()  
        elif type(obj) is type(self):
            other = <DefaultDynamicsProcessor?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, or None"
                    .format(**locals())))
            
        other.copy_to(self)
            
    cpdef object copy_to(self, object obj):
        cdef DefaultDynamicsProcessor other
        cdef object other_type
        
        if obj is None:        
            other = DefaultDynamicsProcessor()
        elif type(obj) is type(self):
            other = <DefaultDynamicsProcessor?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, None"
                    .format(**locals())))
                
        return other
        
    cpdef State next_state(
            self, 
            State state, 
            DoubleArray2 rover_actions):
        cdef Py_ssize_t rover_id, n_rovers
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
        
        if rover_actions.view.shape[0] != n_rovers:
            raise (
                TypeError(
                    "Can not accept (rover_actions) shape"
                    "(rover_actions.view.shape = "
                    "{rover_actions.view.shape}) "
                    "if rover_actions.view.shape[0] != "
                    "the number of rovers "
                    "(state.n_rovers()  = {n_rovers})."
                    .format(**locals())))  
                    
        if rover_actions.view.shape[1] != 2:
            raise (
                TypeError(
                    "Can not accept (rover_actions) shape"
                    "(rover_actions.view.shape = "
                    "{rover_actions.view.shape}) "
                    "if rover_actions.view.shape[1] != 2"
                    .format(**locals())))  
        
        self.r_rover_orientations[...] = state.rover_orientations()
        self.r_rover_positions[...] = state.rover_positions()
        
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
        
        try:
            self.o_next_state[...] = state
        except (TypeError, NotImplementedError):
            self.o_next_state = state.copy()
            
        self.o_next_state.set_rover_positions(self.r_rover_positions)
        self.o_next_state.set_rover_orientations(self.r_rover_orientations)
        
        return self.o_next_state
    

    

        


        