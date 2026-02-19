# Contains ALL thermodynamic solvers and does the actual math
#= Solvers in this file:
    1. FirstLawSolver
    2. IdealGasLaw
=#


include("abstract_solver.jl")

# 1: First law of thermodynamics : ∆U = Q - W

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

get_domain(::FirstLawSolver) = :thermo