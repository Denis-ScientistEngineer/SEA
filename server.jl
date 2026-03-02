
# =============================================================================
# server.jl - Production Web Server
# =============================================================================

using HTTP
using JSON
using Printf

# Load physics files
include("solution_formatter.jl")
include("system_context.jl")
include("abstract_solver.jl")
include("thermodynamics.jl")
include("electromagnetics.jl")
include("registry.jl")
include("tokenizer.jl")
include("dispatcher.jl")


println("🚀 Initializing Physics Solver...")

# Register solvers
register_solver(FirstLawSolver())
register_solver(IdealGasSolver()) 
register_solver(HeatCapacitySolver()) 
# Register electromagnetics solvers
register_solver(PointChargeFieldSolver())
register_solver(CoulombForceSolver())
register_solver(InfiniteLineChargeSolver())
println("✓ Solvers registered: $(length(get_all_solvers()))")


# =============================================================================
# ERROR HANDLING WITH HELPFUL SUGGESTIONS
# =============================================================================

"""
Generate helpful suggestions when no solver found
"""
function generate_suggestions(values::Dict{Symbol, Float64})::Vector{String}
    suggestions = String[]
    variables = Set(keys(values))
    
    # Check what domains might be close
    
    # Thermodynamics suggestions
    thermo_vars = Set([:Q, :q, :heat, :W, :w, :work, :U, :u, :ΔU])
    if length(intersect(variables, thermo_vars)) >= 1
        push!(suggestions, "💡 For First Law of Thermodynamics, you need 2 of: Q (heat), W (work), ΔU (internal energy change)")
    end
    
    gas_vars = Set([:P, :p, :V, :v, :T, :t, :n])
    if length(intersect(variables, gas_vars)) >= 1
        push!(suggestions, "💡 For Ideal Gas Law, you need 3 of: P (pressure), V (volume), n (moles), T (temperature)")
    end
    
    heat_vars = Set([:Q, :q, :m, :c, :ΔT, :deltaT])
    if length(intersect(variables, heat_vars)) >= 1
        push!(suggestions, "💡 For Heat Capacity, you need 3 of: Q (heat), m (mass), c (specific heat), ΔT (temperature change)")
    end
    
    # Electromagnetics suggestions
    charge_vars = Set([:Q, :E, :V, :x, :y, :z])
    if length(intersect(variables, charge_vars)) >= 1
        push!(suggestions, "⚡ For Point Charge Field, you need: Q (charge), x, y, z (field point), x0, y0, z0 (charge location)")
    end
    
    coulomb_vars = Set([:Q1, :Q2, :F])
    if length(intersect(variables, coulomb_vars)) >= 1
        push!(suggestions, "⚡ For Coulomb Force, you need: Q1, Q2 (charges), positions (x1,y1,z1) and (x2,y2,z2)")
    end
    
    # If no specific suggestions, give general help
    if isempty(suggestions)
        push!(suggestions, "ℹ️ Available domains: Thermodynamics (Q, W, ΔU, P, V, T, n), Electromagnetics (Q, E, F, charges)")
        push!(suggestions, "ℹ️ Try using scientific notation for small values: 1e-6 instead of 0.000001")
    end
    
    return suggestions
end

"""
List all available solvers with their requirements
"""
function list_available_solvers()::Vector{Dict{String, Any}}
    solver_info = []
    
    for solver in get_all_solvers()
        info = Dict{String, Any}(
            "name" => string(typeof(solver)),
            "domain" => string(get_domain(solver)),
            "description" => get_description(solver),
            "equation" => get_equation(solver)
        )
        push!(solver_info, info)
    end
    
    return solver_info
end

"""
Explain why specific solvers were rejected (for debugging)
"""
function explain_rejection(values::Dict{Symbol, Float64})::Dict{String, Any}
    context = infer_context(values)
    variable_names = Set(keys(values))
    
    rejections = []
    
    for solver in get_all_solvers()
        reason = ""
        
        # Check context compatibility
        if !is_context_compatible(solver, context)
            required_regime = get_required_regime(solver)
            reason = "Requires $(required_regime) regime, but detected $(context.regime)"
        # Check variable matching
        elseif !can_solve(solver, variable_names, context)
            reason = "Missing required variables"
        # Check input validation
        elseif !validate_inputs(solver, values)
            reason = "Invalid input values (check ranges: positive values, sufficient data)"
        else
            continue  # This solver would work!
        end
        
        push!(rejections, Dict(
            "solver" => string(typeof(solver)),
            "reason" => reason
        ))
    end
    
    return Dict(
        "context" => Dict(
            "regime" => string(context.regime),
            "substance" => string(context.substance),
            "description" => describe_regime(context.regime)
        ),
        "rejections" => rejections
    )
end
# =============================================================================
# API ENDPOINT
# =============================================================================

# Update the solve_api function in server.jl to show context info!


function solve_api(input::String)
    try
        values = parse_input(input)
        
        if values === nothing
            return Dict(
                "success" => false,
                "error" => "Could not parse input. Use format: Q=100, W=40",
                "hint" => "Use scientific notation for small values: 1e-6, 2.5e-9, etc.",
                "examples" => [
                    "Q=100, W=40",
                    "P=101325, V=0.5, T=300",
                    "Q=1e-6, x=1, y=0, z=0, x0=0, y0=0, z0=0"
                ]
            )
        end
        
        # Infer context
        context = infer_context(values)
        
        outcome = dispatch_and_solve(values, context)
        
        if outcome === nothing
            # Generate helpful error response
            suggestions = generate_suggestions(values)
            explanation = explain_rejection(values)
            
            return Dict(
                "success" => false,
                "error" => "No solver found for these variables",
                "input_received" => Dict(string(k) => v for (k, v) in values),
                "context" => explanation["context"],
                "suggestions" => suggestions,
                "hint" => "Make sure you have enough variables (typically need 2-3 known values)",
                "debug" => explanation["rejections"]
            )
        end
        
        # SUCCESS! Now generate step-by-step solution...

        #Generate step by step solution
        solution_steps = format_solution(outcome.solver, values, outcome.result)
        return Dict(
            "success" => true,
            "solver" => string(typeof(outcome.solver)),
            "domain" => string(get_domain(outcome.solver)),
            "equation" => get_equation(outcome.solver),
            "description" => get_description(outcome.solver),
            "results" => result_strings,
            "solution" => solution_steps,
            "context" => Dict(
                "regime" => string(context.regime),
                "substance" => string(context.substance),
                "description" => describe_regime(context.regime)
                )
            )
        
        # SMART FORMAT with units
        result_strings = Dict{String, String}()
        units = get_output_units(outcome.solver)
        
        for (var, val) in outcome.result
            # Format value
            if abs(val) < 1e-3 || abs(val) > 1e4
                val_str = @sprintf("%.4e", val)
            elseif abs(val) < 1.0
                val_str = @sprintf("%.6f", val)
            else
                val_str = @sprintf("%.4f", val)
            end
            
            # Add unit if available
            if haskey(units, var)
                val_str *= " " * units[var]
            end
            
            result_strings[string(var)] = val_str
        end
        
        
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Error: $(e)",
            "hint" => "Check your input format and values"
        )
    end
end

# =============================================================================# 
# REQUEST HANDLER
# =============================================================================

function handle_request(req::HTTP.Request)
    path = HTTP.URIs.URI(req.target).path
    
    # CORS headers for frontend
    cors_headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]
    
    # Handle preflight requests
    if req.method == "OPTIONS"
        return HTTP.Response(200, cors_headers, "")
    end
    
    # Serve the HTML page
    if path == "/"
        html_file = "index.html"
        if isfile(html_file)
            html_content = read(html_file, String)
            return HTTP.Response(200, 
                ["Content-Type" => "text/html; charset=utf-8"], 
                html_content)
        else
            return HTTP.Response(404, "index.html not found!")
        end
        
    # API endpoint - solve a problem
    elseif path == "/solve"
        body = String(req.body)
        data = JSON.parse(body)
        input = data["input"]
        
        println("📝 Solving: $input")
        result = solve_api(input)
        
        response_json = JSON.json(result)
        return HTTP.Response(200, 
            vcat(cors_headers, ["Content-Type" => "application/json"]),
            response_json)
    
    # List available solvers
    elseif path == "/solvers"
        solvers = []
        for solver in get_all_solvers()
            push!(solvers, Dict(
                "name" => string(typeof(solver)),
                "domain" => string(get_domain(solver))
            ))
        end
        
        response_json = JSON.json(Dict("solvers" => solvers))
        return HTTP.Response(200,
            vcat(cors_headers, ["Content-Type" => "application/json"]),
            response_json)
    
    # Health check endpoint (for Railway)
    elseif path == "/health"
        return HTTP.Response(200, 
            ["Content-Type" => "application/json"],
            JSON.json(Dict("status" => "healthy", "solvers" => length(get_all_solvers()))))
        
    else
        return HTTP.Response(404, "Not found")
    end
end

# =============================================================================
# START SERVER
# =============================================================================

function start_server()
    # CRITICAL: Get port from Railway environment variable
    port = parse(Int, get(ENV, "PORT", "8000"))
    
    # CRITICAL: Listen on 0.0.0.0 for Railway (not 127.0.0.1!)
    host = "0.0.0.0"
    
    println("\n" * "="^60)
    println("🌐 Physics Solver Web Server Starting...")
    println("="^60)
    println("\n📍 Server running on port: $port")
    println("🌍 Listening on: $host")
    println("Access at: http://localhost:$port/")
    println("\n⏹️  Press Ctrl+C to stop")
    println("="^60 * "\n")
    
    # Start the HTTP server
    HTTP.serve(handle_request, host, port)
end

# Run the server
if abspath(PROGRAM_FILE) == @__FILE__
    start_server()
end
