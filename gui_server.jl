# =============================================================================
# gui_server.jl - Web Server for Physics Solver GUI (PRODUCTION READY!)
# =============================================================================
# PURPOSE: Creates a web server that works both locally AND in the cloud!
#
# HOW TO RUN LOCALLY:
#   julia gui_server.jl
#   Then open: http://localhost:8000
#
# HOW TO DEPLOY TO CLOUD:
#   Follow DEPLOYMENT_GUIDE.md
#   Then access from anywhere: https://your-app.railway.app
# =============================================================================

using HTTP
using JSON
using Printf

# Load your existing physics solver (EXACT same files you already have!)
include("abstract_solver.jl")
include("thermodynamics.jl")
include("registry.jl")
include("tokenizer.jl")
include("dispatcher.jl")

# Initialize solvers (same as in main.jl)
println("🚀 Initializing Physics Solver...")

function initialize_solvers()
    register_solver(FirstLawSolver())
    register_solver(IdealGasSolver())
    register_solver(HeatCapacitySolver())
end

initialize_solvers()
println("✓ Solvers registered: $(length(get_all_solvers()))")


# =============================================================================
# API ENDPOINT: This is what the web page calls to solve problems
# =============================================================================

"""
Process a problem and return JSON response for the web interface.
"""
function solve_api(input::String)
    try
        # Use your EXISTING code! Nothing new here!
        values = parse_input(input)
        
        if values === nothing
            return Dict(
                "success" => false,
                "error" => "Could not parse input. Use format: Q=100, W=40"
            )
        end
        
        outcome = dispatch_and_solve(values)
        
        if outcome === nothing
            return Dict(
                "success" => false,
                "error" => "No solver found for these variables"
            )
        end
        
        # Format the result nicely
        result_strings = Dict{String, String}()
        for (var, val) in outcome.result
            if var != :unknown_was
                val_str = @sprintf("%.4f", val)
                result_strings[string(var)] = val_str
            end
        end
        
        return Dict(
            "success" => true,
            "solver" => string(typeof(outcome.solver)),
            "domain" => string(get_domain(outcome.solver)),
            "results" => result_strings
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Error: $(e)"
        )
    end
end


# =============================================================================
# WEB SERVER: Serves the HTML page and handles API requests
# =============================================================================

"""
Handle HTTP requests from the browser
"""
function handle_request(req::HTTP.Request)
    # Get the path the browser requested
    path = HTTP.URIs.URI(req.target).path
    
    # CORS headers for production (allows access from anywhere)
    cors_headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]
    
    # Handle preflight requests
    if req.method == "OPTIONS"
        return HTTP.Response(200, cors_headers, "")
    end
    
    if path == "/"
        # Serve the HTML page
        html_file = "index.html"
        if isfile(html_file)
            html_content = read(html_file, String)
            return HTTP.Response(200, 
                ["Content-Type" => "text/html; charset=utf-8"], 
                html_content)
        else
            return HTTP.Response(404, "index.html not found! Make sure it's in the same folder as gui_server.jl")
        end
        
    elseif path == "/solve"
        # API endpoint - solve a problem
        body = String(req.body)
        data = JSON.parse(body)
        input = data["input"]
        
        println("📝 Solving: $input")
        result = solve_api(input)
        
        # Return JSON response with CORS headers
        response_json = JSON.json(result)
        return HTTP.Response(200, 
            vcat(cors_headers, ["Content-Type" => "application/json"]),
            response_json)
    
    elseif path == "/solvers"
        # API endpoint - list available solvers
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
    
    elseif path == "/health"
        # Health check endpoint (for Railway)
        return HTTP.Response(200, 
            ["Content-Type" => "application/json"],
            JSON.json(Dict("status" => "healthy", "solvers" => length(get_all_solvers()))))
        
    else
        return HTTP.Response(404, "Not found")
    end
end


# =============================================================================
# START THE SERVER!
# =============================================================================

function start_server()
    # Get port from environment variable (Railway sets this) or use 8000 locally
    port = parse(Int, get(ENV, "PORT", "8000"))
    
    # Determine if we're running locally or in production
    is_production = haskey(ENV, "RAILWAY_ENVIRONMENT") || haskey(ENV, "PORT")
    
    # In production, listen on 0.0.0.0 (accessible from internet)
    # Locally, listen on 127.0.0.1 (only accessible from your computer)
    host = is_production ? "0.0.0.0" : "127.0.0.1"
    
    println("\n" * "="^60)
    println("🌐 Physics Solver Web Server Starting...")
    println("="^60)
    
    if is_production
        println("\n🚀 Production Mode")
        println("📍 Server running on port: $port")
        println("🌍 Accessible from anywhere!")
    else
        println("\n🏠 Local Mode")
        println("📍 Server running at: http://localhost:$port")
        println("\n🔍 Open your web browser and go to:")
        println("   http://localhost:$port")
    end
    
    println("\n⏹️  Press Ctrl+C to stop the server")
    println("="^60 * "\n")
    
    # Start the HTTP server
    HTTP.serve(handle_request, host, port)
end

# Run the server when this file is executed
if abspath(PROGRAM_FILE) == @__FILE__
    start_server()
end