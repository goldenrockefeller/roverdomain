cimport cython
from rockefeg.cyutil.array cimport DoubleArray
from .state cimport State

@cython.warn.undeclared(True)
cpdef void ensure_all_is_DoubleArray(list arr_list) except *:
    cdef Py_ssize_t id
    cdef DoubleArray arr

    if arr_list is None:
        raise TypeError("The arr_list (arr_list) must not be None.")

    for id in range(len(arr_list)):
        arr = arr_list[id]
        if not isinstance(arr, DoubleArray):
            raise (
                TypeError(
                    "All objects in the list of arr_list (arr_list) must be "
                    "instances of DoubleArray. type(arr_list[{id}]) "
                    "is {arr.__class__}."
                    .format(**locals()) ))

@cython.warn.undeclared(True)
cpdef list deep_copy_DoubleArray_list(list arr_list):
    cdef DoubleArray arr
    cdef list new_list
    cdef Py_ssize_t id

    ensure_all_is_DoubleArray(arr_list)

    new_list = [None] * len(arr_list)

    for id in range(len(arr_list)):
        arr = arr_list[id]
        new_list[id] = arr.copy()

    return new_list



@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class StateHistory:
    def __init__(self):
        init_StateHistory(self)

    cpdef copy(self, copy_obj = None):
        cdef StateHistory new_history
        cdef Py_ssize_t state_id
        cdef State state

        if copy_obj is None:
            new_history = StateHistory.__new__(StateHistory)
        else:
            new_history = copy_obj

        new_history.__history = self.history_deep_copy()

        return new_history

    def __len__(self):
        return len(self.__history)

    cpdef entry(self, Py_ssize_t entry_id):
        cdef State state

        state = self.__history[entry_id]
        return state.copy()

    cpdef pop(self, Py_ssize_t entry_id):
        return self.__history.pop(entry_id)

    cpdef void insert_entry_at(self, Py_ssize_t entry_id, state) except *:
        cdef State cy_state = <State?> state

        self.__history.insert(entry_id, cy_state.copy())

    cpdef void overwrite(self, Py_ssize_t entry_id, state) except *:
        cdef State cy_state = <State?> state

        self.__history[entry_id] = cy_state.copy()

    cpdef void record(self, state) except *:
        cdef State cy_state = <State?> state

        self.__history.append(cy_state.copy())

    cpdef void clear(self):
        self.__history = []

    cpdef list _history(self):
        return self.__history

    cpdef list history_shallow_copy(self):
        cdef list history_copy
        cdef Py_ssize_t state_id

        history_copy = [None] * len(self.__history)

        for state_id in range(len(self.__history)):
            history_copy[state_id] = self.__history[state_id]

        return history_copy

    cpdef list history_deep_copy(self):
        cdef list history_copy
        cdef Py_ssize_t state_id
        cdef State state

        history_copy = [None] * len(self.__history)

        for state_id in range(len(self.__history)):
            state = self.__history[state_id]
            history_copy[state_id] = state.copy()

        return history_copy

    cpdef void set_history(self, list history) except *:
        cdef Py_ssize_t state_id
        cdef State state

        for state_id in range(len(history)):
            state = history[state_id]
            if not isinstance(state, State):
                raise (
                    TypeError(
                        "All objects in (history) must be instances of "
                        "State. (type(history[{state_id}]) = "
                        "{state.__class__})."
                        .format(**locals()) ))

        self.__history = history
@cython.warn.undeclared(True)
cdef StateHistory new_StateHistory():
    cdef StateHistory history

    history = StateHistory.__new__(StateHistory)
    init_StateHistory(history)

    return history

@cython.warn.undeclared(True)
cdef void init_StateHistory(StateHistory history) except *:
    if history is None:
        raise TypeError("The state history (history) cannot be None.")

    history.__history = []


@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class ActionsHistory:
    def __init__(self):
        init_ActionsHistory(self)



    cpdef copy(self, copy_obj = None):
        cdef ActionsHistory new_history
        cdef Py_ssize_t entry_id

        if copy_obj is None:
            new_history = ActionsHistory.__new__(ActionsHistory)
        else:
            new_history = copy_obj

        new_history.__history = self.history_deep_copy()

        return new_history

    def __len__(self):
        return len(self.__history)

    cpdef list entry(self, Py_ssize_t entry_id):
        return deep_copy_DoubleArray_list(self.__history[entry_id])

    cpdef list pop(self, Py_ssize_t entry_id):
        return self.__history.pop(entry_id)

    cpdef void insert_entry_at(
            self,
            Py_ssize_t entry_id,
            list joint_action
            ) except *:
        ensure_all_is_DoubleArray(joint_action)
        self.__history.insert(
            entry_id,
            deep_copy_DoubleArray_list(joint_action) )

    cpdef void overwrite(self, Py_ssize_t entry_id, list joint_action) except *:
        ensure_all_is_DoubleArray(joint_action)

        self.__history[entry_id] = deep_copy_DoubleArray_list(joint_action)

    cpdef void record(self, list joint_action) except *:
        ensure_all_is_DoubleArray(joint_action)
        self.__history.append(deep_copy_DoubleArray_list(joint_action))

    cpdef void clear(self):
        self.__history = []

    cpdef list _history(self):
        return self.__history

    cpdef list history_shallow_copy(self):
        cdef list history_copy
        cdef Py_ssize_t action_id

        history_copy = [None] * len(self.__history)

        for action_id in range(len(self.__history)):
            history_copy[action_id] = self.__history[action_id]

        return history_copy

    cpdef list history_deep_copy(self):
        cdef list history_copy
        cdef Py_ssize_t action_id
        cdef list joint_action

        history_copy = [None] * len(self.__history)

        for action_id in range(len(self.__history)):
            joint_action = self.__history[action_id]
            history_copy[action_id] = deep_copy_DoubleArray_list(joint_action)

        return history_copy

    cpdef void set_history(self, list history) except *:
        cdef Py_ssize_t joint_action_id
        cdef list joint_action

        for joint_action_id in range(len(history)):
            ensure_all_is_DoubleArray(history[joint_action_id])

        self.__history = history

@cython.warn.undeclared(True)
cdef ActionsHistory new_ActionsHistory():
    cdef ActionsHistory history

    history = ActionsHistory.__new__(ActionsHistory)
    init_ActionsHistory(history)

    return history

@cython.warn.undeclared(True)
cdef void init_ActionsHistory(ActionsHistory history) except *:
    if history is None:
        raise (
            TypeError(
                "The rover actions history (history) cannot be None." ))

    history.__history = []

