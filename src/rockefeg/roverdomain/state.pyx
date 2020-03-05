from libc cimport math as cmath
import numpy as np
import inspect

cimport cython

from rockefeg.ndarray.double_array_1 import DoubleArray1
from rockefeg.ndarray.double_array_2 import DoubleArray2

@cython.warn.undeclared(True)
cdef class State:
    def __init__(self):
        cdef Py_ssize_t n_rovers
        cdef Py_ssize_t n_pois
        cdef Py_ssize_t rover_id
        
        n_rovers = 1
        n_pois = 1
        
        self.m_n_rovers = n_rovers
        self.m_n_pois = n_pois
        self.m_rover_positions = DoubleArray2(np.zeros((n_rovers, 2)))
        self.m_rover_orientations = DoubleArray2(np.zeros((n_rovers, 2)))
        
        # Make orientations valid (i.e. magnitude = 1).
        for rover_id in range(n_rovers):
            self.m_rover_orientations[rover_id, 0] = 1.
            
        self.m_poi_positions = DoubleArray2(np.zeros((n_pois, 2)))
        self.m_poi_values = DoubleArray1(np.zeros(n_pois))
        
    cpdef object copy(self, object store):
        cdef State new_state
        cdef object store_type
        
        if store is None or store is ...:
            new_state = State()
        elif type(store) is not self.__class__:
            store_type = type(store)
            raise (
                TypeError(
                    "The type of the store object "
                    "(store_type = {store_type}) is not "
                    "{self.__class__}, None, or Ellipsis ('...')."
                    .format(**locals())))
        else:
            new_state = <State?> store
        
        new_state.m_rover_positions = (
            self.m_rover_positions.copy(
                new_state.m_rover_positions)) # store
            
        new_state.m_rover_orientations = (
            self.m_rover_orientations.copy(
                new_state.m_rover_orientations)) # store
                
        new_state.m_poi_positions = (
            self.m_poi_positions.copy(
                new_state.m_poi_positions)) # store
                
        new_state.m_poi_values = (
            self.m_poi_values.copy(
                new_state.m_poi_values)) # store
                
        new_state.m_n_rovers = self.m_n_rovers
        new_state.m_n_pois = self.m_n_pois
        
        return new_state
        
    cpdef Py_ssize_t n_rovers(self) except *:
        return self.m_n_rovers
        
        
    cpdef void set_n_rovers(self, Py_ssize_t n_rovers) except *:
        cdef Py_ssize_t rover_id
        
        if n_rovers < 0:
            raise ValueError(
                "The number of rovers (n_rovers = {n_rovers}) must be "
                "non-negative. "
                .format(**locals()))
            
        if self.m_n_rovers != n_rovers:
            self.m_n_rovers = n_rovers
            self.m_rover_positions.repurpose(n_rovers, 2)
            self.m_rover_positions.set_all_to(0.)
            
            self.m_rover_orientations.repurpose(n_rovers, 2)
            self.m_rover_orientations.set_all_to(0.) 
            
            # Make orientations valid (i.e. magnitude = 1).
            for rover_id in range(n_rovers):
                self.m_rover_orientations[rover_id, 0] = 1.
        
    cpdef Py_ssize_t n_pois(self) except *:
        return self.m_n_pois
        
    cpdef void set_n_pois(self, Py_ssize_t n_pois) except *:
        if n_pois < 0:
            raise ValueError(
                "The number of POIs (n_pois = {n_pois}) must be non-negative. "
                .format(**locals()))
                
        if self.m_n_pois != n_pois:
            self.m_n_pois = n_pois
            
            self.m_poi_position.repurpose(n_pois, 2)
            self.m_poi_position.set_all_to(0.) 
            
            self.m_poi_position.repurpose(n_pois)
            self.m_poi_position.set_all_to(0.) 
        
    cpdef DoubleArray2 rover_positions(self, object store): 
        return self.m_rover_positions.copy(store)
        
    cpdef void set_rover_positions(
            self, 
            DoubleArray2 rover_positions
            ) except * :
                
        if rover_positions is None:
            raise (
                TypeError(
                    "(rover_positions) can not be None"))        
                
        self.m_rover_positions = (
            rover_positions.copy(
                self.m_rover_positions)) # store
        
    cpdef DoubleArray2 rover_orientations(self, object store): 
        return self.m_rover_orientations.copy(store) 
        
    cpdef void set_rover_orientations(
            self, 
            DoubleArray2 rover_orientations
            ) except * :
        cdef double x, y, norm
        cdef Py_ssize_t n_rovers, rover_id 
        
        if rover_orientations is None:
            raise (
                TypeError(
                    "(rover_orientations) can not be None"))
        
        n_rovers = self.n_rovers()
    
        # Set normalized orientation. 
        for rover_id in range(n_rovers):
            x = rover_orientations.view[rover_id, 0]
            y = rover_orientations.view[rover_id, 1]
            norm = cmath.sqrt(x*x +  y*y)
            if norm != 0.:
                self.m_rover_orientations.view[rover_id, 0] = x/norm
                self.m_rover_orientations.view[rover_id, 1] = y/norm
            else:
                self.m_rover_orientations.view[rover_id, 0] = 1.
                self.m_rover_orientations.view[rover_id, 1] = 0.   
        
    
    cpdef DoubleArray1 poi_values(self, object store):
        return self.m_poi_values.copy(store)
        
    cpdef void set_poi_values(self, DoubleArray1 poi_values) except *:
        if poi_values is None:
            raise (
                TypeError(
                    "(poi_values) can not be None"))
                    
        self.m_poi_values = poi_values.copy(self.m_poi_values) # store
        
    cpdef DoubleArray2 poi_positions(self, object store): 
        return self.m_poi_positions.copy(store)
        
    cpdef void set_poi_positions(self, DoubleArray2 poi_positions) except *:
        if poi_positions is None:
            raise (
                TypeError(
                    "(poi_positions) can not be None"))
                    
        self.m_poi_positions = poi_positions.copy(self.m_poi_positions) # store


        

        
        
        