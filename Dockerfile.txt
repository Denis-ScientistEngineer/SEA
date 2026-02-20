# Use the official Julia image
FROM julia:1.9-alpine

# Set working directory
WORKDIR /app

# Copy all your files into the app
COPY . .

# Install your Julia dependencies
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

# Tell Railway what port your app uses
EXPOSE 8080

# Command to start your server
CMD ["julia", "--project=.", "gui_server.jl"]