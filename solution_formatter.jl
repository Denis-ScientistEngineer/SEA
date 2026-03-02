# solution_formatter.jl - Generate Step-by-Step Solutions
# Shows the work, not just the answer!

"""
Generate a human-readable step-by-step solution
"""
function format_solution(solver::PhysicsSolver, 
                        input_values::Dict{Symbol, Float64},
                        output_values::Dict{Symbol, Float64})::Dict{String, Any}
    
    solution = Dict{String, Any}()
    
    # Delegate to solver-specific formatter
    if typeof(solver) == FirstLawSolver
        return format_first_law_solution(input_values, output_values)
    elseif typeof(solver) == IdealGasSolver
        return format_ideal_gas_solution(input_values, output_values)
    elseif typeof(solver) == HeatCapacitySolver
        return format_heat_capacity_solution(input_values, output_values)
    elseif typeof(solver) == PointChargeFieldSolver
        return format_point_charge_solution(input_values, output_values)
    elseif typeof(solver) == CoulombForceSolver
        return format_coulomb_solution(input_values, output_values)
    else
        # Generic solution format
        return format_generic_solution(solver, input_values, output_values)
    end
end

# =============================================================================
# THERMODYNAMICS SOLUTION FORMATTERS
# =============================================================================

function format_first_law_solution(input::Dict{Symbol, Float64}, 
                                   output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    Q = get_any(output, :Q, :q, :heat)
    W = get_any(output, :W, :w, :work)
    U = get_any(output, :ΔU, :U, :u, :deltaU, :dU)
    
    # Identify what was given and what was found
    given = []
    found = Symbol()
    
    if haskey(input, :Q) || haskey(input, :q) || haskey(input, :heat)
        push!(given, "Q = $(@sprintf("%.2f", Q)) J (heat added to system)")
    else
        found = :Q
    end
    
    if haskey(input, :W) || haskey(input, :w) || haskey(input, :work)
        push!(given, "W = $(@sprintf("%.2f", W)) J (work done by system)")
    else
        found = :W
    end
    
    if haskey(input, :ΔU) || haskey(input, :U) || haskey(input, :u)
        push!(given, "ΔU = $(@sprintf("%.2f", U)) J (internal energy change)")
    else
        found = :ΔU
    end
    
    push!(steps, "📝 Given:")
    for item in given
        push!(steps, "   $item")
    end
    
    push!(steps, "")
    push!(steps, "🔬 Using First Law of Thermodynamics:")
    push!(steps, "   ΔU = Q - W")
    push!(steps, "")
    push!(steps, "📊 Solution:")
    
    if found == :Q
        push!(steps, "   Q = ΔU + W")
        push!(steps, "   Q = $(@sprintf("%.2f", U)) + $(@sprintf("%.2f", W))")
        push!(steps, "   Q = $(@sprintf("%.2f", Q)) J")
    elseif found == :W
        push!(steps, "   W = Q - ΔU")
        push!(steps, "   W = $(@sprintf("%.2f", Q)) - $(@sprintf("%.2f", U))")
        push!(steps, "   W = $(@sprintf("%.2f", W)) J")
    else  # found == :ΔU
        push!(steps, "   ΔU = Q - W")
        push!(steps, "   ΔU = $(@sprintf("%.2f", Q)) - $(@sprintf("%.2f", W))")
        push!(steps, "   ΔU = $(@sprintf("%.2f", U)) J")
    end
    
    push!(steps, "")
    push!(steps, "✅ Answer:")
    if found == :Q
        push!(steps, "   Heat added to system: $(@sprintf("%.2f", Q)) J")
    elseif found == :W
        push!(steps, "   Work done by system: $(@sprintf("%.2f", W)) J")
    else
        if U > 0
            push!(steps, "   Internal energy increased by $(@sprintf("%.2f", U)) J")
        elseif U < 0
            push!(steps, "   Internal energy decreased by $(@sprintf("%.2f", abs(U))) J")
        else
            push!(steps, "   Internal energy remained constant")
        end
    end
    
    return Dict("steps" => steps)
end

function format_ideal_gas_solution(input::Dict{Symbol, Float64},
                                   output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    P = output[:P]
    V = output[:V]
    n = output[:n]
    T = output[:T]
    R = 8.314
    
    # Identify what was found
    found = Symbol()
    for var in [:P, :V, :n, :T]
        if !haskey(input, var)
            found = var
            break
        end
    end
    
    push!(steps, "📝 Given:")
    haskey(input, :P) && push!(steps, "   P = $(@sprintf("%.2f", P)) Pa (pressure)")
    haskey(input, :V) && push!(steps, "   V = $(@sprintf("%.4f", V)) m³ (volume)")
    haskey(input, :n) && push!(steps, "   n = $(@sprintf("%.4f", n)) mol (amount)")
    haskey(input, :T) && push!(steps, "   T = $(@sprintf("%.2f", T)) K (temperature)")
    
    push!(steps, "")
    push!(steps, "🔬 Using Ideal Gas Law:")
    push!(steps, "   PV = nRT")
    push!(steps, "   R = 8.314 J/(mol·K)")
    push!(steps, "")
    push!(steps, "📊 Solution:")
    
    if found == :n
        push!(steps, "   n = PV/(RT)")
        push!(steps, "   n = ($(@sprintf("%.2f", P)))($(@sprintf("%.4f", V))) / (8.314 × $(@sprintf("%.2f", T)))")
        push!(steps, "   n = $(@sprintf("%.4f", n)) mol")
    elseif found == :P
        push!(steps, "   P = nRT/V")
        push!(steps, "   P = ($(@sprintf("%.4f", n)))(8.314)($(@sprintf("%.2f", T))) / $(@sprintf("%.4f", V))")
        push!(steps, "   P = $(@sprintf("%.2f", P)) Pa")
    elseif found == :V
        push!(steps, "   V = nRT/P")
        push!(steps, "   V = ($(@sprintf("%.4f", n)))(8.314)($(@sprintf("%.2f", T))) / $(@sprintf("%.2f", P))")
        push!(steps, "   V = $(@sprintf("%.4f", V)) m³")
    else  # found == :T
        push!(steps, "   T = PV/(nR)")
        push!(steps, "   T = ($(@sprintf("%.2f", P)))($(@sprintf("%.4f", V))) / (($(@sprintf("%.4f", n)))(8.314))")
        push!(steps, "   T = $(@sprintf("%.2f", T)) K")
    end
    
    push!(steps, "")
    push!(steps, "✅ Answer:")
    if found == :n
        push!(steps, "   Amount of gas: $(@sprintf("%.4f", n)) mol")
    elseif found == :P
        push!(steps, "   Gas pressure: $(@sprintf("%.2f", P)) Pa")
    elseif found == :V
        push!(steps, "   Gas volume: $(@sprintf("%.4f", V)) m³")
    else
        push!(steps, "   Gas temperature: $(@sprintf("%.2f", T)) K")
    end
    
    return Dict("steps" => steps)
end

function format_heat_capacity_solution(input::Dict{Symbol, Float64},
                                       output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    Q = get_any(output, :Q, :q, :heat)
    m = get_any(output, :m, :mass)
    c = get_any(output, :c, :specific_heat)
    ΔT = get_any(output, :ΔT, :deltaT, :dT)
    
    push!(steps, "📝 Given:")
    haskey(input, :Q) && push!(steps, "   Q = $(@sprintf("%.2f", Q)) J (heat)")
    haskey(input, :m) && push!(steps, "   m = $(@sprintf("%.2f", m)) kg (mass)")
    haskey(input, :c) && push!(steps, "   c = $(@sprintf("%.2f", c)) J/(kg·K) (specific heat)")
    haskey(input, :ΔT) && push!(steps, "   ΔT = $(@sprintf("%.2f", ΔT)) K (temperature change)")
    
    push!(steps, "")
    push!(steps, "🔬 Using Heat Capacity Equation:")
    push!(steps, "   Q = mcΔT")
    push!(steps, "")
    push!(steps, "📊 Solution:")
    
    # Determine what was calculated
    if !haskey(input, :Q)
        push!(steps, "   Q = mcΔT")
        push!(steps, "   Q = ($(@sprintf("%.2f", m)))($(@sprintf("%.2f", c)))($(@sprintf("%.2f", ΔT)))")
        push!(steps, "   Q = $(@sprintf("%.2f", Q)) J")
    elseif !haskey(input, :m)
        push!(steps, "   m = Q/(cΔT)")
        push!(steps, "   m = $(@sprintf("%.2f", Q)) / (($(@sprintf("%.2f", c)))($(@sprintf("%.2f", ΔT))))")
        push!(steps, "   m = $(@sprintf("%.2f", m)) kg")
    elseif !haskey(input, :c)
        push!(steps, "   c = Q/(mΔT)")
        push!(steps, "   c = $(@sprintf("%.2f", Q)) / (($(@sprintf("%.2f", m)))($(@sprintf("%.2f", ΔT))))")
        push!(steps, "   c = $(@sprintf("%.2f", c)) J/(kg·K)")
    else
        push!(steps, "   ΔT = Q/(mc)")
        push!(steps, "   ΔT = $(@sprintf("%.2f", Q)) / (($(@sprintf("%.2f", m)))($(@sprintf("%.2f", c))))")
        push!(steps, "   ΔT = $(@sprintf("%.2f", ΔT)) K")
    end
    
    return Dict("steps" => steps)
end

# =============================================================================
# ELECTROMAGNETICS SOLUTION FORMATTERS
# =============================================================================

function format_point_charge_solution(input::Dict{Symbol, Float64},
                                      output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    Q = input[:Q]
    field_pt = [input[:x], input[:y], input[:z]]
    charge_pt = [input[:x0], input[:y0], input[:z0]]
    
    Ex = output[:Ex]
    Ey = output[:Ey]
    Ez = output[:Ez]
    E_mag = output[:E_magnitude]
    
    push!(steps, "📝 Given:")
    push!(steps, "   Q = $(@sprintf("%.4e", Q)) C (charge)")
    push!(steps, "   Charge location: ($(@sprintf("%.2f", charge_pt[1])), $(@sprintf("%.2f", charge_pt[2])), $(@sprintf("%.2f", charge_pt[3])))")
    push!(steps, "   Field point: ($(@sprintf("%.2f", field_pt[1])), $(@sprintf("%.2f", field_pt[2])), $(@sprintf("%.2f", field_pt[3])))")
    
    push!(steps, "")
    push!(steps, "🔬 Using Point Charge Formula:")
    push!(steps, "   E⃗ = (kQ/r²)r̂")
    push!(steps, "   k ≈ 8.99 × 10⁹ N·m²/C²")
    
    r_vec = field_pt - charge_pt
    r = sqrt(sum(r_vec.^2))
    
    push!(steps, "")
    push!(steps, "📊 Solution:")
    push!(steps, "   Distance: r = $(@sprintf("%.4f", r)) m")
    push!(steps, "   Electric field magnitude: |E| = $(@sprintf("%.4e", E_mag)) N/C")
    push!(steps, "")
    push!(steps, "   Components:")
    push!(steps, "   Ex = $(@sprintf("%.4e", Ex)) N/C")
    push!(steps, "   Ey = $(@sprintf("%.4e", Ey)) N/C")
    push!(steps, "   Ez = $(@sprintf("%.4e", Ez)) N/C")
    
    return Dict("steps" => steps)
end

function format_coulomb_solution(input::Dict{Symbol, Float64},
                                 output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    Q1 = input[:Q1]
    Q2 = input[:Q2]
    pos1 = [input[:x1], input[:y1], input[:z1]]
    pos2 = [input[:x2], input[:y2], input[:z2]]
    
    F_mag = output[:F_magnitude]
    
    push!(steps, "📝 Given:")
    push!(steps, "   Q₁ = $(@sprintf("%.4e", Q1)) C")
    push!(steps, "   Q₂ = $(@sprintf("%.4e", Q2)) C")
    push!(steps, "   Position 1: ($(@sprintf("%.2f", pos1[1])), $(@sprintf("%.2f", pos1[2])), $(@sprintf("%.2f", pos1[3])))")
    push!(steps, "   Position 2: ($(@sprintf("%.2f", pos2[1])), $(@sprintf("%.2f", pos2[2])), $(@sprintf("%.2f", pos2[3])))")
    
    push!(steps, "")
    push!(steps, "🔬 Using Coulomb's Law:")
    push!(steps, "   F = k|Q₁Q₂|/r²")
    
    r = sqrt(sum((pos2 - pos1).^2))
    
    push!(steps, "")
    push!(steps, "📊 Solution:")
    push!(steps, "   Distance: r = $(@sprintf("%.4f", r)) m")
    push!(steps, "   Force magnitude: |F| = $(@sprintf("%.4e", F_mag)) N")
    
    if Q1 * Q2 > 0
        push!(steps, "   Direction: Repulsive (same sign charges)")
    else
        push!(steps, "   Direction: Attractive (opposite sign charges)")
    end
    
    return Dict("steps" => steps)
end

# =============================================================================
# GENERIC SOLUTION FORMATTER
# =============================================================================

function format_generic_solution(solver::PhysicsSolver,
                                input::Dict{Symbol, Float64},
                                output::Dict{Symbol, Float64})::Dict{String, Any}
    steps = String[]
    
    push!(steps, "📝 Given:")
    for (var, val) in input
        if abs(val) < 1e-3 || abs(val) > 1e4
            push!(steps, "   $(var) = $(@sprintf("%.4e", val))")
        else
            push!(steps, "   $(var) = $(@sprintf("%.4f", val))")
        end
    end
    
    push!(steps, "")
    push!(steps, "🔬 Using: $(get_description(solver))")
    eq = get_equation(solver)
    if !isempty(eq)
        push!(steps, "   $eq")
    end
    
    push!(steps, "")
    push!(steps, "✅ Results:")
    for (var, val) in output
        if !haskey(input, var)  # Only show newly calculated values
            if abs(val) < 1e-3 || abs(val) > 1e4
                push!(steps, "   $(var) = $(@sprintf("%.4e", val))")
            else
                push!(steps, "   $(var) = $(@sprintf("%.4f", val))")
            end
        end
    end
    
    return Dict("steps" => steps)
end
