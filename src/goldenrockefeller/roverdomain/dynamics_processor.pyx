cimport cython
from goldenrockefeller.cyutil.array cimport DoubleArray
from libc cimport math as cmath
from .state cimport RoverDatum

from typing import Sequence

@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class BaseDynamicsProcessor:
    cpdef BaseDynamicsProcessor copy(self, copy_obj = None):
        pass

    @cython.locals(actions=list)
    cpdef void process_state(
            self,
            State state,
            actions: Sequence[DoubleArray]
            ) except *:
        raise NotImplementedError("Abstract method.")
    # list<DoubleArray>[n_rovers][n_action_dims]


@cython.warn.undeclared(True)
@cython.auto_pickle(True)
cdef class DefaultDynamicsProcessor(BaseDynamicsProcessor):
    def __init__(self):
        init_DefaultDynamicsProcessor(self)

    cpdef DefaultDynamicsProcessor copy(self, copy_obj = None):
        cdef DefaultDynamicsProcessor new_processor

        if copy_obj is None:
            new_processor = DefaultDynamicsProcessor.__new__(DefaultDynamicsProcessor)
        else:
            new_processor = copy_obj
        return new_processor

    @cython.locals(actions=list, rover_data=list)
    cpdef void process_state(
            self,
            State state,
            actions: Sequence[DoubleArray]) except *:
        cdef Py_ssize_t n_rovers, rover_id
        cdef Py_ssize_t n_actions
        cdef Py_ssize_t n_action_dims
        cdef DoubleArray action
        rover_data: Seqeunce[RoverDatum]
        cdef RoverDatum rover_datum
        cdef double clipped_action_0, clipped_action_1
        cdef double gf_rover_unit_direction_x, gf_rover_unit_direction_y
        cdef double delta_direction
        cdef double rover_direction
        cdef double action_norm
        cdef double rf_movement_x, rf_movement_y # rf rover frame
        cdef double gf_movement_x, gf_movement_y # gf global frame
        cdef double position_x, position_y

        state = state
        actions = actions
        rover_data = state.rover_data()

        if state is None:
            raise (
                TypeError(
                    "(state) can not be None"))

        if actions is None:
            raise (
                TypeError(
                    "(actions) can not be None"))

        n_rovers = len(rover_data)
        n_actions = len(actions)

        if n_rovers != len(actions):
            raise (
                TypeError(
                    "The number of rover (state.n_rovers() = "
                    "{n_rovers}) must be equal to the number of actions "
                    "(len(actions) = {n_actions})."
                    .format(**locals())))

        for rover_id in range(n_actions):
            action = actions[rover_id]
            n_action_dims = len(action)
            if n_action_dims != 2:
                raise (
                    IndexError(
                        "The number of action dimensions "
                        "(len(actions[{rover_id}]) = {n_action_dims}) "
                        "must be 2."
                        .format(**locals()) ))

        # Translate then reorient all rovers based on their actions.
        for rover_id in range(n_rovers):
            action = actions[rover_id]

            rover_datum = rover_data[rover_id]

            # action_norm = (
            #     cmath.sqrt(
            #         action.view[0] * action.view[0]
            #         + action.view[1] * action.view[1] ))
            # rf_movement_x = action.view[0]
            # rf_movement_y = action.view[1]
            # if action_norm != 0.0:
            #     rf_movement_x /= action_norm
            #     rf_movement_y /= action_norm
            # if action_norm < 1.:
            #     rf_movement_x *= action_norm
            #     rf_movement_y *= action_norm

            rf_movement_x = min(max(-1, action.view[0]), 1)
            rf_movement_y = min(max(-1, action.view[1]), 1)

            delta_direction = cmath.atan2(rf_movement_y, rf_movement_x)

            # Move the rover forward.
            rover_direction = rover_datum.direction()
            gf_rover_unit_direction_x = cmath.cos(rover_direction)
            gf_rover_unit_direction_y = cmath.sin(rover_direction)

            gf_movement_x = (
                gf_rover_unit_direction_x
                * rf_movement_x
                - gf_rover_unit_direction_y
                * rf_movement_y)
            gf_movement_y = (
                gf_rover_unit_direction_x
                * rf_movement_y
                + gf_rover_unit_direction_y
                * rf_movement_x)

            rover_datum.set_position_x(
                rover_datum.position_x()
                + gf_movement_x )
            rover_datum.set_position_y(
                rover_datum.position_y()
                + gf_movement_y )

            # Rotate the rover.
            rover_datum.set_direction(
                rover_datum.direction() + delta_direction)

@cython.warn.undeclared(True)
cdef DefaultDynamicsProcessor new_DefaultDynamicsProcessor():
    cdef DefaultDynamicsProcessor processor

    processor = DefaultDynamicsProcessor.__new__(DefaultDynamicsProcessor)
    init_DefaultDynamicsProcessor(processor)

    return processor

@cython.warn.undeclared(True)
cdef void init_DefaultDynamicsProcessor(
        DefaultDynamicsProcessor processor
        ) except *:
    if processor is None:
        raise (
            TypeError(
                "The dynamics processor (processor) cannot be None." ))


