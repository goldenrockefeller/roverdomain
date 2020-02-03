from libc cimport math as cmath
import numpy as np
import inspect

cimport cython

@cython.warn.undeclared(True)
cdef class State:
    @cython.warn.undeclared(False)
    def __init__(self):
        n_rovers = 1
        n_pois = 1
        
        self.m_n_rovers = n_rovers
        self.m_n_pois = n_pois
        self.m_rover_positions = np.zeros((n_rovers, 2))
        self.m_rover_orientations = np.zeros((n_rovers, 2)) 
        self.m_rover_orientations[:, 0] = 1.
        self.m_poi_positions = np.zeros((n_pois, 2))
        self.m_poi_values = np.zeros(n_pois)
        
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

    cpdef Py_ssize_t n_rovers(self) except *:
        return self.m_n_rovers
        
        
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *:
        if n_rovers < 0:
            raise ValueError(
                "The number of rovers (n_rovers = {n_rovers}) must be "
                "non-negative. "
                .format(**locals()))
            
        if self.m_n_rovers != n_rovers:
            self.m_n_rovers = n_rovers
            self.m_rover_positions = np.zeros((n_rovers, 2))
            self.m_rover_orientations = np.zeros((n_rovers, 2)) 
            self.m_rover_orientations[:, 0] = 1.
        
    cpdef Py_ssize_t n_pois(self) except *:
        return self.m_n_pois
        
    cpdef void set_n_pois(self, Py_ssize_t n_pois) except *:
        if n_pois < 0:
            raise ValueError(
                "The number of POIs (n_pois = {n_pois}) must be non-negative. "
                .format(**locals()))
                
        if self.m_n_pois != n_pois:
            self.m_n_pois = n_pois
            self.m_poi_positions = np.zeros((n_pois, 2))
            self.m_poi_values = np.zeros(n_pois)

   
    cpdef double[:, :] rover_positions_copy(self) except *:
        cdef double[:, :] rover_positions
        
        rover_positions = np.zeros((self.n_rovers(), 2))
        return self.rover_positions_via(rover_positions)
        
    cpdef double[:, :] rover_positions_via(self, double[:, :] store) except *: 
        cdef double[:, :] rover_positions
        
        rover_positions = store[:self.n_rovers(), :2]
        rover_positions[...] = self.m_rover_positions
        return rover_positions
        
    cpdef void set_rover_positions(
            self, 
            const double[:, :] rover_positions
            ) except * :
        self.m_rover_positions[...] = rover_positions    
        
        
    cpdef double[:, :] rover_orientations_copy(self) except *:
        cdef double[:, :] rover_orientations
        
        rover_orientations = np.zeros((self.n_rovers(), 2))
        return self.rover_orientations_via(rover_orientations)
        
    cpdef double[:, :] rover_orientations_via(
            self, 
            double[:, :] store
            ) except *: 
        cdef double[:, :] rover_orientations
        
        rover_orientations = store[:self.n_rovers(), :2]
        rover_orientations[...] = self.m_rover_orientations
        return rover_orientations
        
    cpdef void set_rover_orientations(
            self, 
            const double[:, :] rover_orientations
            ) except * :
        cdef double x, y, norm
        cdef Py_ssize_t n_rovers, rover_id 
        
        n_rovers = self.n_rovers()
    
        # Set normalized orientation. 
        for rover_id in range(n_rovers):
            x = rover_orientations[rover_id, 0]
            y = rover_orientations[rover_id, 1]
            norm = cmath.sqrt(x*x +  y*y)
            if norm != 0.:
                self.m_rover_orientations[rover_id, 0] = x/norm
                self.m_rover_orientations[rover_id, 1] = y/norm
            else:
                self.m_rover_orientations[rover_id, 0] = 1.
                self.m_rover_orientations[rover_id, 1] = 0.
        self.m_rover_orientations[...] = rover_orientations    
        
     
    cpdef double[:] poi_values_copy(self) except *:
        cdef double[:] poi_values 
        
        poi_values = np.zeros(self.n_pois())
        return self.poi_values_via(poi_values)
        
        
    cpdef double[:] poi_values_via(self, double[:] store) except *:
        cdef double[:] poi_values 
        
        poi_values = store[:self.n_pois()]
        poi_values[...] = self.m_poi_values
        return poi_values
        
    cpdef void set_poi_values(self, const double[:] poi_values) except *:
        self.m_poi_values[...] = poi_values
    
    
    cpdef double[:, :] poi_positions_copy(self) except *:
        cdef double[:, :] poi_positions
        
        poi_positions = np.zeros((self.n_pois(), 2))
        return self.poi_positions_via(poi_positions)
        
    cpdef double[:, :] poi_positions_via(self, double[:, :] store) except *: 
        cdef double[:, :] poi_positions
        
        poi_positions = store[:self.n_pois(), :2]
        poi_positions[...] = self.m_poi_positions
        return poi_positions
        
    cpdef void set_poi_positions(
            self, 
            const double[:, :] poi_positions
            ) except * :
        self.m_poi_positions[...] = poi_positions    

    cpdef object copy_via(self, object store):
        cdef State new_state
        cdef object store_type
        cdef object self_type
        
        if type(store) is not type(self):
            store_type = type(store)
            self_type = type(self)
            raise TypeError(
                "The type of the storage parameter "
                "(type(store) = {store_type}) must be exactly {self_type}."
                .format(**locals()))
        
        new_state = <State?> store
        
        new_state.m_n_rovers = self.m_n_rovers
        new_state.m_n_pois = self.m_n_pois
        new_state.m_rover_positions[...] = self.m_rover_positions
        new_state.m_rover_orientations[...] = self.m_rover_orientations
        new_state.m_poi_positions[...] = self.m_poi_positions
        new_state.m_poi_values[...] = self.m_poi_values
        
        return new_state
        
    
    cpdef object copy(self):
        cdef State new_state
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        
        n_rovers = self.n_rovers()
        n_pois = self.n_pois()
        
        new_state = State()
        new_state.m_rover_positions = np.zeros((n_rovers, 2))
        new_state.m_rover_orientations = np.zeros((n_rovers, 2)) 
        new_state.m_poi_positions = np.zeros((n_pois, 2))
        new_state.m_poi_values = np.zeros(n_pois)
        return self.copy_via(new_state)
        
        
        