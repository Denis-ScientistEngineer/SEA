# abstract_solver.jl - The Contract for All Physics Solvers
# NOW WITH SYSTEM CONTEXT AWARENESS!

include("system_context.jl")

# =============================================================================
# THE SOLVER CONTRACT
# =============================================================================

"""
    PhysicsSolver

Abstract type for all physics solvers.
Each solver must implement the required functions below.
"""
abstract type PhysicsSolver end

# =============================================================================
# REQUIRED FUNCTIONS (Every solver MUST implement these)
# =============================================================================

"""
    can_solve(solver, variables, context) -> Bool

Check if this solver can handle the given variables AND physical context.

The context parameter is CRITICAL - it ensures we don't apply:
- Classical thermodynamics at quantum scales
- Ideal gas law at relativistic speeds
- Quantum mechanics to macroscopic objects

Arguments:
- solver: The solver instance
- variables: Set of variable symbols present in input
- context: SystemContext describing the physical regime

Returns:
- true if solver is applicable, false otherwise
"""
function can_solve(solver::PhysicsSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    # Default implementation without context (backward compatible)
    return can_solve(solver, variables)
end

# Fallback for solvers that don't implement context version
function can_solve(solver::PhysicsSolver, variables::Set{Symbol})::Bool
    error("$(typeof(solver)) must implement can_solve(solver, variables) or can_solve(solver, variables, context)")
end

"""
    solve(solver, values) -> Dict{Symbol, Float64}

Perform the actual physics calculation.

Arguments:
- solver: The solver instance
- values: Dictionary of variable names to values

Returns:
- Updated dictionary with computed values added
"""
function solve(solver::PhysicsSolver, values::Dict{Symbol, Float64})
    error("$(typeof(solver)) must implement solve()")
end

"""
    get_domain(solver) -> Symbol

Return which physics domain this solver belongs to.

Returns:
- Domain symbol (e.g., :thermodynamics, :electromagnetics, :mechanics)
"""
function get_domain(solver::PhysicsSolver)::Symbol
    error("$(typeof(solver)) must implement get_domain()")
end

# =============================================================================
# OPTIONAL FUNCTIONS (Provide defaults but can be overridden)
# =============================================================================

"""
    get_priority(solver) -> Int

Return solver priority (higher = more specific/preferred).

Default: 50 (medium priority)
Range: 0-100
- 90-100: Very specific (e.g., finite line charge with exact geometry)
- 70-89:  Specific (e.g., ideal gas, Coulomb force)
- 50-69:  General (e.g., first law of thermodynamics)
- 30-49:  Very general (catch-all solvers)
"""
function get_priority(solver::PhysicsSolver)::Int
    return 50
end

"""
    validate_inputs(solver, values) -> Bool

Check if the provided values are sufficient and valid for solving.

This goes beyond can_solve - it checks:
- Are there enough known values?
- Are values in valid ranges?
- Are combinations physically meaningful?

Default: true (assume valid)
"""
function validate_inputs(solver::PhysicsSolver, values::Dict{Symbol, Float64})::Bool
    return true
end

"""
    get_description(solver) -> String

Return human-readable description of what this solver does.

Default: Just the type name
"""
function get_description(solver::PhysicsSolver)::String
    return string(typeof(solver))
end

"""
    get_required_regime(solver) -> ScaleRegime

Return which physical regime this solver is valid in.

Default: CLASSICAL_MACRO (most solvers)
Override for quantum, relativistic, or statistical solvers!
"""
function get_required_regime(solver::PhysicsSolver)::ScaleRegime
    return CLASSICAL_MACRO
end

"""
    get_required_substance(solver) -> Vector{SubstanceType}

Return which substance types this solver can handle.

Default: Empty vector (no restriction)
Override to restrict to specific substances!
"""
function get_required_substance(solver::PhysicsSolver)::Vector{SubstanceType}
    return SubstanceType[]  # Empty = no restriction
end

"""
    get_physics_type(solver) -> Symbol

Return the specific physics this solver implements.

Used for regime validation.
Examples: :ideal_gas_law, :coulombs_law, :first_law_thermodynamics
"""
function get_physics_type(solver::PhysicsSolver)::Symbol
    return :unknown
end

"""
    is_context_compatible(solver, context) -> Bool

Check if this solver is compatible with the given physical context.

This is the KEY VALIDATION - ensures physics matches reality!

Default implementation checks:
1. Regime compatibility
2. Substance compatibility  
3. Physics-specific validation

Override for custom compatibility rules!
"""
function is_context_compatible(solver::PhysicsSolver, context::SystemContext)::Bool
    # Check regime compatibility
    required_regime = get_required_regime(solver)
    if required_regime != CLASSICAL_MACRO && context.regime != required_regime
        return false
    end
    
    # Check substance compatibility
    required_substances = get_required_substance(solver)
    if !isempty(required_substances)
        if !(context.substance in required_substances)
            return false
        end
    end
    
    # Check physics validity in this regime
    physics_type = get_physics_type(solver)
    if physics_type != :unknown
        if !is_regime_valid(context, physics_type)
            return false
        end
    end
    
    return true
end

# =============================================================================
# WEEK 2 ENHANCEMENTS: METADATA AND UNITS
# =============================================================================

"""
    get_equation(solver) -> String

Return the equation this solver implements (for display).

Default: Empty string
Example: "PV = nRT", "F = kQ₁Q₂/r²", "ΔU = Q - W"
"""
function get_equation(solver::PhysicsSolver)::String
    return ""
end

"""
    get_output_units(solver) -> Dict{Symbol, String}

Return the physical units of output variables.

Default: Empty dict (no units specified)
Example: Dict(:E => "N/C", :V => "V", :F => "N")
"""
function get_output_units(solver::PhysicsSolver)::Dict{Symbol, String}
    return Dict{Symbol, String}()
end

"""
    get_input_constraints(solver) -> Dict{Symbol, String}

Return constraints on input variables (for validation).

Default: Empty dict
Example: Dict(:T => "T > 0", :P => "P > 0", :v => "v < c")
"""
function get_input_constraints(solver::PhysicsSolver)::Dict{Symbol, String}
    return Dict{Symbol, String}()
end

# =============================================================================
# HELPER FUNCTIONS FOR SOLVER DEVELOPERS
# =============================================================================

"""
    check_positive(values, vars...) -> Bool

Helper: Check if specified variables are all positive.
"""
function check_positive(values::Dict{Symbol, Float64}, vars::Symbol...)::Bool
    for var in vars
        if haskey(values, var) && values[var] <= 0
            return false
        end
    end
    return true
end

"""
    check_range(value, min_val, max_val) -> Bool

Helper: Check if value is in valid range.
"""
function check_range(value::Float64, min_val::Float64, max_val::Float64)::Bool
    return min_val <= value <= max_val
end

"""
    get_any(values, vars...) -> Union{Float64, Nothing}

Helper: Get first available variable from a list of aliases.
"""
function get_any(values::Dict{Symbol, Float64}, vars::Symbol...)
    for var in vars
        if haskey(values, var)
            return values[var]
        end
    end
    return nothing
end