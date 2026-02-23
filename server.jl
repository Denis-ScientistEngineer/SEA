using HTTP
using JSON
using Printf

# Load physics files
include("abstract_solver.jl")
include("thermodynamics.jl")
include("registry.jl")
include("tokenizer.jl")
include("dispatcher.jl")

println("🚀 Initializing Physics Solver...")

# Register solvers
register_solver(FirstLawSolver())

println("✓ Solvers registered!")

# API function
function solve_api(input::String)
    try
        values = parse_input(input)
        
        if values === nothing
            return Dict("success" => false, "error" => "Could not parse input")
        end
        
        outcome = dispatch_and_solve(values)
        
        if outcome === nothing
            return Dict("success" => false, "error" => "No solver found")
        end
        
        result_strings = Dict{String, String}()
        for (var, val) in outcome.result
            val_str = @sprintf("%.4f", val)
            result_strings[string(var)] = val_str
        end
        
        return Dict(
            "success" => true,
            "solver" => string(typeof(outcome.solver)),
            "domain" => string(get_domain(outcome.solver)),
            "results" => result_strings
        )
    catch e
        return Dict("success" => false, "error" => "Error: $(e)")
    end
end

# Request handler
function handle_request(req)
    path = HTTP.URIs.URI(req.target).path
    
    cors = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]
    
    if req.method == "OPTIONS"
        return HTTP.Response(200, cors, "")
    end
    
    if path == "/"
        # Simple test page for now
        return HTTP.Response(200, """
            <!DOCTYPE html>
            <html>
            <head><title>Physics Solver</title></head>
            <body>
                <h1>✅ Physics Solver Online!</h1>
                <p>Try: <code>/solve</code> endpoint</p>
                <button onclick="test()">Test Solver</button>
                <div id="result"></div>
                <script>
                async function test() {
                    const res = await fetch('/solve', {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json'},
                        body: JSON.stringify({input: 'Q=100, W=40'})
                    });
                    const data = await res.json();
                    document.getElementById('result').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                }
                </script>
            </body>
            </html>
        """)
        
    elseif path == "/solve"
        body = String(req.body)
        
        # Handle empty body
        if isempty(body)
            return HTTP.Response(400, vcat(cors, ["Content-Type" => "application/json"]),
                "{\"success\": false, \"error\": \"Empty request\"}")
        end
        
        data = JSON.parse(body)
        input = data["input"]
        
        println("📝 Solving: $input")
        result = solve_api(input)
        
        return HTTP.Response(200, 
            vcat(cors, ["Content-Type" => "application/json"]),
            JSON.json(result))
    else
        return HTTP.Response(404, "Not found")
    end
end

# Start server
port = parse(Int, get(ENV, "PORT", "8000"))
host = "0.0.0.0"

println("🌐 Starting server on port $port...")
HTTP.serve(handle_request, host, port)
