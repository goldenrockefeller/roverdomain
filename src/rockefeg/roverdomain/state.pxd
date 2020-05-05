

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
    
    cpdef Py_ssize_t n_rovers(self) except *
    cpdef void append_rover_datum(self, rover_datum) except *
    cpdef pop_rover_datum(self, Py_ssize_t index)
    cpdef void insert_rover_datum(self, Py_ssize_t index, rover_datum) except *
    cpdef rover_datum(self, Py_ssize_t index)
    cpdef void set_rover_datum(self, Py_ssize_t index, rover_datum) except *
    cpdef list _rover_data(self)
    cpdef list rover_data_shallow_copy(self)
    cpdef list rover_data_deep_copy(self)
    cpdef void set_rover_data(self, list rover_data) except *
    
    cpdef Py_ssize_t n_pois(self) except *
    cpdef void append_poi_datum(self, poi_datum) except *
    cpdef pop_poi_datum(self, Py_ssize_t index)
    cpdef void insert_poi_datum(self, Py_ssize_t index, poi_datum) except *
    cpdef poi_datum(self, Py_ssize_t index)
    cpdef void set_poi_datum(self, Py_ssize_t index, poi_datum) except *
    cpdef list _poi_data(self)
    cpdef list poi_data_shallow_copy(self)
    cpdef list poi_data_deep_copy(self)
    cpdef void set_poi_data(self, list poi_data) except *
    
cdef State new_State()
cdef void init_State(State state) except *

    
    

        
        