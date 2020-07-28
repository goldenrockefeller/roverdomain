cimport cython

from libc cimport math as cmath


cdef double TAU = 2 * cmath.pi

from rockefeg.cyutil.typed_list cimport TypedList, new_TypedList
from rockefeg.cyutil.typed_list cimport BaseWritableTypedList, is_sub_full_type 



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
        cdef Py_ssize_t rover_datum_id
        cdef Py_ssize_t poi_datum_id
        cdef BaseWritableTypedList rover_data
        cdef BaseWritableTypedList poi_data
        cdef BaseWritableTypedList new_rover_data
        cdef BaseWritableTypedList new_poi_data
        cdef RoverDatum rover_datum
        cdef PoiDatum poi_datum
        
        if copy_obj is None:
            new_state = State.__new__(State)
        else:
            new_state = copy_obj
            
        # Deep Copy.
        rover_data = self.__rover_data
        new_rover_data = rover_data.shallow_copy()
        for rover_datum_id in range(len(rover_data)):
            rover_datum = rover_data.item(rover_datum_id)
            new_rover_data.set_item(rover_datum_id, rover_datum.copy())
        new_state.__rover_data = new_rover_data   
        
        # Deep Copy.
        poi_data = self.__poi_data
        new_poi_data = poi_data.shallow_copy()
        for poi_datum_id in range(len(poi_data)):
            poi_datum = poi_data.item(poi_datum_id)
            new_poi_data.set_item(poi_datum_id, poi_datum.copy())
        new_state.__poi_data = new_poi_data   
        
        return new_state
     
    cpdef rover_data(self):
        return self.__rover_data
        
    cpdef void set_rover_data(self, rover_data) except *:
        cdef BaseWritableTypedList setting_rover_data = (
            <BaseWritableTypedList?> rover_data)
        cdef object rover_data_item_type

        rover_data_item_type = setting_rover_data.item_type()

        if not is_sub_full_type(rover_data_item_type, RoverDatum):
            raise (
                TypeError(
                    "The rover data list's item type "
                    "(rover_data.item_type() = {rover_data_item_type}) "
                    "must be RoverDatum."
                    .format(**locals())))

        self.__rover_data = setting_rover_data
    
    cpdef poi_data(self):
        return self.__poi_data
        
    cpdef void set_poi_data(self, poi_data) except *:
        cdef BaseWritableTypedList setting_poi_data = (
            <BaseWritableTypedList?> poi_data)
        cdef object poi_data_item_type

        poi_data_item_type = setting_poi_data.item_type()

        if not is_sub_full_type(poi_data_item_type, PoiDatum):
            raise (
                TypeError(
                    "The POI data list's item type "
                    "(poi_data.item_type() = {poi_data_item_type}) "
                    "must be PoiDatum."
                    .format(**locals())))

        self.__poi_data = setting_poi_data
        

cdef State new_State():
    cdef State state
    
    state = State.__new__(State)
    init_State(state)
    
    return state

cdef void init_State(State state) except *:
    if state is None:
        raise TypeError("The state (state) cannot be None.")
        
    state.__rover_data = new_TypedList(RoverDatum)
    state.__poi_data = new_TypedList(PoiDatum)
        

        
        
        