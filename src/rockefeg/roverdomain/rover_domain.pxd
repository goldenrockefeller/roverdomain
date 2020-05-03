# cython: language_level=3
cdef RoverDomain new_RoverDomain()
cdef void init_RoverDomain(RoverDomain domain) except *

cdef class RoverDomain:
    cdef __current_state
    cdef __setting_state
    cdef __evaluator
    cdef __dynamics_processor
    cdef __rover_observations_calculator
    cdef Py_ssize_t __n_steps_elapsed
    cdef Py_ssize_t __n_steps
    cdef Py_ssize_t __setting_n_steps
    cdef __state_history
    # list<State>[n_steps]
    cdef __actions_history
    # list<list<DoubleArray>>[n_steps, n_rovers, n_action_dims]
        
    cpdef copy(self, copy_obj = ?)
    
    cpdef bint episode_is_done(self) except *
     
    cpdef list rover_observations(self)
    # list<DoubleArray>[n_observation_dims, n_rovers]
    
    cpdef double eval(self) except *
    
    cpdef rover_evals(self)
    # DoubleArray[n_rovers]
    
    cpdef void reset(self) except *
        
    cpdef void step(self, list rover_actions) except *
    # list<DoubleArray>[n_rovers, n_observation_dims]
    
    cpdef current_state(self)
    cpdef void set_current_state(self, state) except *
    
    cpdef setting_state(self)    
    cpdef void set_setting_state(self, state) except *
        
    cpdef evaluator(self)        
    cpdef void set_evaluator(self, evaluator) except *
    
    cpdef dynamics_processor(self)    
    cpdef void set_dynamics_processor(self, dynamics_processor) except *
    
    cpdef rover_observations_calculator(self)    
    cpdef void set_rover_observations_calculator(
        self,
        rover_observations_calculator
        ) except *
    
    cpdef Py_ssize_t setting_n_steps(self)
    cpdef void set_setting_n_steps(self, Py_ssize_t n_steps) except *
    
    cpdef Py_ssize_t n_steps_elapsed(self)
    
    cpdef void _set_n_steps_elapsed(self, Py_ssize_t n_steps_elapsed) except *
    # Protected
    
    cpdef Py_ssize_t n_steps(self)
    
    cpdef void _set_n_steps(self, Py_ssize_t n_steps) except *
    # Protected
    
    cpdef state_history(self)
    
    cpdef void _set_state_history(self, state_history) except *
    # Protected
    
    cpdef actions_history(self)
    
    cpdef void _set_actions_history(self, actions_history) except *
    # Protected
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    