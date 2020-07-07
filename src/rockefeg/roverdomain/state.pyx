cimport cython

from libc cimport math as cmath

cdef double TAU = 2 * cmath.pi




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
            
        new_rover_datum.__position_x = self.__position_x
        new_rover_datum.__position_y = self.__position_y
        new_rover_datum.__direction = self.__direction
        
        return new_rover_datum
    
    cpdef double position_x(self) except *:
        return self.__position_x
        
    cpdef void set_position_x(self, double position_x) except *:
        self.__position_x = position_x
    
    cpdef double position_y(self) except *:
        return self.__position_y
        
    cpdef void set_position_y(self, double position_y) except *:
        self.__position_y = position_y
    
    cpdef double direction(self) except *:
        return self.__direction
        
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
                
        self.__direction = direction

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
            
        new_poi_datum.__position_x = self.__position_x
        new_poi_datum.__position_y = self.__position_y
        new_poi_datum.__value = self.__value
        
        return new_poi_datum
    
    cpdef double position_x(self) except *:
        return self.__position_x
        
    cpdef void set_position_x(self, double position_x) except *:
        self.__position_x = position_x
    
    cpdef double position_y(self) except *:
        return self.__position_y
        
    cpdef void set_position_y(self, double position_y) except *:
        self.__position_y = position_y
        
    cpdef double value(self) except *:
        return self.__value
        
    cpdef void set_value(self, double value) except *:
        self.__value = value
        
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
        
    cpdef copy(self, copy_obj = None):
        cdef State new_state
        cdef Py_ssize_t datum_id
        cdef RoverDatum rover_datum
        cdef PoiDatum poi_datum
        
        if copy_obj is None:
            new_state = State.__new__(State)
        else:
            new_state = copy_obj
            
        new_state.__rover_data = self.rover_data_deep_copy()
        new_state.__poi_data = self.poi_data_deep_copy()
        
        return new_state
     
    cpdef Py_ssize_t n_rovers(self) except *:
          return len(self.__rover_data)
        
    cpdef void append_rover_datum(self, rover_datum) except *:
        self.__rover_data.append(<RoverDatum?>rover_datum)
        
    cpdef pop_rover_datum(self, Py_ssize_t index = -1):
        return self.__rover_data.pop(index)
        
    cpdef void insert_rover_datum(self, Py_ssize_t index, rover_datum) except *:
        self.__rover_data.insert(index, <RoverDatum?>rover_datum)
        
    cpdef rover_datum(self, Py_ssize_t index):
        return self.__rover_data[index]
        
    cpdef void set_rover_datum(self, Py_ssize_t index, rover_datum) except *:
        self.__rover_data[index] = <RoverDatum?>rover_datum
 
    cpdef list _rover_data(self):
        return self.__rover_data
        
    cpdef list rover_data_shallow_copy(self):
        cdef list rover_data_copy
        cdef Py_ssize_t rover_datum_id
        
        rover_data_copy = [None] * len(self.__rover_data)
        
        for rover_datum_id in range(len(self.__rover_data)):
            rover_data_copy[rover_datum_id] = self.__rover_data[rover_datum_id]
            
        return rover_data_copy
        
    cpdef list rover_data_deep_copy(self):
        cdef list rover_data_copy
        cdef Py_ssize_t rover_datum_id
        cdef RoverDatum rover_datum
        
        rover_data_copy = [None] * len(self.__rover_data)
        
        for rover_datum_id in range(len(self.__rover_data)):
            rover_datum = self.__rover_data[rover_datum_id]
            rover_data_copy[rover_datum_id] = rover_datum.copy()
            
        return rover_data_copy
        
    cpdef void set_rover_data(self, list rover_data) except *:
        cdef Py_ssize_t rover_datum_id
        cdef RoverDatum rover_datum
        
        for rover_datum_id in range(len(rover_data)):
            rover_datum = rover_data[rover_datum_id]
            if not isinstance(rover_datum, RoverDatum):
                raise (
                    TypeError(
                        "All objects in (rover_data) must be instances of "
                        "RoverDatum. (type(rover_data[{rover_datum_id}]) = "
                        "{rover_datum.__class__})."
                        .format(**locals()) ))
        
        self.__rover_data = rover_data
        
    cpdef Py_ssize_t n_pois(self) except *:
          return len(self.__poi_data)
        
    cpdef void append_poi_datum(self, poi_datum) except *:
        self.__poi_data.append(<PoiDatum?>poi_datum)
        
    cpdef pop_poi_datum(self, Py_ssize_t index = -1):
        return self.__poi_data.pop(index)
        
    cpdef void insert_poi_datum(self, Py_ssize_t index, poi_datum) except *:
        self.__poi_data.insert(index, <PoiDatum?>poi_datum)
        
    cpdef poi_datum(self, Py_ssize_t index):
        return self.__poi_data[index]
        
    cpdef void set_poi_datum(self, Py_ssize_t index, poi_datum) except *:
        self.__poi_data[index] = <PoiDatum?>poi_datum
 
    cpdef list _poi_data(self):
        return self.__poi_data
        
    cpdef list poi_data_shallow_copy(self):
        cdef list poi_data_copy
        cdef Py_ssize_t poi_datum_id
        
        poi_data_copy = [None] * len(self.__poi_data)
        
        for poi_datum_id in range(len(self.__poi_data)):
            poi_data_copy[poi_datum_id] = self.__poi_data[poi_datum_id]
            
        return poi_data_copy
        
    cpdef list poi_data_deep_copy(self):
        cdef list poi_data_copy
        cdef Py_ssize_t poi_datum_id
        cdef PoiDatum poi_datum
        
        poi_data_copy = [None] * len(self.__poi_data)
        
        for poi_datum_id in range(len(self.__poi_data)):
            poi_datum = self.__poi_data[poi_datum_id]
            poi_data_copy[poi_datum_id] = poi_datum.copy()
            
        return poi_data_copy
        
    cpdef void set_poi_data(self, list poi_data) except *:
        cdef Py_ssize_t poi_datum_id
        cdef PoiDatum poi_datum
        
        for poi_datum_id in range(len(poi_data)):
            poi_datum = poi_data[poi_datum_id]
            if not isinstance(poi_datum, PoiDatum):
                raise (
                    TypeError(
                        "All objects in (poi_data) must be instances of "
                        "PoiDatum. (type(poi_data[{poi_datum_id}]) = "
                        "{poi_datum.__class__})."
                        .format(**locals()) ))
        
        self.__poi_data = poi_data


cdef State new_State():
    cdef State state
    
    state = State.__new__(State)
    init_State(state)
    
    return state

cdef void init_State(State state) except *:
    if state is None:
        raise TypeError("The state (state) cannot be None.")
        
    state.__rover_data = []
    state.__poi_data = []
        

        
        
        