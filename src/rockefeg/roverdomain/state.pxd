cdef RoverDatum new_RoverDatum()
cdef void init_RoverDatum(RoverDatum datum) except *

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

cdef PoiDatum new_PoiDatum()
cdef void init_PoiDatum(PoiDatum datum) except *    
    
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
    
cdef RoverData new_RoverData()
cdef void init_RoverData(RoverData data) except *

cdef class RoverData:
    cdef list __data
    # list<RoverDatum>[n_rovers]
    
    cpdef copy(self, copy_obj = ?)
    
    #def __len__(self)
    
    cpdef void append(self, datum) except *
    cpdef pop(self, Py_ssize_t index)
    cpdef void insert(self, Py_ssize_t index, datum) except *
    
    cpdef datum(self, Py_ssize_t index)
    cpdef void set_datum(self, Py_ssize_t index, datum) except *
    
    cpdef list _data(self)
    cpdef list data_shallow_copy(self)
    cpdef void set_data(self, list data) except *
    # list<RoverDatum>[n_rovers]

cdef PoiData new_PoiData()
cdef void init_PoiData(PoiData data) except *    
    
cdef class PoiData:
    cdef list __data
    # list<PoiDatum>[n_pois]
    
    cpdef copy(self, copy_obj = ?)
    
    #def __len__(self)
    
    cpdef void append(self, datum) except *
    cpdef pop(self, Py_ssize_t index)
    cpdef void insert(self, Py_ssize_t index, datum) except *
    
    cpdef datum(self, Py_ssize_t index)
    cpdef void set_datum(self, Py_ssize_t index, datum) except *
    
    cpdef list _data(self)
    cpdef list data_shallow_copy(self)
    cpdef void set_data(self, list data) except *
    # list<PoiDatum>[n_pois]
    
cdef State new_State()
cdef void init_State(State state) except *

cdef class State:
    cdef __rover_data
    cdef __poi_data
    
    cpdef object copy(self, object copy_obj = ?)
    
    cpdef rover_data(self)
    cpdef void set_rover_data(self, rover_data) except *
    
    cpdef poi_data(self)
    cpdef void set_poi_data(self, poi_data) except *
    
    
    
    

        
        