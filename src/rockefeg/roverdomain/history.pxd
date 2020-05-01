from .state cimport State

cdef StateHistory new_StateHistory()
cdef void init_StateHistory(StateHistory history) except *

cdef class StateHistory:
    cdef list __history
    #list<State>[n_steps]

    cpdef object copy(self)

    #def __len__(self)

    cpdef State entry(self, Py_ssize_t entry_id)
    cpdef State pop(self, Py_ssize_t entry_id)
    cpdef void insert_entry_at(self, Py_ssize_t entry_id, State state) except *
    cpdef void overwrite(self, Py_ssize_t entry_id, State state) except *
    cpdef void record(self, State state) except *

    cpdef void clear(self)

    cpdef list _history(self)
    cpdef void set_history(self, list history) except *

cdef ActionsHistory new_ActionsHistory()
cdef void init_ActionsHistory(ActionsHistory history) except *

cdef class ActionsHistory:
    cdef list __history
    #list<list<DoubleArray>>>[n_steps][n_rovers][n_action_dims]

    cpdef void check_actions(self, list actions) except *

    cpdef list copy_actions(self, list actions)


    cpdef object copy(self)

    #def __len__(self)

    cpdef list entry(self, Py_ssize_t entry_id)
    cpdef list pop(self, Py_ssize_t entry_id)
    cpdef void insert_entry_at(self, Py_ssize_t entry_id, list actions) except *
    cpdef void overwrite(self, Py_ssize_t entry_id, list actions) except *
    cpdef void record(self, list actions) except *

    cpdef void clear(self)

    cpdef list _history(self)
    cpdef void set_history(self, list history) except *