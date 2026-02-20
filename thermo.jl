# Contains ALL thermodynamic solvers and does the actual math
#= Solvers in this file:
    1. FirstLawSolver
    2. Ideal Gas Law: PV = nRT
    3. Heat Capacity: Q = mcΔT
=#


include("abstract_solver.jl")

# Solver 1: First law of thermodynamics : ∆U = Q - W


struct FirstLawSolver <: PhysicsSolver end

function can_solve(::FirstLawSolver, variables::Set{Symbol})::Bool
    #All the names a user might use for our three variables
    our_variables = Set([
        :Q, :q, :heat,
        :W, :w, :work,
        :U, :u, :deltaU, :dU, :∆U
    ])

    #How many of the user's variables do you recognize?
    matches = length(intersect(variables, our_variables))

    return matches >= 2
end


function solve(::FirstLawSolver, values::Dict{Symbol, Float64})
    # step 1: Extract variables( handle all the names the user might have used)
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    W = get(values, :W, get(values, :w, get(values, :work, nothing)))
    U = get(values, :U, get(values, :u, get(values, :internalenergy, get(values, :dU, get(values, :deltaU, get(values, :∆U, nothing))))))

    # step 2: validate: we need exactly 2 known values
    known = count(!isnothing, [Q, W, U])
    if known < 2
        error("First Law needs at least 2 of the values in the formula: ∆U = Q - W")
    end

    #step 3: solve for the unknown using ∆U = Q - W
    if isnothing(U)
        U = Q - W
        values[:∆U] = U
        values[:unknown_was] = 0.0  # marker (0 = found ∆U)
    elseif isnothing(Q)
        Q = U + W
        values[:Q] = Q
        values[:unknown_was] = 1.0 # marker (1 = found Q)
    elseif isnothing(W)
        W = Q - U
        values[:W] = W
        values[:unknown_was] = 2.0  # marker (2 = found w)
    end

    return values
end

# rule 3: which domain does this belong to? (used for display purposes)
get_domain(::FirstLawSolver) = :thermo


# =============================================================================
# SOLVER 2: IDEAL GAS LAW: PV = nRT
# =============================================================================

struct IdealGasSolver <: PhysicsSolver end

function can_solve(::IdealGasSolver, variables::Set{Symbol})::Bool
    our_variables = Set([
        :p, :pressure, :P,
        :V, :v, :volume,
        :n, :moles,
        :T, :temp, :temperature
    ])

    matches = length(intersect(variables, our_variables))

    return matches >= 3 # we need at least 3 of the 4 variables to solve for the unknown
end

function solve(::IdealGasSolver, values::Dict{Symbol, Float64})
    P = get(values, :P, get(values, :p, get(values, :pressure, nothing)))
    V = get(values, :V, get(values, :v, get(values, :volume, nothing)))
    n = get(values, :n, get(values, :moles, nothing))
    T = get(values, :T, get(values, :temp, get(values, :temperature, nothing)))

    R = 8.3145 # universal gas constant in J/(mol·K)
    # PV = nRT - solve for the unknown

    if isnothing(P)
        P = (n*R*T) / V
        values[:P] = P
    elseif isnothing(V)
        V = ((n*R*T) / P)
        values[:P] = P
    elseif isnothing(n)
        n = (P*V) / (R * T)
        values[:n] = n
    elseif isnothing(T)
        T = (P*V) / (R * n)
        values[:T] = T
    end

    return values
end

get_domain(::IdealGasSolver) = :thermo


# =============================================================================
# Solver 3: Heat Capcity: Q = mcΔT
# =============================================================================

struct HeatCapacitySolver <: PhysicsSolver end


function can_solve(::HeatCapacitySolver, variables::Set{Symbol})::Bool
    our_variables = Set([
        :Q, :q, :heat,
        :m, :M, :mass,
        :T, :temp, :temperature, :deltaT, :dt, :ΔT,
        :c, :C, :specificheat, :specific_heat
    ])

    matches = length(intersect(variables, our_variables))

    return matches >= 3
end


function solve(::HeatCapacitySolver, values::Dict{Symbol, Float64})
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    m = get(values, :m, get(values, :M, get(values, :mass, nothing)))
    c = get(values, :c, get(values, :C, get(values, :specificheat, get(values, :specific_heat, nothing))))
    ΔT = get(values, :deltaT, get(values, :temp, get(values, :temperature, get(values, :dt, get(values, :ΔT, nothing)))))

    # Q = mcΔT - solve for the unknown

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

get_domain(::HeatCapacitySolver) = :thermo

