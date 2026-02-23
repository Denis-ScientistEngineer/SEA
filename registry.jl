const SOLVER_REGISTRY = Vector{PhysicsSolver}()

function register_solver(solver::PhysicsSolver)
    push!(SOLVER_REGISTRY, solver)
    println("  ✓ Registered: $(typeof(solver))")
end

function get_all_solvers()::Vector{PhysicsSolver}
    return SOLVER_REGISTRY
end
