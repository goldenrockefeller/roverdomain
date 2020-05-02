cimport cython

from libc cimport math as cmath

cdef double TAU = 2 * cmath.pi


cdef RoverDatum new_RoverDatum():
    cdef RoverDatum new_rover_datum
    
    new_rover_datum = RoverDatum.__new__(RoverDatum)
    init_RoverDatum(new_rover_datum)
    
    return new_rover_datum

cdef void init_RoverDatum(RoverDatum rover_datum) except *:
    if rover_datum is None:
        raise TypeError("The rover datum (rover_datum) cannot be None.")


@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverDatum:
    def __init__(self):
        init_RoverDatum(self)
        
    cpdef object copy(self, object copy_obj = None):
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
cdef class PoiDatum:
    def __init__(self):
        init_PoiDatum(self)

    cpdef object copy(self, object copy_obj = None):
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
    
cdef RoverData new_RoverData():
    cdef RoverData data
    
    data = RoverData.__new__(RoverData)
    init_RoverData(data)
    
    return data

cdef void init_RoverData(RoverData data) except *:
    if data is None:
        raise TypeError("The rover data (data) cannot be None.")

    data.__data = []
        
    
@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class RoverData:
    def __init__(self):
        init_RoverData(self)
        
    cpdef object copy(self, object copy_obj = None):
        cdef RoverData new_data
        cdef Py_ssize_t datum_id
        
        if copy_obj is None:
            new_data = RoverData.__new__(RoverData)
        else:
            new_data = copy_obj
            
        new_data.__data = [None] * len(self)
        
        for datum_id in range(len(self)):
            new_data.__data[datum_id] = self.__data[datum_id].copy()
        
        return new_data
    
    def __len__(self):
        return len(self.__data)
    
    cpdef void append(self, RoverDatum datum) except *:
        if datum is None:
            raise TypeError("The rover datum (datum) must not be None.")
            
        self.__data.append(datum)
        
    cpdef RoverDatum pop(self, Py_ssize_t index):
        return self.__data.pop(index)
        
    cpdef void insert(self, Py_ssize_t index, RoverDatum datum) except *:
        self.__data.insert(index, datum)
        
    cpdef RoverDatum datum(self, Py_ssize_t index):
        return self.__data[index]
        
    cpdef void set_datum(self, Py_ssize_t index, RoverDatum datum) except *:
        if datum is None:
            raise TypeError("The rover datum (datum) must not be None.")
            
        self.__data[index] = datum
    
    cpdef list _data(self):
        return self.__data
        
    cpdef void set_data(self, list data) except *:
        cdef Py_ssize_t datum_id
        cdef object datum
        
        if data is None:
            raise TypeError("The data (data) must not be None.")
        
        for datum_id in range(len(data)):
            datum = data[datum_id]
            if not isinstance(datum, RoverDatum):
                raise (
                    TypeError(
                        "All objects in data (data) must be instances of "
                        "RoverDatum. type(data[{datum_id}]) is "
                        "{datum.__class__}."
                        .format(**locals()) ))
        
        self.__data = data
    
cdef PoiData new_PoiData():
    cdef PoiData data
    
    data = PoiData.__new__(PoiData)
    init_PoiData(data)
    
    return data

cdef void init_PoiData(PoiData data) except *:
    if data is None:
        raise TypeError("The poi data (data) cannot be None.")

    data.__data = []
    
@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class PoiData:
    def __init__(self):
        init_PoiData(self)
        
        
    cpdef object copy(self, object copy_obj = None):
        cdef PoiData new_data
        cdef Py_ssize_t datum_id
        
        if copy_obj is None:
            new_data = PoiData.__new__(PoiData)
        else:
            new_data = copy_obj
        
        new_data.__data = [None] * len(self)
        
        for datum_id in range(len(self)):
            new_data.__data[datum_id] = self.__data[datum_id].copy()
        
        return new_data
    
    def __len__(self):
        return len(self.__data)
    
    cpdef void append(self, PoiDatum datum) except *:
        if datum is None:
            raise TypeError("The POI datum (datum) must not be None.")
            
        self.__data.append(datum)
        
    cpdef PoiDatum pop(self, Py_ssize_t index):
        return self.__data.pop(index)
        
    cpdef void insert(self, Py_ssize_t index, PoiDatum datum) except *:
        self.__data.insert(index, datum)
        
    cpdef PoiDatum datum(self, Py_ssize_t index):
        return self.__data[index]
        
    cpdef void set_datum(self, Py_ssize_t index, PoiDatum datum) except *:
        if datum is None:
            raise TypeError("The POI datum (datum) must not be None.")
            
        self.__data[index] = datum
    
    cpdef list _data(self):
        return self.__data
        
    cpdef void set_data(self, list data) except *:
        cdef Py_ssize_t datum_id
        cdef object datum
        
        if data is None:
            raise TypeError("The data (data) must not be None.")
        
        for datum_id in range(len(data)):
            datum = data[datum_id]
            if not isinstance(datum, PoiDatum):
                raise (
                    TypeError(
                        "All objects in data (data) must be instances of "
                        "PoiDatum. (type(data[{datum_id}]) = "
                        "{datum.__class__})."
                        .format(**locals()) ))
        
        self.__data = data
    
cdef State new_State():
    cdef State state
    
    state = State.__new__(State)
    init_State(state)
    
    return state

cdef void init_State(State state) except *:
    if state is None:
        raise TypeError("The state (state) cannot be None.")
        
    state.__rover_data = RoverData()
    state.__poi_data = PoiData()

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class State:
    def __init__(self):
        init_State(self)
        
    cpdef object copy(self, object copy_obj = None):
        cdef State new_state
        
        if copy_obj is None:
            new_state = State.__new__(State)
        else:
            new_state = copy_obj
            
        new_state.__rover_data = self.__rover_data.copy()
        new_state.__poi_data = self.__poi_data.copy()
        
        return new_state
    
    cpdef RoverData rover_data(self):
        return self.__rover_data
        
    cpdef void set_rover_data(self, RoverData rover_data) except *:
        if rover_data is None:
            raise TypeError("The rover data (rover_data) must not be None")
        self.__rover_data = rover_data
    
    cpdef PoiData poi_data(self):
        return self.__poi_data
        
    cpdef void set_poi_data(self, PoiData poi_data) except *:
        if poi_data is None:
            raise TypeError("The poi data (poi_data) must not be None")
            
        self.__poi_data = poi_data

        

        
        
        