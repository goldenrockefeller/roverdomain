

cdef class RoverDatum:
    cdef double __position_x
    cdef double __position_y
    cdef double __direction
    
    cpdef copy(self, copy_obj = ?)
    
    cpdef double position_x(self) except *
    cpdef void set_position_x(self, double position_x) except *
    
    cpdef double position_y(self) except *
    cpdef void set_position_y(self, double position_x) except *
    
    cpdef double direction(self) except *
    cpdef void set_direction(self, double direction) except *
    
cdef RoverDatum new_RoverDatum()
cdef void init_RoverDatum(RoverDatum datum) except *
  
    
cdef class PoiDatum:
    cdef double __position_x
    cdef double __position_y
    cdef double __value
    
    cpdef copy(self, copy_obj = ?)
    
    cpdef double position_x(self) except *
    cpdef void set_position_x(self, double position_x) except *
    
    cpdef double position_y(self) except *
    cpdef void set_position_y(self, double position_x) except *
    
    cpdef double value(self) except *
    cpdef void set_value(self, double value) except *
    

cdef PoiDatum new_PoiDatum()
cdef void init_PoiDatum(PoiDatum datum) except *  


cdef class State:
    cdef __rover_data
    cdef __poi_data
    
    cpdef copy(self, copy_obj = ?)
    
    cpdef rover_data(self)
    cpdef void set_rover_data(self, rover_data) except *
    
    cpdef poi_data(self)
    cpdef void set_poi_data(self, poi_data) except *
    
cdef State new_State()
cdef void init_State(State state) except *

    
    

        
        