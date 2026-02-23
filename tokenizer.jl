struct Token
    name::Symbol
    value::Float64
end

function tokenize(input::String)::Vector{Token}
    tokens = Token[]
    pattern = r"([a-zA-ZΔδεσρμτ][a-zA-Z0-9_Δδεσρμτ]*)\s*=\s*(-?\d+\.?\d*)"
    
    for m in eachmatch(pattern, input)
        name = Symbol(m.captures[1])
        value = parse(Float64, m.captures[2])
        push!(tokens, Token(name, value))
    end
    
    return tokens
end

function parse_input(input::AbstractString)
    tokens = tokenize(input)
    
    if length(tokens) < 2
        return nothing
    end
    
    return Dict(t.name => t.value for t in tokens)
end
