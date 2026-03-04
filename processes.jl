# processes.jl - Thermodynamic Process Solvers
# Models HOW systems change, not just their states!

include("abstract_solver.jl")

# =============================================================================
# ISOTHERMAL PROCESS: T = constant, PV = constant
# Used in: Slow compression/expansion with heat exchange
# =============================================================================

struct IsothermalProcessSolver <: PhysicsSolver end

function can_solve(::IsothermalProcessSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    # Need: Two of (P1, V1, P2, V2) and T is constant
    # OR explicitly marked as isothermal process
    has_process_marker = :isothermal in variables || :process in variables
    has_states = (:P1 in variables || :P2 in variables) && 
                 (:V1 in variables || :V2 in variables)
    
    return has_process_marker && has_states
end

function validate_inputs(::IsothermalProcessSolver, values::Dict{Symbol, Float64})::Bool
    # Need at least 3 of: P1, V1, P2, V2
    state_vars = [:P1, :V1, :P2, :V2]
    known = count(v -> haskey(values, v), state_vars)
    
    # All positive
    for var in state_vars
        if haskey(values, var) && values[var] <= 0
            return false
        end
    end
    
    return known >= 3
end

get_required_regime(::IsothermalProcessSolver) = CLASSICAL_MACRO
get_required_substance(::IsothermalProcessSolver) = []
get_physics_type(::IsothermalProcessSolver) = :ideal_gas_law
get_priority(::IsothermalProcessSolver) = 75

get_description(::IsothermalProcessSolver) = "Isothermal Process (T = constant, PV = constant)"
get_equation(::IsothermalProcessSolver) = "P₁V₁ = P₂V₂, W = nRT ln(V₂/V₁)"
get_domain(::IsothermalProcessSolver) = :thermodynamics

function get_output_units(::IsothermalProcessSolver)::Dict{Symbol, String}
    return Dict(
        :P1 => "Pa", :P2 => "Pa",
        :V1 => "m³", :V2 => "m³",
        :W => "J", :Q => "J"
    )
end

function solve(::IsothermalProcessSolver, values::Dict{Symbol, Float64})
    # Get known values
    P1 = get(values, :P1, nothing)
    V1 = get(values, :V1, nothing)
    P2 = get(values, :P2, nothing)
    V2 = get(values, :V2, nothing)
    T = get(values, :T, nothing)
    n = get(values, :n, nothing)
    
    # Apply PV = constant (isothermal)
    if isnothing(P2) && !isnothing(P1) && !isnothing(V1) && !isnothing(V2)
        P2 = P1 * V1 / V2
        values[:P2] = P2
    elseif isnothing(P1) && !isnothing(P2) && !isnothing(V1) && !isnothing(V2)
        P1 = P2 * V2 / V1
        values[:P1] = P1
    elseif isnothing(V2) && !isnothing(P1) && !isnothing(V1) && !isnothing(P2)
        V2 = P1 * V1 / P2
        values[:V2] = V2
    elseif isnothing(V1) && !isnothing(P1) && !isnothing(V2) && !isnothing(P2)
        V1 = P2 * V2 / P1
        values[:V1] = V1
    end
    
    # Calculate work: W = nRT ln(V2/V1) = P1V1 ln(V2/V1)
    if !isnothing(V1) && !isnothing(V2) && !isnothing(P1)
        if !isnothing(n) && !isnothing(T)
            W = n * 8.314 * T * log(V2 / V1)
        else
            W = P1 * V1 * log(V2 / V1)
        end
        values[:W] = W
        values[:Q] = W  # For isothermal: Q = W (ΔU = 0)
    end
    
    return values
end

# =============================================================================
# ADIABATIC PROCESS: Q = 0, PVᵞ = constant
# Used in: Fast compression/expansion (no time for heat transfer)
# =============================================================================

struct AdiabaticProcessSolver <: PhysicsSolver end

function can_solve(::AdiabaticProcessSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    has_process_marker = :adiabatic in variables || (:process in variables && :gamma in variables)
    has_states = (:P1 in variables || :P2 in variables) && 
                 (:V1 in variables || :V2 in variables)
    has_gamma = :gamma in variables || :γ in variables
    
    return has_process_marker && has_states && has_gamma
end

function validate_inputs(::AdiabaticProcessSolver, values::Dict{Symbol, Float64})::Bool
    # Need gamma and at least 3 state variables
    has_gamma = haskey(values, :gamma) || haskey(values, :γ)
    if !has_gamma
        return false
    end
    
    state_vars = [:P1, :V1, :P2, :V2, :T1, :T2]
    known = count(v -> haskey(values, v), state_vars)
    
    return known >= 3
end

get_required_regime(::AdiabaticProcessSolver) = CLASSICAL_MACRO
get_required_substance(::AdiabaticProcessSolver) = []
get_physics_type(::AdiabaticProcessSolver) = :ideal_gas_law
get_priority(::AdiabaticProcessSolver) = 80

get_description(::AdiabaticProcessSolver) = "Adiabatic Process (Q = 0, PVᵞ = constant)"
get_equation(::AdiabaticProcessSolver) = "P₁V₁ᵞ = P₂V₂ᵞ, W = (P₁V₁ - P₂V₂)/(γ-1)"
get_domain(::AdiabaticProcessSolver) = :thermodynamics

function get_output_units(::AdiabaticProcessSolver)::Dict{Symbol, String}
    return Dict(
        :P1 => "Pa", :P2 => "Pa",
        :V1 => "m³", :V2 => "m³",
        :T1 => "K", :T2 => "K",
        :W => "J"
    )
end

function solve(::AdiabaticProcessSolver, values::Dict{Symbol, Float64})
    γ = get(values, :gamma, get(values, :γ, 1.4))  # Default: air
    
    P1 = get(values, :P1, nothing)
    V1 = get(values, :V1, nothing)
    P2 = get(values, :P2, nothing)
    V2 = get(values, :V2, nothing)
    T1 = get(values, :T1, nothing)
    T2 = get(values, :T2, nothing)
    
    # Apply PVᵞ = constant
    if isnothing(P2) && !isnothing(P1) && !isnothing(V1) && !isnothing(V2)
        P2 = P1 * (V1 / V2)^γ
        values[:P2] = P2
    elseif isnothing(P1) && !isnothing(P2) && !isnothing(V1) && !isnothing(V2)
        P1 = P2 * (V2 / V1)^γ
        values[:P1] = P1
    elseif isnothing(V2) && !isnothing(P1) && !isnothing(V1) && !isnothing(P2)
        V2 = V1 * (P1 / P2)^(1/γ)
        values[:V2] = V2
    elseif isnothing(V1) && !isnothing(P1) && !isnothing(V2) && !isnothing(P2)
        V1 = V2 * (P2 / P1)^(1/γ)
        values[:V1] = V1
    end
    
    # Apply TVᵞ⁻¹ = constant if temperatures involved
    if !isnothing(T1) && !isnothing(V1) && !isnothing(V2) && isnothing(T2)
        T2 = T1 * (V1 / V2)^(γ - 1)
        values[:T2] = T2
    elseif !isnothing(T2) && !isnothing(V1) && !isnothing(V2) && isnothing(T1)
        T1 = T2 * (V2 / V1)^(γ - 1)
        values[:T1] = T1
    end
    
    # Calculate work: W = (P1V1 - P2V2)/(γ-1)
    if !isnothing(P1) && !isnothing(V1) && !isnothing(P2) && !isnothing(V2)
        W = (P1 * V1 - P2 * V2) / (γ - 1)
        values[:W] = W
        values[:Q] = 0.0  # Adiabatic: Q = 0
        values[:ΔU] = -W   # ΔU = Q - W = 0 - W = -W
    end
    
    return values
end

# =============================================================================
# ISOBARIC PROCESS: P = constant, V/T = constant
# Used in: Heating at constant pressure (piston free to move)
# =============================================================================

struct IsobaricProcessSolver <: PhysicsSolver end

function can_solve(::IsobaricProcessSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    has_process_marker = :isobaric in variables
    has_states = (:V1 in variables || :V2 in variables) && 
                 (:T1 in variables || :T2 in variables)
    has_pressure = :P in variables
    
    return has_process_marker && has_states && has_pressure
end

function validate_inputs(::IsobaricProcessSolver, values::Dict{Symbol, Float64})::Bool
    has_P = haskey(values, :P)
    state_vars = [:V1, :T1, :V2, :T2]
    known = count(v -> haskey(values, v), state_vars)
    
    return has_P && known >= 3
end

get_required_regime(::IsobaricProcessSolver) = CLASSICAL_MACRO
get_required_substance(::IsobaricProcessSolver) = []
get_physics_type(::IsobaricProcessSolver) = :ideal_gas_law
get_priority(::IsobaricProcessSolver) = 75

get_description(::IsobaricProcessSolver) = "Isobaric Process (P = constant, V/T = constant)"
get_equation(::IsobaricProcessSolver) = "V₁/T₁ = V₂/T₂, W = P(V₂ - V₁)"
get_domain(::IsobaricProcessSolver) = :thermodynamics

function get_output_units(::IsobaricProcessSolver)::Dict{Symbol, String}
    return Dict(
        :V1 => "m³", :V2 => "m³",
        :T1 => "K", :T2 => "K",
        :W => "J", :Q => "J"
    )
end

function solve(::IsobaricProcessSolver, values::Dict{Symbol, Float64})
    P = values[:P]
    
    V1 = get(values, :V1, nothing)
    T1 = get(values, :T1, nothing)
    V2 = get(values, :V2, nothing)
    T2 = get(values, :T2, nothing)
    n = get(values, :n, nothing)
    
    # Apply V/T = constant
    if isnothing(V2) && !isnothing(V1) && !isnothing(T1) && !isnothing(T2)
        V2 = V1 * T2 / T1
        values[:V2] = V2
    elseif isnothing(V1) && !isnothing(V2) && !isnothing(T1) && !isnothing(T2)
        V1 = V2 * T1 / T2
        values[:V1] = V1
    elseif isnothing(T2) && !isnothing(V1) && !isnothing(T1) && !isnothing(V2)
        T2 = T1 * V2 / V1
        values[:T2] = T2
    elseif isnothing(T1) && !isnothing(V1) && !isnothing(T2) && !isnothing(V2)
        T1 = T2 * V1 / V2
        values[:T1] = T1
    end
    
    # Calculate work: W = P(V2 - V1)
    if !isnothing(V1) && !isnothing(V2)
        W = P * (V2 - V1)
        values[:W] = W
        
        # Q = nCp(T2 - T1), but if we don't have n or Cp, just report W
        if !isnothing(n) && !isnothing(T1) && !isnothing(T2)
            # For ideal gas: Cp = (γ/(γ-1))R, assuming γ=1.4 for air
            Cp = (1.4 / 0.4) * 8.314
            Q = n * Cp * (T2 - T1)
            values[:Q] = Q
            values[:ΔU] = Q - W
        end
    end
    
    return values
end

# =============================================================================
# ISOCHORIC PROCESS: V = constant, P/T = constant
# Used in: Heating in rigid container
# =============================================================================

struct IsochoricProcessSolver <: PhysicsSolver end

function can_solve(::IsochoricProcessSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    has_process_marker = :isochoric in variables
    has_states = (:P1 in variables || :P2 in variables) && 
                 (:T1 in variables || :T2 in variables)
    has_volume = :V in variables
    
    return has_process_marker && has_states && has_volume
end

function validate_inputs(::IsochoricProcessSolver, values::Dict{Symbol, Float64})::Bool
    has_V = haskey(values, :V)
    state_vars = [:P1, :T1, :P2, :T2]
    known = count(v -> haskey(values, v), state_vars)
    
    return has_V && known >= 3
end

get_required_regime(::IsochoricProcessSolver) = CLASSICAL_MACRO
get_required_substance(::IsochoricProcessSolver) = []
get_physics_type(::IsochoricProcessSolver) = :ideal_gas_law
get_priority(::IsochoricProcessSolver) = 75

get_description(::IsochoricProcessSolver) = "Isochoric Process (V = constant, P/T = constant)"
get_equation(::IsochoricProcessSolver) = "P₁/T₁ = P₂/T₂, W = 0"
get_domain(::IsochoricProcessSolver) = :thermodynamics

function get_output_units(::IsochoricProcessSolver)::Dict{Symbol, String}
    return Dict(
        :P1 => "Pa", :P2 => "Pa",
        :T1 => "K", :T2 => "K",
        :Q => "J", :ΔU => "J"
    )
end

function solve(::IsochoricProcessSolver, values::Dict{Symbol, Float64})
    V = values[:V]
    
    P1 = get(values, :P1, nothing)
    T1 = get(values, :T1, nothing)
    P2 = get(values, :P2, nothing)
    T2 = get(values, :T2, nothing)
    n = get(values, :n, nothing)
    
    # Apply P/T = constant
    if isnothing(P2) && !isnothing(P1) && !isnothing(T1) && !isnothing(T2)
        P2 = P1 * T2 / T1
        values[:P2] = P2
    elseif isnothing(P1) && !isnothing(P2) && !isnothing(T1) && !isnothing(T2)
        P1 = P2 * T1 / T2
        values[:P1] = P1
    elseif isnothing(T2) && !isnothing(P1) && !isnothing(T1) && !isnothing(P2)
        T2 = T1 * P2 / P1
        values[:T2] = T2
    elseif isnothing(T1) && !isnothing(P1) && !isnothing(T2) && !isnothing(P2)
        T1 = T2 * P1 / P2
        values[:T1] = T1
    end
    
    # Work is zero (no volume change)
    values[:W] = 0.0
    
    # Q = nCv(T2 - T1)
    if !isnothing(n) && !isnothing(T1) && !isnothing(T2)
        # For ideal gas: Cv = R/(γ-1), assuming γ=1.4
        Cv = 8.314 / 0.4
        Q = n * Cv * (T2 - T1)
        values[:Q] = Q
        values[:ΔU] = Q  # ΔU = Q - W = Q - 0 = Q
    end
    
    return values
end

# =============================================================================
# POLYTROPIC PROCESS: PVⁿ = constant (generalization)
# Special cases: n=0 (isobaric), n=1 (isothermal), n=γ (adiabatic), n=∞ (isochoric)
# =============================================================================

struct PolytropicProcessSolver <: PhysicsSolver end

function can_solve(::PolytropicProcessSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    has_n = :n_polytropic in variables || :polytropic in variables
    has_states = (:P1 in variables || :P2 in variables) && 
                 (:V1 in variables || :V2 in variables)
    
    return has_n && has_states
end

function validate_inputs(::PolytropicProcessSolver, values::Dict{Symbol, Float64})::Bool
    has_n = haskey(values, :n_polytropic)
    state_vars = [:P1, :V1, :P2, :V2]
    known = count(v -> haskey(values, v), state_vars)
    
    return has_n && known >= 3
end

get_required_regime(::PolytropicProcessSolver) = CLASSICAL_MACRO
get_required_substance(::PolytropicProcessSolver) = []
get_priority(::PolytropicProcessSolver) = 70

get_description(::PolytropicProcessSolver) = "Polytropic Process (PVⁿ = constant)"
get_equation(::PolytropicProcessSolver) = "P₁V₁ⁿ = P₂V₂ⁿ"
get_domain(::PolytropicProcessSolver) = :thermodynamics

function solve(::PolytropicProcessSolver, values::Dict{Symbol, Float64})
    n = values[:n_polytropic]
    
    P1 = get(values, :P1, nothing)
    V1 = get(values, :V1, nothing)
    P2 = get(values, :P2, nothing)
    V2 = get(values, :V2, nothing)
    
    # Apply PVⁿ = constant
    if isnothing(P2) && !isnothing(P1) && !isnothing(V1) && !isnothing(V2)
        P2 = P1 * (V1 / V2)^n
        values[:P2] = P2
    elseif isnothing(V2) && !isnothing(P1) && !isnothing(V1) && !isnothing(P2)
        V2 = V1 * (P1 / P2)^(1/n)
        values[:V2] = V2
    end
    
    # Calculate work
    if !isnothing(P1) && !isnothing(V1) && !isnothing(P2) && !isnothing(V2)
        if abs(n - 1.0) < 0.001  # n ≈ 1 (isothermal)
            W = P1 * V1 * log(V2 / V1)
        else
            W = (P2 * V2 - P1 * V1) / (1 - n)
        end
        values[:W] = W
    end
    
    return values
end
