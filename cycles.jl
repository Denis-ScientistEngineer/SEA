# cycles.jl - Thermodynamic Cycle Analyzers
# Models complete engine cycles and calculates efficiency!

include("abstract_solver.jl")

# =============================================================================
# CARNOT CYCLE - The Ideal Heat Engine
# Process 1-2: Isothermal expansion (absorb heat from hot reservoir)
# Process 2-3: Adiabatic expansion (temperature drops)
# Process 3-4: Isothermal compression (reject heat to cold reservoir)
# Process 4-1: Adiabatic compression (return to start)
# =============================================================================


# =============================================================================
# CARNOT CYCLE
# =============================================================================

struct CarnotCycleSolver <: PhysicsSolver end

function can_solve(::CarnotCycleSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    has_cycle_marker = :carnot in variables || :carnot_cycle in variables
    has_temps = (:Th in variables && :Tc in variables) || 
                (:T_hot in variables && :T_cold in variables)
    has_energy = any(k in variables for k in [:Qh, :Qc, :Q_hot, :Q_cold, :W])
    
    return has_cycle_marker && has_temps && has_energy
end

function validate_inputs(::CarnotCycleSolver, values::Dict{Symbol, Float64})::Bool
    Th = get(values, :Th, get(values, :T_hot, nothing))
    Tc = get(values, :Tc, get(values, :T_cold, nothing))
    
    if isnothing(Th) || isnothing(Tc)
        return false
    end
    
    if Th <= 0 || Tc <= 0 || Th <= Tc
        return false
    end
    
    has_energy = any(haskey(values, v) for v in [:Qh, :Qc, :Q_hot, :Q_cold, :W])
    return has_energy
end

get_required_regime(::CarnotCycleSolver) = CLASSICAL_MACRO
get_required_substance(::CarnotCycleSolver) = []  # No restriction
get_physics_type(::CarnotCycleSolver) = :classical_thermodynamics
get_priority(::CarnotCycleSolver) = 85

get_description(::CarnotCycleSolver) = "Carnot Cycle (Most efficient heat engine)"
get_equation(::CarnotCycleSolver) = "η = 1 - Tc/Th, W = Qh - Qc"
get_domain(::CarnotCycleSolver) = :thermodynamics

function get_output_units(::CarnotCycleSolver)::Dict{Symbol, String}
    return Dict(
        :Th => "K", :Tc => "K",
        :Qh => "J", :Qc => "J", :W => "J",
        :efficiency => "%"
    )
end

function solve(::CarnotCycleSolver, values::Dict{Symbol, Float64})
    Th = get(values, :Th, values[:T_hot])
    Tc = get(values, :Tc, values[:T_cold])
    
    η = 1.0 - Tc / Th
    values[:efficiency] = η * 100
    
    Qh = get(values, :Qh, get(values, :Q_hot, nothing))
    Qc = get(values, :Qc, get(values, :Q_cold, nothing))
    W = get(values, :W, nothing)
    
    if !isnothing(Qh)
        if isnothing(W)
            W = η * Qh
            values[:W] = W
        end
        if isnothing(Qc)
            Qc = Qh - W
            values[:Qc] = Qc
        end
    elseif !isnothing(Qc)
        Qh = Qc / (1 - η)
        values[:Qh] = Qh
        if isnothing(W)
            W = Qh - Qc
            values[:W] = W
        end
    elseif !isnothing(W)
        Qh = W / η
        values[:Qh] = Qh
        Qc = Qh - W
        values[:Qc] = Qc
    end
    
    return values
end

# =============================================================================
# OTTO CYCLE
# =============================================================================

struct OttoCycleSolver <: PhysicsSolver end

function can_solve(::OttoCycleSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    has_cycle_marker = :otto in variables || :otto_cycle in variables
    has_compression_ratio = :r in variables || :compression_ratio in variables
    has_gamma = :gamma in variables || :γ in variables
    
    return has_cycle_marker && has_compression_ratio && has_gamma
end

function validate_inputs(::OttoCycleSolver, values::Dict{Symbol, Float64})::Bool
    r = get(values, :r, get(values, :compression_ratio, nothing))
    γ = get(values, :gamma, get(values, :γ, nothing))
    
    if isnothing(r) || isnothing(γ)
        return false
    end
    
    if r <= 1 || γ < 1 || γ > 2
        return false
    end
    
    return true
end

get_required_regime(::OttoCycleSolver) = CLASSICAL_MACRO
get_required_substance(::OttoCycleSolver) = []  # No restriction
get_physics_type(::OttoCycleSolver) = :classical_thermodynamics
get_priority(::OttoCycleSolver) = 85

get_description(::OttoCycleSolver) = "Otto Cycle (Gasoline engine)"
get_equation(::OttoCycleSolver) = "η = 1 - 1/r^(γ-1)"
get_domain(::OttoCycleSolver) = :thermodynamics

function get_output_units(::OttoCycleSolver)::Dict{Symbol, String}
    return Dict(:efficiency => "%")
end

function solve(::OttoCycleSolver, values::Dict{Symbol, Float64})
    r = get(values, :r, values[:compression_ratio])
    γ = get(values, :gamma, get(values, :γ, 1.4))
    
    η = 1.0 - 1.0 / (r^(γ - 1))
    values[:efficiency] = η * 100
    
    # Additional state calculations if initial conditions provided
    P1 = get(values, :P1, nothing)
    T1 = get(values, :T1, nothing)
    V1 = get(values, :V1, nothing)
    
    if !isnothing(P1) && !isnothing(T1) && !isnothing(V1)
        V2 = V1 / r
        P2 = P1 * r^γ
        T2 = T1 * r^(γ - 1)
        
        values[:V2] = V2
        values[:P2] = P2
        values[:T2] = T2
    end
    
    return values
end

# =============================================================================
# DIESEL CYCLE
# =============================================================================

struct DieselCycleSolver <: PhysicsSolver end

function can_solve(::DieselCycleSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    has_cycle_marker = :diesel in variables || :diesel_cycle in variables
    has_compression_ratio = :r in variables || :compression_ratio in variables
    has_cutoff_ratio = :rc in variables || :cutoff_ratio in variables
    has_gamma = :gamma in variables || :γ in variables
    
    return has_cycle_marker && has_compression_ratio && has_cutoff_ratio && has_gamma
end

function validate_inputs(::DieselCycleSolver, values::Dict{Symbol, Float64})::Bool
    r = get(values, :r, get(values, :compression_ratio, nothing))
    rc = get(values, :rc, get(values, :cutoff_ratio, nothing))
    γ = get(values, :gamma, get(values, :γ, nothing))
    
    if isnothing(r) || isnothing(rc) || isnothing(γ)
        return false
    end
    
    if r <= 1 || rc <= 1 || γ < 1
        return false
    end
    
    return true
end

get_required_regime(::DieselCycleSolver) = CLASSICAL_MACRO
get_required_substance(::DieselCycleSolver) = []  # No restriction
get_physics_type(::DieselCycleSolver) = :classical_thermodynamics
get_priority(::DieselCycleSolver) = 85

get_description(::DieselCycleSolver) = "Diesel Cycle (Diesel engine)"
get_equation(::DieselCycleSolver) = "η = 1 - (1/r^(γ-1))[(rc^γ - 1)/(γ(rc - 1))]"
get_domain(::DieselCycleSolver) = :thermodynamics

function get_output_units(::DieselCycleSolver)::Dict{Symbol, String}
    return Dict(:efficiency => "%")
end

function solve(::DieselCycleSolver, values::Dict{Symbol, Float64})
    r = get(values, :r, values[:compression_ratio])
    rc = get(values, :rc, values[:cutoff_ratio])
    γ = get(values, :gamma, get(values, :γ, 1.4))
    
    η = 1.0 - (1.0 / r^(γ - 1)) * ((rc^γ - 1) / (γ * (rc - 1)))
    values[:efficiency] = η * 100
    
    return values
end

# =============================================================================
# RANKINE CYCLE
# =============================================================================

struct RankineCycleSolver <: PhysicsSolver end

function can_solve(::RankineCycleSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    has_cycle_marker = :rankine in variables || :rankine_cycle in variables
    has_pressures = :P_high in variables && :P_low in variables
    has_temps = :T_high in variables && :T_low in variables
    
    return has_cycle_marker && has_pressures && has_temps
end

function validate_inputs(::RankineCycleSolver, values::Dict{Symbol, Float64})::Bool
    P_high = get(values, :P_high, nothing)
    P_low = get(values, :P_low, nothing)
    T_high = get(values, :T_high, nothing)
    T_low = get(values, :T_low, nothing)
    
    if isnothing(P_high) || isnothing(P_low) || isnothing(T_high) || isnothing(T_low)
        return false
    end
    
    if P_high <= P_low || T_high <= T_low
        return false
    end
    
    return true
end

get_required_regime(::RankineCycleSolver) = CLASSICAL_MACRO
get_required_substance(::RankineCycleSolver) = []  # No restriction
get_physics_type(::RankineCycleSolver) = :classical_thermodynamics
get_priority(::RankineCycleSolver) = 85

get_description(::RankineCycleSolver) = "Rankine Cycle (Steam power plant)"
get_equation(::RankineCycleSolver) = "η ≈ 1 - T_low/T_high (simplified)"
get_domain(::RankineCycleSolver) = :thermodynamics

function get_output_units(::RankineCycleSolver)::Dict{Symbol, String}
    return Dict(:efficiency => "%")
end

function solve(::RankineCycleSolver, values::Dict{Symbol, Float64})
    T_high = values[:T_high]
    T_low = values[:T_low]
    
    η = 1.0 - T_low / T_high
    values[:efficiency] = η * 100
    
    return values
end

# =============================================================================
# HEAT ENGINE EFFICIENCY
# =============================================================================

struct HeatEngineEfficiencySolver <: PhysicsSolver end

function can_solve(::HeatEngineEfficiencySolver, variables::Set{Symbol}, context::SystemContext)::Bool
    has_heats = (any(k in variables for k in [:Qh, :Q_hot]) && 
                 any(k in variables for k in [:Qc, :Q_cold]))
    
    return has_heats
end

function validate_inputs(::HeatEngineEfficiencySolver, values::Dict{Symbol, Float64})::Bool
    Qh = get(values, :Qh, get(values, :Q_hot, nothing))
    Qc = get(values, :Qc, get(values, :Q_cold, nothing))
    
    if isnothing(Qh) || isnothing(Qc)
        return false
    end
    
    if Qh <= 0 || Qc < 0 || Qc > Qh
        return false
    end
    
    return true
end

get_required_regime(::HeatEngineEfficiencySolver) = CLASSICAL_MACRO
get_required_substance(::HeatEngineEfficiencySolver) = []  # No restriction
get_physics_type(::HeatEngineEfficiencySolver) = :classical_thermodynamics
get_priority(::HeatEngineEfficiencySolver) = 70

get_description(::HeatEngineEfficiencySolver) = "Heat Engine Efficiency (η = W/Qh)"
get_equation(::HeatEngineEfficiencySolver) = "η = (Qh - Qc)/Qh = W/Qh"
get_domain(::HeatEngineEfficiencySolver) = :thermodynamics

function get_output_units(::HeatEngineEfficiencySolver)::Dict{Symbol, String}
    return Dict(:W => "J", :efficiency => "%")
end

function solve(::HeatEngineEfficiencySolver, values::Dict{Symbol, Float64})
    Qh = get(values, :Qh, values[:Q_hot])
    Qc = get(values, :Qc, values[:Q_cold])
    
    W = Qh - Qc
    values[:W] = W
    
    η = W / Qh
    values[:efficiency] = η * 100
    
    return values
end
