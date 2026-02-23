include("abstract_solver.jl")

# First Law: ΔU = Q - W
struct FirstLawSolver <: PhysicsSolver end

function can_solve(::FirstLawSolver, variables::Set{Symbol})::Bool
    our_vars = Set([:Q, :q, :heat, :W, :w, :work, :U, :u, :ΔU, :deltaU, :dU])
    return length(intersect(variables, our_vars)) >= 2
end

function solve(::FirstLawSolver, values::Dict{Symbol, Float64})
    Q = get(values, :Q, get(values, :q, get(values, :heat, nothing)))
    W = get(values, :W, get(values, :w, get(values, :work, nothing)))
    U = get(values, :U, get(values, :u, get(values, :ΔU, get(values, :deltaU, get(values, :dU, nothing)))))
    
    known = count(!isnothing, [Q, W, U])
    if known < 2
        error("Need at least 2 values")
    end
    
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
