# the string manipulation file

struct Token
    name::Symbol
    value::Float64
end

# Makes tokens to print nicely in the termnal
Base.show(io::IO, t::Token) = print(io, "$(t.name) = $(t.value)")


function tokenize(input::String)::Vector{Token}
    tokens = Token[]    # strat with empty list of tokens

    # Regex pattern
    # is the 'serch pattern' that finds variable=value in any string
    pattern = r"([a-zA-Z∆][a-zA-Z0-9_∆]*)\s*=\s*(-?\d+\.?\d*)"

    #scan for every match in the input string
    for m in eachmatch(pattern, input)
        raw_name = m.captures[1]    #"heat", "Q"
        raw_value = m.captures[2]   # "100" 

        name = Symbol(raw_name)     # convert "Q" -> :Q
        value = parse(Float64, raw_value)   # convert "100" -> 100.0

        push!(tokens, Token(name, value))
    end

    return tokens
end


# STEP 3: CONVERT tokens
# The solvers expect a Dict, not a vector of Tokens

function tokens_to_dict(tokens::Vector{Token})::Dict{Symbol, Float64}
    return Dict(t.name => t.value for t in tokens)
end


# STEP 4: Validation
function validate_tokens(tokens::Vector{Token})::Bool
    if length(tokens) == 0
        println("ERROR: Could not find any variable=value pairs in your input.")
        println("   Please use formart like: Q=100, W=40")
        return false
    end

    if length(tokens) == 1
        println("ERROR: Only found 1 variable. You need at least 2 to solve an equation.")
        println("   Example: Q=100, w=40    (2 values -> finds ∆U)")
        return false
    end

    return true
end



# CONVENIENCE: Full Parse function
# Combines tokenize + validate + convert into one call
# This is what the dispatcher.jl will actually call

function parse_input(input::AbstractString)::Union{Dict{Symbol, Float64}, Nothing}
    # step 1: Extract tokens

    tokens = tokenize(input)

    # step 2: Validate we have enough

    if !validate_tokens(tokens)
        return nothing
    end

    # step 3: Convert to Dictionary

    values = tokens_to_dict(tokens)

    println("✓ Tokenizer extracted: $values")

    return values
end