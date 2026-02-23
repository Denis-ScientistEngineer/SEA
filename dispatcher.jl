# the routing file

# PURPOSE:: This is the TRAFFIC CONTROLLER of the entire system
#=
    1. recieve the dict of vlues from tokenizer.jl
    2. Ask each solver in the registry: "can you handle these variables?"
    3. send the dict the 1st solver that says yes
    4. return the result
=#


# THE MAIN DISPATCHER function

function find_solver(variables::Set{Symbol})::Union{PhysicsSolver, Nothing}
    println("→Dispatcher searching for solver that can handles: $variables")

    #Ask every solver in the registry
    for solver in get_all_solvers()
        if can_solve(solver, variables)
            println(" →Dispatcher found: $(typeof(solver))")
            return solver
        end
    end

    # Nobody says yes
    println(" →Dispatcher: No solver found for variables: $variables")
    return nothing
end


# This combines finding + solving into one step

function dispatch_and_solve(values::Dict{Symbol, Float64})
    # Extract variable names Only
    variable_names = Set(keys(values))

    # ask the registry to find us a solver
    solver = find_solver(variable_names)

    # if nobody can solve this stop here
    if solver === nothing
        println("\n Error: No solver found.")
        println("Variables you provided: $(join(variable_names, ","))")
        println("Registered solvers handle: ")
        for s in get_all_solvers()
            println("   .$(typeof(s))")
        end
        return nothing
    end

    # I found a solver! Run it.
    println("→Dispatching to $(typeof(solver))...")
    result = solve(solver, values)

    return (solver=solver, result=result)
end
