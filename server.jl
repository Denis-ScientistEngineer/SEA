# MINIMAL WEB SERVER - Guaranteed to work!
using HTTP

println("🚀 Starting minimal server...")

function handle_request(req)
    println("📥 Request received: $(req.target)")
    
    if req.target == "/"
        return HTTP.Response(200, """
            <!DOCTYPE html>
            <html>
            <head><title>Physics Solver</title></head>
            <body>
                <h1>✅ IT WORKS!</h1>
                <p>Your physics solver is live!</p>
                <form>
                    <input type="text" id="input" placeholder="Q=100, W=40">
                    <button type="button" onclick="alert('Server is running!')">Test</button>
                </form>
            </body>
            </html>
        """)
    else
        return HTTP.Response(404, "Not found")
    end
end

# Get port from Railway (or use 8000 locally)
port = parse(Int, get(ENV, "PORT", "8000"))

println("📍 Starting on port: $port")
println("🌐 Listening on: 0.0.0.0")

# Start server
HTTP.serve(handle_request, "0.0.0.0", port)