cimport cython
import cython

from libc cimport math as cmath


cdef double TAU = 2 * cmath.pi

from typing import List


@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverDatum:
    def __init__(self):
         
        init_RoverDatum(self)
        
    cpdef copy(self, copy_obj = None):
        cdef RoverDatum new_rover_datum
        
        if copy_obj is None:
            new_rover_datum = RoverDatum.__new__(RoverDatum)
        else:
            new_rover_datum = copy_obj
            
        new_rover_datum._position_x = self._position_x
        new_rover_datum._position_y = self._position_y
        new_rover_datum._direction = self._direction
        
        return new_rover_datum
    
    cpdef double position_x(self) except *:
        return self._position_x
        
    cpdef void set_position_x(self, double position_x) except *:
        self._position_x = position_x
    
    cpdef double position_y(self) except *:
        return self._position_y
        
    cpdef void set_position_y(self, double position_y) except *:
        self._position_y = position_y
    
    cpdef double direction(self) except *:
        return self._direction
        
    cpdef void set_direction(self, double direction) except *:
        cdef bint direction_is_neg
        
        # Wrap the direction around (-pi, pi]
        direction_is_neg = direction < 0
        #
        if direction_is_neg:
            direction = -direction
            
            direction = cmath.fmod(direction, TAU)
            if direction >= cmath.pi:
                direction -= TAU
            
            direction = -direction
        else:
            direction = cmath.fmod(direction, TAU)
            
            if direction > cmath.pi:
                direction -= TAU
                
        self._direction = direction

@cython.warn.undeclared(True)
cdef RoverDatum new_RoverDatum():
    cdef RoverDatum new_rover_datum
    
    new_rover_datum = RoverDatum.__new__(RoverDatum)
    init_RoverDatum(new_rover_datum)
    
    return new_rover_datum

@cython.warn.undeclared(True)
cdef void init_RoverDatum(RoverDatum rover_datum) except *:
    if rover_datum is None:
        raise TypeError("The rover datum (rover_datum) cannot be None.")
 
@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class PoiDatum:
    def __init__(self):
        init_PoiDatum(self)

    cpdef copy(self, copy_obj = None):
        cdef PoiDatum new_poi_datum
        
        if copy_obj is None:
            new_poi_datum = PoiDatum.__new__(PoiDatum)
        else:
            new_poi_datum = copy_obj
            
        new_poi_datum._position_x = self._position_x
        new_poi_datum._position_y = self._position_y
        new_poi_datum._value = self._value
        
        return new_poi_datum
    
    cpdef double position_x(self) except *:
        return self._position_x
        
    cpdef void set_position_x(self, double position_x) except *:
        self._position_x = position_x
    
    cpdef double position_y(self) except *:
        return self._position_y
        
    cpdef void set_position_y(self, double position_y) except *:
        self._position_y = position_y
        
    cpdef double value(self) except *:
        return self._value
        
    cpdef void set_value(self, double value) except *:
        self._value = value
        
cdef PoiDatum new_PoiDatum():
    cdef PoiDatum new_poi_datum
    
    new_poi_datum = PoiDatum.__new__(PoiDatum)
    init_PoiDatum(new_poi_datum)
    
    return new_poi_datum

cdef void init_PoiDatum(PoiDatum poi_datum) except *:
    if poi_datum is None:
        raise TypeError("The POI datum (poi_datum) cannot be None.")
        


@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class State:
    def __init__(self):
        init_State(self)
    
    cpdef State copy(self, copy_obj = None):
        cdef State new_state
        cdef Py_ssize_t rover_datum_id
        cdef Py_ssize_t poi_datum_id
        new_rover_data : List[RoverDaturm]
        new_poi_data : List[PoiDatum]
        cdef RoverDatum rover_datum
        cdef PoiDatum poi_datum
        
        if copy_obj is None:
            new_state = State.__new__(State)
        else:
            new_state = copy_obj
            
        # Deep Copy.
        new_state._rover_data  = [None] * len(self._rover_data)
        for rover_datum_id in range(len(self._rover_data)):
            rover_datum = self._rover_data[rover_datum_id]
            new_state._rover_data[rover_datum_id] =  rover_datum.copy()
         
        
        # Deep Copy.
        new_state._poi_data = [None] * len(self._poi_data)
        for poi_datum_id in range(len(self._poi_data)):
            poi_datum = self._poi_data[poi_datum_id]
            new_state._poi_data[poi_datum_id] =  poi_datum.copy()
        
        return new_state
    
    cpdef list rover_data(self):
        # type: (...) -> List[RoverDatum]
        return self._rover_data
        
    cpdef void set_rover_data(self, rover_data : List[RoverDatum]) except *:
        self._rover_data = rover_data
    
    cpdef list poi_data(self):
        # type: (...) -> List[PoiDatum]
        return self._poi_data
        
    cpdef void set_poi_data(self, poi_data : List[PoiDatum]) except *:
        self._poi_data = poi_data
        

cdef State new_State():
    cdef State state
    
    state = State.__new__(State)
    init_State(state)
    
    return state

cdef void init_State(State state) except *:
    if state is None:
        raise TypeError("The state (state) cannot be None.")
        
    state._rover_data = []
    state._poi_data = []
        

        
        
        