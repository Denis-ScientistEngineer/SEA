# Use the official Julia image
FROM julia:1.9-alpine

# Set working directory
WORKDIR /app

# Copy all your files into the app
COPY . .

# Install HTTP and JSON packages (your app needs these)
RUN julia -e 'using Pkg; Pkg.add(["HTTP", "JSON"])'

# Tell Railway what port your app uses
EXPOSE 8080

# Command to start your server
CMD ["julia", "gui_server.jl"]