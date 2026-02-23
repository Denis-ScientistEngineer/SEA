# File that stores all available solvers
# It knows which departments exist and how to reach them

const SOLVER_REGISTRY = Vector{PhysicsSolver}()

function register_solver(solver::PhysicsSolver)
    push!(SOLVER_REGISTRY, solver)
    println(" ✓ Registered: $(typeof(solver)) [domain: $(get_domain(solver))]")
end


# LIST: Show everything available in the registry (useful for debugging)

function list_registered_solvers()
    println("\n Registered solvers ($(length(SOLVER_REGISTRY)) total): ")
    
    if isempty(SOLVER_REGISTRY)
        println("   (none registered yet)")
    else
        for (i, solver) in enumerate(SOLVER_REGISTRY)
            println("   $i. $(typeof(solver)) - domain: $(get_domain(solver))")
        end
    end

    println("   " * "*"^45)
end


# CLEAR: Remove all solvers (useful for testing or reloading)

function clear_registry()
    empty!(SOLVER_REGISTRY)
    println("Registry cleared.")
end


#   GET ALL SOLVERS: Returns the full list(used by dispatcher)

function get_all_solvers()::Vector{PhysicsSolver}
    return SOLVER_REGISTRY
end
