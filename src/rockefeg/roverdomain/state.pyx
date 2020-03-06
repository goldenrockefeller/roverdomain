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
            self.m_rover_orientations.view[rover_id, 0] = 1.
            
        self.m_poi_positions = DoubleArray2(np.zeros((n_pois, 2)))
        self.m_poi_values = DoubleArray1(np.zeros(n_pois))
        
    cpdef object copy(self):
        return self.copy_to(None)
        
    def __setitem__(self, index, obj):
        cdef State other
        cdef object other_type
        
        if index is not ...:
            raise IndexError("The index (index) must be Ellipsis ('...')")
        
        if obj is None:        
            other = State()  
        elif type(obj) is type(self):
            other = <State?> obj
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
        cdef State other
        cdef object other_type
        
        if obj is None:        
            other = State() 
        elif type(obj) is type(self):
            other = <State?> obj
        else:
            other_type = type(obj)
            raise (
                TypeError(
                    "The type of the other object "
                    "(other_type = {other_type}) is not "
                    "{self.__class__}, None"
                    .format(**locals())))
                
        other.m_rover_positions[...] = self.m_rover_positions
        other.m_rover_orientations[...] = self.m_rover_orientations
        other.m_poi_positions[...] = self.m_poi_positions
        other.m_poi_values[...] = self.m_poi_values
                
        other.m_n_rovers = self.m_n_rovers
        other.m_n_pois = self.m_n_pois
                
        return other
        
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
                self.m_rover_orientations.view[rover_id, 0] = 1.
        
    cpdef Py_ssize_t n_pois(self) except *:
        return self.m_n_pois
        
    cpdef void set_n_pois(self, Py_ssize_t n_pois) except *:
        if n_pois < 0:
            raise ValueError(
                "The number of POIs (n_pois = {n_pois}) must be non-negative. "
                .format(**locals()))
                
        if self.m_n_pois != n_pois:
            self.m_n_pois = n_pois
            
            self.m_poi_positions.repurpose(n_pois, 2)
            self.m_poi_positions.set_all_to(0.) 
            
            self.m_poi_values.repurpose(n_pois)
            self.m_poi_values.set_all_to(0.) 
        
    cpdef DoubleArray2 rover_positions(self): 
        return self.m_rover_positions
        
    cpdef void set_rover_positions(
            self, 
            DoubleArray2 rover_positions
            ) except * :
        cdef Py_ssize_t n_rovers
        
        
        if rover_positions is None:
            raise (
                TypeError(
                    "(rover_positions) can not be None")) 
        
        n_rovers = self.n_rovers()
        if rover_positions.view.shape[0] != n_rovers:
            raise (
                TypeError(
                    "Can not accept (rover_positions) shape"
                    "(rover_positions.view.shape = "
                    "{rover_positions.view.shape}) "
                    "if rover_positions.view.shape[0] != "
                    "the number of rovers "
                    "(self.n_rovers()  = {n_rovers})."
                    .format(**locals())))  
                
        if rover_positions.view.shape[1] != 2:
            raise (
                TypeError(
                    "Can not accept (rover_positions) shape"
                    "(rover_positions.view.shape = "
                    "{rover_positions.view.shape}) "
                    "if rover_positions.view.shape[1] != 2"
                    .format(**locals())))   
                
        self.m_rover_positions[...] = rover_positions
        
    cpdef DoubleArray2 rover_orientations(self): 
        return self.m_rover_orientations
        
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
        if rover_orientations.view.shape[0] != n_rovers:
            raise (
                TypeError(
                    "Can not accept (rover_orientations) shape"
                    "(rover_orientations.view.shape = "
                    "{rover_orientations.view.shape}) "
                    "if rover_orientations.view.shape[0] != "
                    "the number of rovers "
                    "(self.n_rovers()  = {n_rovers})."
                    .format(**locals())))  
                    
        if rover_orientations.view.shape[1] != 2:
            raise (
                TypeError(
                    "Can not accept (rover_orientations) shape"
                    "(rover_orientations.view.shape = "
                    "{rover_orientations.view.shape}) "
                    "if rover_orientations.view.shape[1] != 2"
                    .format(**locals())))    
        
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
        
    
    cpdef DoubleArray1 poi_values(self):
        return self.m_poi_values
        
    cpdef void set_poi_values(self, DoubleArray1 poi_values) except *:
        cdef Py_ssize_t n_pois
        if poi_values is None:
            raise (
                TypeError(
                    "(poi_values) can not be None"))
        
        n_pois = self.n_pois()           
        if poi_values.view.shape[0] != self.n_pois():
            raise (
                TypeError(
                    "Can not accept (poi_values) shape"
                    "(poi_values.view.shape = "
                    "{poi_values.view.shape}) "
                    "if poi_values.view.shape[0] != "
                    "the number of POIs (self.n_pois()  = {n_pois})."
                    .format(**locals())))  
                    
        self.m_poi_values[...] = poi_values
        
    cpdef DoubleArray2 poi_positions(self): 
        return self.m_poi_positions
        
    cpdef void set_poi_positions(self, DoubleArray2 poi_positions) except *:
        cdef Py_ssize_t n_pois
        
        if poi_positions is None:
            raise (
                TypeError(
                    "(poi_positions) can not be None"))
                    
        n_pois = self.n_pois()
        if poi_positions.view.shape[0] != n_pois:
            raise (
                TypeError(
                    "Can not accept (poi_positions) shape"
                    "(poi_positions.view.shape = "
                    "{poi_positions.view.shape}) "
                    "if poi_positions.view.shape[0] != "
                    "the number of POIs (self.n_pois()  = {n_pois})."
                    .format(**locals())))  
        
        if poi_positions.view.shape[1] != 2:
            raise (
                TypeError(
                    "Can not accept (poi_positions) shape"
                    "(poi_positions.view.shape = "
                    "{poi_positions.view.shape}) "
                    "if poi_positions.view.shape[1] != 2"
                    .format(**locals())))    
                    
        self.m_poi_positions[...] = poi_positions


        

        
        
        