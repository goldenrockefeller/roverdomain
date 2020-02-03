from libc cimport math as cmath
cimport cython
import numpy as np
import inspect

@cython.warn.undeclared(True)
cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
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
    
    cpdef State next_state_copy(
            self, 
            State state, 
            const double[:, :] rover_actions):
        cdef State next_state
        next_state = <State?> state.copy()
        return self.next_state_via(next_state, state, rover_actions)
        
    cpdef State next_state_via(
            self, 
            State store, 
            State state, 
            const double[:, :] rover_actions):
        cdef Py_ssize_t rover_id, n_rovers
        cdef double dx, dy, norm, clipped_action_x, clipped_action_y
        cdef double[:, :] rover_orientations
        cdef double[:, :] rover_positions
        
        store = <State?> state.copy_via(store)
        
        n_rovers = store.n_rovers()            
        
        try:
            rover_orientations = (
                store.rover_orientations_via(self.r_rover_orientations_store))
        except:
            self.r_rover_orientations_store = store.rover_orientations_copy()
            rover_orientations = self.r_rover_orientations_store
        
        try:
            rover_positions = (
                store.rover_positions_via(self.r_rover_positions))
        except:
            self.r_rover_positions_store = store.rover_positions_copy()
            rover_positions = self.r_rover_positions_store
            
        
        
        # Translate and Reorient all rovers based on their actions
        for rover_id in range(n_rovers):
            
            # clip actions
            clipped_action_x = min(max(-1, rover_actions[rover_id, 0]), 1)
            clipped_action_y = min(max(-1, rover_actions[rover_id, 1]), 1)
    
            # turn action into global frame motion
            dx = (rover_orientations[rover_id, 0]
                * clipped_action_x
                - rover_orientations[rover_id, 1] 
                * clipped_action_y)
            dy = (rover_orientations[rover_id, 0] 
                * clipped_action_y
                + rover_orientations[rover_id, 1] 
                * clipped_action_x)
            
            # globally move and reorient agent
            rover_positions[rover_id, 0] += dx
            rover_positions[rover_id, 1] += dy
            
            
            # Reorient agent in the direction of movement in
            # the global frame.  Avoid divide by 0
            # (by skipping the reorientation step entirely).
            if not (dx == 0. and dy == 0.): 
                norm = cmath.sqrt(dx*dx +  dy*dy)
                rover_orientations[rover_id, 0] = dx / norm
                rover_orientations[rover_id, 1] = dy / norm
        
        store.set_rover_positions(rover_positions)
        store.set_rover_orientations(rover_orientations)
        return store
        
    cpdef object copy(self):
        return DefaultDynamicsProcessor()
    
    cpdef object copy_via(self, object store):
        cdef DefaultDynamicsProcessor new_processor
        cdef object store_type
        cdef object self_type
        
    
        if type(store) is not type(self):
            store_type = type(store)
            self_type = type(self)
            raise TypeError(
                "The type of the storage parameter "
                "(type(store) = {store_type}) must be exactly {self_type}."
                .format(**locals()))
        
        new_processor = <DefaultDynamicsProcessor?> store
        
        return new_processor
    

        


        