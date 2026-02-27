# thermodynamics.jl - Context-Aware Thermodynamics Solvers
include("abstract_solver.jl")

# =============================================================================
# FIRST LAW OF THERMODYNAMICS: ΔU = Q - W
# =============================================================================

struct FirstLawSolver <: PhysicsSolver end

# Basic compatibility
function can_solve(::FirstLawSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    # Only valid in classical regime!
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    our_vars = Set([:Q, :q, :heat, :W, :w, :work, :U, :u, :ΔU, :deltaU, :dU])
    return length(intersect(variables, our_vars)) >= 2
end

function validate_inputs(::FirstLawSolver, values::Dict{Symbol, Float64})::Bool
    Q = get_any(values, :Q, :q, :heat)
    W = get_any(values, :W, :w, :work)
    U = get_any(values, :U, :u, :ΔU, :deltaU, :dU)
    
    # Need EXACTLY 2 known values
    known = count(!isnothing, [Q, W, U])
    return known == 2
end

# Context awareness
get_required_regime(::FirstLawSolver) = CLASSICAL_MACRO
get_physics_type(::FirstLawSolver) = :classical_thermodynamics
get_priority(::FirstLawSolver) = 60

# Metadata
get_description(::FirstLawSolver) = "First Law of Thermodynamics (ΔU = Q - W)"
get_equation(::FirstLawSolver) = "ΔU = Q - W"
get_domain(::FirstLawSolver) = :thermodynamics

function get_output_units(::FirstLawSolver)::Dict{Symbol, String}
    return Dict(
        :Q => "J",
        :W => "J",
        :ΔU => "J",
        :U => "J"
    )
end

function get_input_constraints(::FirstLawSolver)::Dict{Symbol, String}
    return Dict(
        :Q => "Energy in Joules",
        :W => "Work in Joules (positive = done by system)",
        :ΔU => "Internal energy change in Joules"
    )
end

# Solver implementation
function solve(::FirstLawSolver, values::Dict{Symbol, Float64})
    Q = get_any(values, :Q, :q, :heat)
    W = get_any(values, :W, :w, :work)
    U = get_any(values, :U, :u, :ΔU, :deltaU, :dU)
    
    if isnothing(U)
        U = Q - W
        values[:ΔU] = U
    elseif isnothing(Q)
        Q = U + W
        values[:Q] = Q
    elseif isnothing(W)
        W = Q - U
        values[:W] = W
    end
    
    return values
end

# =============================================================================
# IDEAL GAS LAW: PV = nRT
# =============================================================================

struct IdealGasSolver <: PhysicsSolver end

function can_solve(::IdealGasSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    # Only valid for ideal gases in classical regime!
    if context.regime != CLASSICAL_MACRO
        return false
    end
    if context.substance != IDEAL_GAS && context.substance != IDEAL_GAS
        # Allow if substance not yet determined
        if context.substance != IDEAL_GAS
            return false
        end
    end
    
    our_vars = Set([:P, :p, :pressure, :V, :v, :volume, :n, :moles, :T, :t, :temperature])
    return length(intersect(variables, our_vars)) >= 3
end

function validate_inputs(::IdealGasSolver, values::Dict{Symbol, Float64})::Bool
    P = get_any(values, :P, :p, :pressure)
    V = get_any(values, :V, :v, :volume)
    n = get_any(values, :n, :moles)
    T = get_any(values, :T, :t, :temperature)
    
    # Need EXACTLY 3 known values
    known = count(!isnothing, [P, V, n, T])
    
    # Also check validity ranges
    if !isnothing(P) && P <= 0
        return false
    end
    if !isnothing(V) && V <= 0
        return false
    end
    if !isnothing(n) && n <= 0
        return false
    end
    if !isnothing(T) && T <= 0
        return false
    end
    
    return known == 3
end

get_required_regime(::IdealGasSolver) = CLASSICAL_MACRO
get_required_substance(::IdealGasSolver) = [IDEAL_GAS]
get_physics_type(::IdealGasSolver) = :ideal_gas_law
get_priority(::IdealGasSolver) = 70

get_description(::IdealGasSolver) = "Ideal Gas Law (PV = nRT)"
get_equation(::IdealGasSolver) = "PV = nRT, R = 8.314 J/(mol·K)"
get_domain(::IdealGasSolver) = :thermodynamics

function get_output_units(::IdealGasSolver)::Dict{Symbol, String}
    return Dict(
        :P => "Pa",
        :V => "m³",
        :n => "mol",
        :T => "K"
    )
end

function get_input_constraints(::IdealGasSolver)::Dict{Symbol, String}
    return Dict(
        :P => "P > 0 (not too high for ideal behavior)",
        :V => "V > 0",
        :n => "n > 0",
        :T => "T > 0 (not too low for ideal behavior)"
    )
end

function solve(::IdealGasSolver, values::Dict{Symbol, Float64})
    R = 8.314  # J/(mol·K)
    
    P = get_any(values, :P, :p, :pressure)
    V = get_any(values, :V, :v, :volume)
    n = get_any(values, :n, :moles)
    T = get_any(values, :T, :t, :temperature)
    
    if isnothing(n)
        n = (P * V) / (R * T)
        values[:n] = n
    elseif isnothing(P)
        P = (n * R * T) / V
        values[:P] = P
    elseif isnothing(V)
        V = (n * R * T) / P
        values[:V] = V
    elseif isnothing(T)
        T = (P * V) / (n * R)
        values[:T] = T
    end
    
    return values
end

# =============================================================================
# HEAT CAPACITY: Q = mcΔT
# =============================================================================

struct HeatCapacitySolver <: PhysicsSolver end

function can_solve(::HeatCapacitySolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    our_vars = Set([:Q, :q, :heat, :m, :mass, :c, :specific_heat, :ΔT, :deltaT, :dT])
    has_Q = any(v in variables for v in [:Q, :q, :heat])
    has_m = any(v in variables for v in [:m, :mass])
    has_c = any(v in variables for v in [:c, :specific_heat])
    has_T = any(v in variables for v in [:ΔT, :deltaT, :dT])
    
    return count([has_Q, has_m, has_c, has_T]) >= 3
end

function validate_inputs(::HeatCapacitySolver, values::Dict{Symbol, Float64})::Bool
    Q = get_any(values, :Q, :q, :heat)
    m = get_any(values, :m, :mass)
    c = get_any(values, :c, :specific_heat)
    ΔT = get_any(values, :ΔT, :deltaT, :dT)
    
    known = count(!isnothing, [Q, m, c, ΔT])
    
    # Validate positive values where required
    if !isnothing(m) && m <= 0
        return false
    end
    if !isnothing(c) && c <= 0
        return false
    end
    
    return known == 3
end

get_required_regime(::HeatCapacitySolver) = CLASSICAL_MACRO
get_physics_type(::HeatCapacitySolver) = :classical_thermodynamics
get_priority(::HeatCapacitySolver) = 65

get_description(::HeatCapacitySolver) = "Heat Capacity (Q = mcΔT)"
get_equation(::HeatCapacitySolver) = "Q = mcΔT"
get_domain(::HeatCapacitySolver) = :thermodynamics

function get_output_units(::HeatCapacitySolver)::Dict{Symbol, String}
    return Dict(
        :Q => "J",
        :m => "kg",
        :c => "J/(kg·K)",
        :ΔT => "K"
    )
end

function get_input_constraints(::HeatCapacitySolver)::Dict{Symbol, String}
    return Dict(
        :m => "m > 0",
        :c => "c > 0 (material property)",
        :ΔT => "Temperature change in Kelvin"
    )
end

function solve(::HeatCapacitySolver, values::Dict{Symbol, Float64})
    Q = get_any(values, :Q, :q, :heat)
    m = get_any(values, :m, :mass)
    c = get_any(values, :c, :specific_heat)
    ΔT = get_any(values, :ΔT, :deltaT, :dT)
    
    if isnothing(Q)
        Q = m * c * ΔT
        values[:Q] = Q
    elseif isnothing(m)
        m = Q / (c * ΔT)
        values[:m] = m
    elseif isnothing(c)
        c = Q / (m * ΔT)
        values[:c] = c
    elseif isnothing(ΔT)
        ΔT = Q / (m * c)
        values[:ΔT] = ΔT
    end
    
    return values
end