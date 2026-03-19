# helper_functions.jl
# Utility functions used across solver files

"""
    get_any(dict, keys...) -> Union{Float64, Nothing}
    
Try to get a value from dict using multiple possible keys.
Returns the first found value, or nothing if none exist.

Example:
    Q = get_any(values, :Q, :q, :heat)
    # Tries :Q first, then :q, then :heat
"""
function get_any(dict::Dict{Symbol, Float64}, keys::Symbol...)
    for key in keys
        if haskey(dict, key)
            return dict[key]
        end
    end
    return nothing
end

"""
    has_any(dict, keys...) -> Bool
    
Check if dict has any of the given keys.
"""
function has_any(dict::Dict{Symbol, Float64}, keys::Symbol...)
    for key in keys
        if haskey(dict, key)
            return true
        end
    end
    return false
end

"""
    count_present(dict, key_groups...) -> Int
    
Count how many key groups have at least one present key.
Useful for checking if we have enough variables.

Example:
    count_present(values, [:Q, :q], [:W, :w], [:U, :ΔU])
    # Returns 2 if we have Q and W, for instance
"""
function count_present(dict::Dict{Symbol, Float64}, key_groups::Vector{Symbol}...)
    count = 0
    for group in key_groups
        if any(k -> haskey(dict, k), group)
            count += 1
        end
    end
    return count
end