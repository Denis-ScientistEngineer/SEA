# =============================================================================
# gui_server.jl - Web Server for Physics Solver GUI
# =============================================================================
# PURPOSE: Creates a simple web server so you can use your solver in a browser!
#
# HOW TO RUN:
#   1. Install HTTP package (only need to do this ONCE):
#      julia> using Pkg; Pkg.add("HTTP"); Pkg.add("JSON")
#
#   2. Run this file:
#      julia gui_server.jl
#
#   3. Open your browser to:
#      http://localhost:8000
#
# WHAT THIS DOES:
#   - Creates a web server on your computer
#   - Uses your EXISTING solver code (no changes needed!)
#   - Provides an API endpoint for the GUI to call
# =============================================================================

using HTTP
using JSON
using Printf

# Load your existing physics solver (EXACT same files you already have!)
include("abstract_solver.jl")
include("thermo.jl")
include("registry.jl")
include("tokenizer.jl")
include("dispatcher.jl")

# Initialize solvers (same as in main.jl)
println("🚀 Initializing Physics Solver...")
const SOLVER_REGISTRY = Vector{PhysicsSolver}()

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
    
    if path == "/"
        # Serve the HTML page
        html_file = "index.html"
        if isfile(html_file)
            return HTTP.Response(200, read(html_file, String))
        else
            return HTTP.Response(404, "index.html not found! Make sure it's in the same folder as gui_server.jl")
        end
        
    elseif path == "/solve"
        # API endpoint - solve a problem
        # The browser sends: POST /solve with body: {"input": "Q=100, W=40"}
        
        body = String(req.body)
        data = JSON.parse(body)
        input = data["input"]
        
        println("📝 Solving: $input")
        result = solve_api(input)
        
        # Return JSON response
        response_json = JSON.json(result)
        return HTTP.Response(200, 
            ["Content-Type" => "application/json",
             "Access-Control-Allow-Origin" => "*"],
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
            ["Content-Type" => "application/json"],
            response_json)
        
    else
        return HTTP.Response(404, "Not found")
    end
end


# =============================================================================
# START THE SERVER!
# =============================================================================

function start_server(port=8000)
    println("\n" * "="^60)
    println("🌐 Physics Solver Web Server Starting...")
    println("="^60)
    println("\n📍 Server running at: http://localhost:$port")
    println("\n🔍 Open your web browser and go to:")
    println("   http://localhost:$port")
    println("\n⏹️  Press Ctrl+C to stop the server")
    println("\n" * "="^60 * "\n")
    
    # Start the HTTP server
    HTTP.serve(handle_request, "127.0.0.1", port)
end

# Run the server when this file is executed
if abspath(PROGRAM_FILE) == @__FILE__
    start_server(8000)
end