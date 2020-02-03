# cython: language_level=3

from .state cimport State
from .base_rover_observations_calculator cimport BaseRoverObservationsCalculator
from .base_dynamics_processor cimport BaseDynamicsProcessor
from .base_evaluator cimport BaseEvaluator


cdef class RoverDomain:
    cdef public State m_current_state
    cdef public State m_setting_state_ref
    cdef public BaseEvaluator m_evaluator_ref
    cdef public BaseDynamicsProcessor m_dynamics_processor_ref
    cdef public BaseRoverObservationsCalculator m_rover_observations_calculator_ref
    cdef public Py_ssize_t m_n_steps_elapsed
    cdef public Py_ssize_t m_n_rover_action_dims
    cdef public Py_ssize_t m_setting_n_rover_action_dims
    cdef public Py_ssize_t m_n_steps
    cdef public Py_ssize_t m_setting_n_steps
    cdef public Py_ssize_t m_n_rovers
    cdef public Py_ssize_t m_n_rover_observation_dims
    cdef public object[::1] m_state_history_store
    # State[n_steps]
    cdef public double[:, :, ::1] m_rover_actions_history_store
    # double[n_steps, n_rovers, n_rover_action_dims]
        
    
    cpdef object copy(self)
    cpdef object copy_via(self, object store)
        
    cpdef State current_state_copy(self)
    cpdef State current_state_via(self, State store)
    
    cpdef State setting_state_ref(self)
    cpdef void set_setting_state_ref(self, State state) except *
    
    cpdef BaseEvaluator evaluator_ref(self)
    cpdef void set_evaluator_ref(self, BaseEvaluator evaluator) except *
    
    cpdef BaseDynamicsProcessor dynamics_processor_ref(self)
    cpdef void set_dynamics_processor_ref(
        self, 
        BaseDynamicsProcessor dynamics_processor
        ) except *
        
    cpdef BaseRoverObservationsCalculator rover_observations_calculator_ref(
        self
        )
    cpdef void set_rover_observations_calculator_ref(
        self,
        BaseRoverObservationsCalculator rover_observations_calculator
        ) except *
    
    cpdef Py_ssize_t n_steps_elapsed(self) except *
    
    cpdef Py_ssize_t n_rover_action_dims(self) except *
    
    cpdef object[:] state_history_copy(self) except *
    cpdef object[:] state_history_via(self, object[:] store) except *
    # State[n_steps_elapsed]
        
    cpdef Py_ssize_t n_steps(self) except *
    
    cpdef Py_ssize_t setting_n_steps(self) except *
    cpdef void set_setting_n_steps(self, Py_ssize_t n_steps) except *

    cpdef Py_ssize_t n_rovers(self) except *
    
    cpdef Py_ssize_t n_pois(self) except *

    cpdef double[:, :] rover_positions_copy(self) except *
    cpdef double[:, :] rover_positions_via(self, double[:, :] store) except *
    cpdef void set_rover_positions(
        self, 
        const double[:, :] rover_positions
        ) except *
        
        
    cpdef double[:, :] rover_orientations_copy(self) except *
    cpdef double[:, :] rover_orientations_via(self, double[:, :] store) except *
    cpdef void set_rover_orientations(
        self, 
        const double[:, :] rover_orientations
        ) except *
        
    cpdef double[:] poi_values_copy(self) except *
    cpdef double[:] poi_values_via(self, double[:] store) except *
    cpdef void set_poi_values(self, const double[:] poi_values) except *
    
    cpdef double[:, :] poi_positions_copy(self) except *
    cpdef double[:, :] poi_positions_via(self, double[:, :] store) except *
    cpdef void set_poi_positions(
        self, 
        const double[:, :] poi_positions
        ) except *
    
    cpdef bint done(self) except *
        
    cpdef double[:, :, :] rover_actions_history_copy(self) except *
    cpdef double[:, :, :] rover_actions_history_via(
        self, 
        double[:, :, :] store
        ) except *
    # double[n_steps_elapsed, n_rovers, n_rover_action_dims]
     
    cpdef double[:, :] rover_observations_copy(self) except *
    cpdef double[:, :] rover_observations_via(self, double[:, :] store) except *
    # double[n_rovers, n_rover_observation_dims]
    
    cpdef double eval(self) except *
    
    cpdef double[:] rover_evals_copy(self) except *
    cpdef double[:] rover_evals_via(self, double[:] rover_evals) except *
    # double[n_rovers]
    
    cpdef void reset(self) except *
        
    cpdef void step(self, const double[:, :] rover_actions) except *
    
    