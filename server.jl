
# =============================================================================
# server.jl - Production Web Server
# =============================================================================

using HTTP
using JSON
using Printf

# Load physics files
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
# API ENDPOINT
# =============================================================================

# Update the solve_api function in server.jl to show context info!

function solve_api(input::String)
    try
        values = parse_input(input)
        
        if values === nothing
            return Dict(
                "success" => false,
                "error" => "Could not parse input. Use format: Q=100, W=40"
            )
        end
        
        # Infer context
        context = infer_context(values)
        
        outcome = dispatch_and_solve(values, context)
        
        if outcome === nothing
            return Dict(
                "success" => false,
                "error" => "No solver found for these variables in $(context.regime) regime",
                "regime" => string(context.regime),
                "substance" => string(context.substance)
            )
        end
        
        # SMART FORMAT with units and context!
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
        
        return Dict(
            "success" => true,
            "solver" => string(typeof(outcome.solver)),
            "domain" => string(get_domain(outcome.solver)),
            "equation" => get_equation(outcome.solver),
            "results" => result_strings,
            # NEW: Context information!
            "context" => Dict(
                "regime" => string(context.regime),
                "substance" => string(context.substance),
                "description" => describe_regime(context.regime)
            )
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Error: $(e)"
        )
    end
end

# =============================================================================
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
