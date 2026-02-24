# the routing file

# PURPOSE:: This is the TRAFFIC CONTROLLER of the entire system
#=
    1. recieve the dict of vlues from tokenizer.jl
    2. Ask each solver in the registry: "can you handle these variables?"
    3. send the dict the 1st solver that says yes
    4. return the result
=#


# THE MAIN DISPATCHER function

# Find the best solver for given variables
function find_solver(values::Dict{Symbol, Float64})
    variable_names = Set(keys(values))
    candidates = []
    
    # Find all solvers that CAN handle these variables
    for solver in get_all_solvers()
        if can_solve(solver, variable_names)
            # Also check if inputs are actually valid
            if validate_inputs(solver, values)
                priority = get_priority(solver)
                push!(candidates, (solver=solver, priority=priority))
            end
        end
    end
    
    # Sort by priority (highest first)
    sort!(candidates, by=x -> x.priority, rev=true)
    
    # Return the highest priority solver
    if !isempty(candidates)
        return candidates[1].solver
    end
    
    return nothing
end

# Dispatch and solve
function dispatch_and_solve(values::Dict{Symbol, Float64})
    solver = find_solver(values)
    
    if solver === nothing
        return nothing
    end
    
    try
        result = solve(solver, values)
        return (solver=solver, result=result)
    catch e
        println("⚠️  Solver $(typeof(solver)) failed: $e")
        return nothing
    end
end

# NEW: Get all matching solvers (for debugging/testing)
function find_all_matching_solvers(values::Dict{Symbol, Float64})
    variable_names = Set(keys(values))
    matches = []
    
    for solver in get_all_solvers()
        can_handle = can_solve(solver, variable_names)
        is_valid = can_handle ? validate_inputs(solver, values) : false
        priority = get_priority(solver)
        
        push!(matches, Dict(
            "solver" => string(typeof(solver)),
            "can_handle" => can_handle,
            "is_valid" => is_valid,
            "priority" => priority,
            "description" => get_description(solver)
        ))
    end
    
    return matches
end
