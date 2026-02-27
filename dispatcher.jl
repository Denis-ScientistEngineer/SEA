# dispatcher.jl - Smart Dispatcher with Context Awareness
# NOW RESPECTS PHYSICAL BOUNDARIES!

include("abstract_solver.jl")
include("system_context.jl")

# =============================================================================
# CONTEXT-AWARE DISPATCHER
# =============================================================================

"""
    find_solver(values, context) -> Union{PhysicsSolver, Nothing}

Find the best solver for given variables AND physical context.

This is the BRAIN of the system - it:
1. Infers physical context if not provided
2. Filters solvers by regime compatibility
3. Checks variable matching
4. Validates inputs
5. Ranks by priority
6. Returns best match

Arguments:
- values: Dictionary of input variables
- context: Optional SystemContext (auto-inferred if not provided)

Returns:
- Best matching solver, or nothing if no valid solver found
"""
function find_solver(values::Dict{Symbol, Float64}, context::Union{SystemContext, Nothing}=nothing)
    variable_names = Set(keys(values))
    
    # Infer context if not provided
    if isnothing(context)
        context = infer_context(values)
        println("📊 Detected regime: $(describe_regime(context.regime))")
        println("🔬 Substance: $(context.substance)")
    end
    
    candidates = []
    
    # Find all compatible solvers
    for solver in get_all_solvers()
        # Step 1: Check regime/context compatibility
        if !is_context_compatible(solver, context)
            continue
        end
        
        # Step 2: Check if solver can handle these variables
        if !can_solve(solver, variable_names, context)
            continue
        end
        
        # Step 3: Validate inputs
        if !validate_inputs(solver, values)
            continue
        end
        
        # Step 4: Add to candidates with priority
        priority = get_priority(solver)
        push!(candidates, (solver=solver, priority=priority))
    end
    
    # Sort by priority (highest first)
    sort!(candidates, by=x -> x.priority, rev=true)
    
    # Return best match
    if !isempty(candidates)
        return candidates[1].solver
    end
    
    return nothing
end

"""
    dispatch_and_solve(values, context) -> Union{NamedTuple, Nothing}

Dispatch to appropriate solver and execute.

Returns:
- (solver=solver, result=result, context=context) on success
- nothing on failure
"""
function dispatch_and_solve(values::Dict{Symbol, Float64}, context::Union{SystemContext, Nothing}=nothing)
    # Infer context if needed
    if isnothing(context)
        context = infer_context(values)
    end
    
    solver = find_solver(values, context)
    
    if solver === nothing
        return nothing
    end
    
    try
        result = solve(solver, values)
        return (solver=solver, result=result, context=context)
    catch e
        println("⚠️  Solver $(typeof(solver)) failed: $e")
        return nothing
    end
end

# =============================================================================
# DEBUGGING AND ANALYSIS TOOLS
# =============================================================================

"""
    find_all_matching_solvers(values, context) -> Vector

Get all solvers that match (for debugging).

Returns detailed info about each solver's compatibility.
"""
function find_all_matching_solvers(values::Dict{Symbol, Float64}, context::Union{SystemContext, Nothing}=nothing)
    variable_names = Set(keys(values))
    
    if isnothing(context)
        context = infer_context(values)
    end
    
    matches = []
    
    for solver in get_all_solvers()
        context_ok = is_context_compatible(solver, context)
        can_handle = can_solve(solver, variable_names, context)
        is_valid = can_handle ? validate_inputs(solver, values) : false
        priority = get_priority(solver)
        
        push!(matches, Dict(
            "solver" => string(typeof(solver)),
            "domain" => string(get_domain(solver)),
            "description" => get_description(solver),
            "context_compatible" => context_ok,
            "can_handle" => can_handle,
            "is_valid" => is_valid,
            "priority" => priority,
            "required_regime" => string(get_required_regime(solver)),
            "physics_type" => string(get_physics_type(solver))
        ))
    end
    
    return matches
end

"""
    explain_dispatch(values) -> String

Explain why certain solvers were chosen or rejected.
Great for debugging!
"""
function explain_dispatch(values::Dict{Symbol, Float64})::String
    context = infer_context(values)
    matches = find_all_matching_solvers(values, context)
    
    explanation = "🔍 Dispatch Analysis:\n"
    explanation *= "Context: $(describe_regime(context.regime))\n"
    explanation *= "Substance: $(context.substance)\n\n"
    
    for match in matches
        explanation *= "$(match["solver"]):\n"
        explanation *= "  Context OK: $(match["context_compatible"])\n"
        explanation *= "  Can Handle: $(match["can_handle"])\n"
        explanation *= "  Valid: $(match["is_valid"])\n"
        explanation *= "  Priority: $(match["priority"])\n\n"
    end
    
    return explanation
end