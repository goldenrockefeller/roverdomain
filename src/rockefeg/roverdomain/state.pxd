cdef RoverDatum new_RoverDatum()
cdef void init_RoverDatum(RoverDatum datum) except *

cdef class RoverDatum:
    cdef double __position_x
    cdef double __position_y
    cdef double __direction
    
    cpdef object copy(self, object copy_obj = ?)
    
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
    
    cpdef object copy(self, object copy_obj = ?)
    
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
    
    cpdef object copy(self, object copy_obj = ?)
    
    #def __len__(self)
    
    cpdef void append(self, RoverDatum datum) except *
    cpdef RoverDatum pop(self, Py_ssize_t index)
    cpdef void insert(self, Py_ssize_t index, RoverDatum datum) except *
    
    cpdef RoverDatum datum(self, Py_ssize_t index)
    cpdef void set_datum(self, Py_ssize_t index, RoverDatum datum) except *
    
    cpdef list _data(self)
    cpdef void set_data(self, list data) except *
    # list<RoverDatum>[n_rovers]

cdef PoiData new_PoiData()
cdef void init_PoiData(PoiData data) except *    
    
cdef class PoiData:
    cdef list __data
    # list<PoiDatum>[n_pois]
    
    cpdef object copy(self, object copy_obj = ?)
    
    #def __len__(self)
    
    cpdef void append(self, PoiDatum datum) except *
    cpdef PoiDatum pop(self, Py_ssize_t index)
    cpdef void insert(self, Py_ssize_t index, PoiDatum datum) except *
    
    cpdef PoiDatum datum(self, Py_ssize_t index)
    cpdef void set_datum(self, Py_ssize_t index, PoiDatum datum) except *
    
    cpdef list _data(self)
    cpdef void set_data(self, list data) except *
    # list<PoiDatum>[n_pois]
    
cdef State new_State()
cdef void init_State(State state) except *

cdef class State:
    cdef RoverData __rover_data
    cdef PoiData __poi_data
    
    cpdef object copy(self, object copy_obj = ?)
    
    cpdef RoverData rover_data(self)
    cpdef void set_rover_data(self, RoverData rover_data) except *
    
    cpdef PoiData poi_data(self)
    cpdef void set_poi_data(self, PoiData poi_data) except *
    
    
    
    

        
        