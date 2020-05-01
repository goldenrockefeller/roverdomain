cimport cython
from rockefeg.cyutil.array cimport DoubleArray

cdef StateHistory new_StateHistory():
    cdef StateHistory history

    history = StateHistory.__new__(StateHistory)
    init_StateHistory(history)

    return history

cdef void init_StateHistory(StateHistory history) except *:
    if history is None:
        raise TypeError("The state history (history) cannot be None.")

    history.__history = []

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class StateHistory:
    def __init__(self):
        init_StateHistory(self)

    cpdef object copy(self):
        cdef StateHistory new_history
        cdef Py_ssize_t state_id
        cdef State state

        new_history = self.__class__.__new__(self.__class__)
        new_history.__history = [None] * len(self)

        for state_id in range(len(self)):
            state = self.__history[state_id]
            new_history.__history[state_id] = state.copy()

        return new_history

    def __len__(self):
        return len(self.__history)

    cpdef State entry(self, Py_ssize_t entry_id):
        cdef State state

        state = self.__history[entry_id]
        return state.copy()

    cpdef State pop(self, Py_ssize_t entry_id):
        return self.__history.pop(entry_id)

    cpdef void insert(self, Py_ssize_t entry_id, State state) except *:
        if state is None:
            raise TypeError("The state (state) must not be None.")

        self.__history.insert(entry_id, state.copy())

    cpdef void overwrite(self, Py_ssize_t entry_id, State state) except *:
        if state is None:
            raise TypeError("The state (state) must not be None.")

        self.__history[entry_id] = state.copy()

    cpdef void record(self, State state) except *:
        self.__history.append(state.copy())

    cpdef void clear(self):
        self.__history = []

    cpdef list _history(self):
        return self.__history

    cpdef void set_history(self, list history) except *:
        cdef Py_ssize_t state_id
        cdef State state

        if history is None:
            raise TypeError("The history (history) must not be None.")

        for state_id in range(history):
            state = history[state_id]
            if not isinstance(history[state_id], State):
                raise (
                    TypeError(
                        "All objects in the history (history) must be "
                        "instances of State. type(history[{state_id}]) is "
                        "{state.__class__}."
                        .format(**locals()) ))

        self.__history = history


cdef ActionsHistory new_ActionsHistory():
    cdef ActionsHistory history

    history = ActionsHistory.__new__(ActionsHistory)
    init_ActionsHistory(history)

    return history


cdef void init_ActionsHistory(ActionsHistory history) except *:
    if history is None:
        raise (
            TypeError(
                "The rover actions history (history) cannot be None." ))

    history.__history = []

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class ActionsHistory:
    def __init__(self):
        init_ActionsHistory(self)


    cpdef void check_actions(self, list actions) except *:
        cdef Py_ssize_t action_id
        cdef object action

        if actions is None:
            raise TypeError("The actions (actions) must not be None.")

        for action_id in range(len(actions)):
            action = actions[action_id]
            if not isinstance(action, DoubleArray):
                raise (
                    TypeError(
                        "All objects in the list of actions (actions) must be "
                        "instances of DoubleArray. type(actions[{action_id}]) "
                        "is {action.__class__}."
                        .format(**locals()) ))

    cpdef list copy_actions(self, list actions):
        cdef list new_actions
        cdef Py_ssize_t action_id
        cdef DoubleArray action

        self.check_actions(actions)

        new_actions = [None] * len(actions)

        for action_id in range(len(actions)):
            action = actions[action_id]
            new_actions[action_id] = action.copy()

        return new_actions

    cpdef object copy(self):
        cdef ActionsHistory new_history
        cdef Py_ssize_t entry_id
        cdef list actions

        new_history = self.__class__.__new__(self.__class__)
        new_history.__history = [None] * len(self)

        for entry_id in range(len(self)):
            actions = self.__history[entry_id]
            new_history.__history[entry_id] = (
                self.copy_actions(actions))

        return new_history

    def __len__(self):
        return len(self.__history)

    cpdef list entry(self, Py_ssize_t entry_id):
        return self.copy_actions(self.__history[entry_id])

    cpdef list pop(self, Py_ssize_t entry_id):
        return self.__history.pop(entry_id)

    cpdef void insert(
            self,
            Py_ssize_t entry_id,
            list actions
            ) except *:
        self.check_actions(actions)
        self.__history.insert(
            entry_id,
            self.copy_actions(actions) )

    cpdef void overwrite(self, Py_ssize_t entry_id, list actions) except *:
        self.check_actions(actions)

        self.__history[entry_id] = self.copy_actions(actions)

    cpdef void record(self, list actions) except *:
        self.check_actions(actions)
        self.__history.append(self.copy_actions(actions))

    cpdef void clear(self):
        self.__history = []

    cpdef list _history(self):
        return self.__history

    cpdef void set_history(self, list history) except *:
        cdef Py_ssize_t actions_id
        cdef object exc

        if history is None:
            raise TypeError("The history (history) must not be None.")

        for actions_id in range(history):
            self.check_actions(history[actions_id])

        self.__history = history