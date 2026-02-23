# the contract file
# Here are the rules:

abstract type PhysicsSolver end

# RULE 1: Every solver must have  can_solve() function
# Dispatcher will call this to ask if it can do the task

function can_solve(solver::PhysicsSolver, variables::Set{Symbol})::Bool
    error("$(typeof(solver)) must impelement can_solve function!")
end


# RULE 2: Every solver must have a solve() functon
# Dispatcher will call this after finding the right solver

function solve(solver::PhysicsSolver, values::Dict{Symbol, Float64})
    error("$(typeof(solver)) must implement solve()!")
end


#RULE 3: Every solver must have a get_domain() function
# This tells us which domain(file) it belongs to

function get_domain(solver::PhysicsSolver)::Symbol
    error("$(typeof(solver)) must implement get_domain()!")
end
