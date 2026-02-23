# The contract that all solvers must follow
abstract type PhysicsSolver end

function can_solve(solver::PhysicsSolver, variables::Set{Symbol})::Bool
    error("$(typeof(solver)) must implement can_solve()")
end

function solve(solver::PhysicsSolver, values::Dict{Symbol, Float64})
    error("$(typeof(solver)) must implement solve()")
end

function get_domain(solver::PhysicsSolver)::Symbol
    error("$(typeof(solver)) must implement get_domain()")
end
