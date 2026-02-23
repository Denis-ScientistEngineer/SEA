function dispatch_and_solve(values::Dict{Symbol, Float64})
    variable_names = Set(keys(values))
    
    for solver in get_all_solvers()
        if can_solve(solver, variable_names)
            result = solve(solver, values)
            return (solver=solver, result=result)
        end
    end
    
    return nothing
end
