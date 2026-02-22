# Test web server

using HTTP

println("🚀 Starting minimal server...")

function handle_request(req)
    println("Request recieved: $(req.target)")

    if req.target == "/"
        return HTTP.Response(200, """
            <!DOCTYPE html>
            <html>
            <head><title>Physics Solver</title></head>
            <body>
                <h1>    IT WORKS!</h1>
                <p>Your Physics Solver is LIVE!</p>
                <form>
                    <input type="text" id="input" placeholder="Q=100, W=40">
                    <button type="button" onclick="alert('server is running!')">Test</button>
                </form>
            </body>
            </html>
        """)
    else
        return HTTP.Response(404, "Not found")
    end
end

# Get port from Railway (for use 8000 locally)
port = parse(Int, get(ENV, "PORT", "8000"))

println("Starting on port: $port")
println("Listening on: 0.0.0.0")

#start server
HTTP.serve(handle_request, "0.0.0.0", port)