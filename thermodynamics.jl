include("abstract_solver.jl")

# =============================================================================
# FIRST LAW OF THERMODYNAMICS: ΔU = Q - W
# =============================================================================

struct FirstLawSolver <: PhysicsSolver end

function can_solve(::FirstLawSolver, variables::Set{Symbol})::Bool
    our_vars = Set([:Q, :q, :heat, :W, :w, :work, :U, :u, :ΔU, :deltaU, :dU])
    return length(intersect(variables, our_vars)) >= 2
end

function validate_inputs(::FirstLawSolver, values::Dict{Symbol, Float64})::Bool
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    W = get(values, :W, get(values, :w, get(values, :work, nothing)))
    U = get(values, :U, get(values, :u, get(values, :ΔU, get(values, :deltaU, get(values, :dU, nothing)))))
    
    # Need EXACTLY 2 known values to solve for the third
    known = count(!isnothing, [Q, W, U])
    return known == 2
end

function get_priority(::FirstLawSolver)::Int
    return 60  # High priority - fundamental law
end

function get_description(::FirstLawSolver)::String
    return "First Law of Thermodynamics (ΔU = Q - W)"
end

function solve(::FirstLawSolver, values::Dict{Symbol, Float64})
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    W = get(values, :W, get(values, :w, get(values, :work, nothing)))
    U = get(values, :U, get(values, :u, get(values, :ΔU, get(values, :deltaU, get(values, :dU, nothing)))))
    
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

get_domain(::FirstLawSolver) = :thermodynamics

# =============================================================================
# IDEAL GAS LAW: PV = nRT
# =============================================================================

struct IdealGasSolver <: PhysicsSolver end

function can_solve(::IdealGasSolver, variables::Set{Symbol})::Bool
    our_vars = Set([:P, :p, :pressure, :V, :v, :volume, :n, :moles, :T, :t, :temperature])
    return length(intersect(variables, our_vars)) >= 3
end

function validate_inputs(::IdealGasSolver, values::Dict{Symbol, Float64})::Bool
    P = get(values, :P, get(values, :p, get(values, :pressure, nothing)))
    V = get(values, :V, get(values, :v, get(values, :volume, nothing)))
    n = get(values, :n, get(values, :moles, nothing))
    T = get(values, :T, get(values, :t, get(values, :temperature, nothing)))
    
    # Need EXACTLY 3 known values to solve for the fourth
    known = count(!isnothing, [P, V, n, T])
    return known == 3
end

function get_priority(::IdealGasSolver)::Int
    return 70  # Higher priority - very specific variables
end

function get_description(::IdealGasSolver)::String
    return "Ideal Gas Law (PV = nRT)"
end

function solve(::IdealGasSolver, values::Dict{Symbol, Float64})
    R = 8.314  # J/(mol·K)
    
    P = get(values, :P, get(values, :p, get(values, :pressure, nothing)))
    V = get(values, :V, get(values, :v, get(values, :volume, nothing)))
    n = get(values, :n, get(values, :moles, nothing))
    T = get(values, :T, get(values, :t, get(values, :temperature, nothing)))
    
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

get_domain(::IdealGasSolver) = :thermodynamics

# =============================================================================
# HEAT CAPACITY: Q = mcΔT
# =============================================================================

struct HeatCapacitySolver <: PhysicsSolver end

function can_solve(::HeatCapacitySolver, variables::Set{Symbol})::Bool
    our_vars = Set([:Q, :q, :heat, :m, :mass, :c, :specific_heat, :ΔT, :deltaT, :dT])
    has_Q = any(v in variables for v in [:Q, :q, :heat])
    has_m = any(v in variables for v in [:m, :mass])
    has_c = any(v in variables for v in [:c, :specific_heat])
    has_T = any(v in variables for v in [:ΔT, :deltaT, :dT])
    
    return count([has_Q, has_m, has_c, has_T]) >= 3
end

function validate_inputs(::HeatCapacitySolver, values::Dict{Symbol, Float64})::Bool
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    m = get(values, :m, get(values, :mass, nothing))
    c = get(values, :c, get(values, :specific_heat, nothing))
    ΔT = get(values, :ΔT, get(values, :deltaT, get(values, :dT, nothing)))
    
    # Need EXACTLY 3 known values to solve for the fourth
    known = count(!isnothing, [Q, m, c, ΔT])
    return known == 3
end

function get_priority(::HeatCapacitySolver)::Int
    return 65  # High priority - specific to heat transfer
end

function get_description(::HeatCapacitySolver)::String
    return "Heat Capacity (Q = mcΔT)"
end

function solve(::HeatCapacitySolver, values::Dict{Symbol, Float64})
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    m = get(values, :m, get(values, :mass, nothing))
    c = get(values, :c, get(values, :specific_heat, nothing))
    ΔT = get(values, :ΔT, get(values, :deltaT, get(values, :dT, nothing)))
    
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

get_domain(::HeatCapacitySolver) = :thermodynamics

