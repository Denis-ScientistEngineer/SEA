# system_context.jl - Physical System Framework
# Based on the 4 Pillars: Classical, Statistical, Quantum, Relativistic

# =============================================================================
# PHYSICAL SCALE REGIMES (Based on Real Physics!)
# =============================================================================

@enum ScaleRegime begin
    CLASSICAL_MACRO     # Everyday objects: size > 1μm, T > 1K, v << c
    STATISTICAL_MESO    # Molecular scale: Knudsen 0.01 < Kn < 10
    QUANTUM_MICRO       # Atomic/subatomic: ℏ matters, λ ~ size
    RELATIVISTIC        # High speed: v ≈ c, E ≈ mc²
end

# =============================================================================
# SYSTEM TYPES (Thermodynamics Classification)
# =============================================================================

@enum SystemType begin
    ISOLATED    # No mass, no energy transfer (dE=0, dM=0)
    CLOSED      # Energy transfer, no mass (dE≠0, dM=0) - Most common!
    OPEN        # Both mass and energy transfer (dE≠0, dM≠0)
end

@enum BoundaryType begin
    RIGID       # Fixed volume (dV=0) - no PdV work
    FLEXIBLE    # Movable boundary (dV≠0) - PdV work possible
    PERMEABLE   # Mass can pass through (dN≠0)
    CONDUCTING  # Heat can pass through (dQ≠0)
    INSULATING  # No heat transfer (dQ=0) - adiabatic
end

# =============================================================================
# SUBSTANCE TYPES (What's in the system?)
# =============================================================================

@enum SubstanceType begin
    IDEAL_GAS       # PV=nRT regime (low P, high T)
    REAL_GAS        # Van der Waals corrections needed
    LIQUID          # Incompressible fluid
    SOLID           # Rigid structure
    PLASMA          # Ionized gas
    POINT_CHARGES   # Electrostatics
    FIELDS          # EM fields, no matter
    VACUUM          # Empty space
end

# =============================================================================
# PHYSICAL CONSTANTS FOR REGIME DETECTION
# =============================================================================

const ℏ = 1.054571817e-34    # Planck's constant / 2π (J·s)
const c = 299792458.0        # Speed of light (m/s)
const k_B = 1.380649e-23     # Boltzmann constant (J/K)
const m_e = 9.1093837e-31    # Electron mass (kg)
const m_p = 1.6726219e-27    # Proton mass (kg)

# =============================================================================
# SYSTEM CONTEXT - Complete Physical Description
# =============================================================================

"""
    SystemContext

Complete description of the physical system, including:
- Scale regime (which physics applies)
- System type (open/closed/isolated)
- Boundary properties
- Substance type
- Physical parameters (T, P, size, velocity)

This determines which solvers are physically valid!
"""
struct SystemContext
    # Primary classification
    regime::ScaleRegime
    system_type::SystemType
    boundary_type::BoundaryType
    substance::SubstanceType
    
    # Physical parameters (for regime detection)
    characteristic_length::Union{Nothing, Float64}  # meters
    characteristic_velocity::Union{Nothing, Float64}  # m/s
    temperature::Union{Nothing, Float64}  # Kelvin
    pressure::Union{Nothing, Float64}  # Pascal
    particle_energy::Union{Nothing, Float64}  # Joules
    
    # Computed properties
    knudsen_number::Union{Nothing, Float64}
    reynolds_number::Union{Nothing, Float64}
    beta::Union{Nothing, Float64}  # v/c for relativistic check
end

# Default constructor
function SystemContext(;
    regime=CLASSICAL_MACRO,
    system_type=CLOSED,
    boundary_type=FLEXIBLE,
    substance=IDEAL_GAS,
    characteristic_length=nothing,
    characteristic_velocity=nothing,
    temperature=nothing,
    pressure=nothing,
    particle_energy=nothing
)
    # Compute derived quantities
    kn = compute_knudsen(characteristic_length, pressure, temperature)
    re = compute_reynolds(characteristic_length, characteristic_velocity)
    beta = isnothing(characteristic_velocity) ? nothing : characteristic_velocity / c
    
    SystemContext(
        regime, system_type, boundary_type, substance,
        characteristic_length, characteristic_velocity,
        temperature, pressure, particle_energy,
        kn, re, beta
    )
end

# =============================================================================
# REGIME DETECTION FUNCTIONS (The Science!)
# =============================================================================

"""
Compute Knudsen number: Kn = λ/L
where λ = mean free path, L = characteristic length

Kn > 10    → Free molecular flow (kinetic theory)
0.01 < Kn < 10 → Transitional (statistical mechanics)
Kn < 0.01  → Continuum (classical thermodynamics)
"""
function compute_knudsen(L, P, T)
    if isnothing(L) || isnothing(P) || isnothing(T)
        return nothing
    end
    
    # Mean free path: λ ≈ k_B*T/(√2*π*d²*P)
    # Using d ≈ 3.7e-10 m for air
    d = 3.7e-10
    λ = k_B * T / (sqrt(2) * π * d^2 * P)
    
    return λ / L
end

"""
Compute Reynolds number: Re = ρvL/μ
Determines if flow is laminar or turbulent
"""
function compute_reynolds(L, v)
    if isnothing(L) || isnothing(v)
        return nothing
    end
    
    # Simplified: just return order of magnitude estimate
    # For air: ρ ≈ 1 kg/m³, μ ≈ 1.8e-5 Pa·s
    return 1.0 * v * L / 1.8e-5
end

"""
    infer_regime(values::Dict{Symbol, Float64}) -> ScaleRegime

Automatically detect which physical regime applies based on:
- Size scales
- Energy scales  
- Velocity scales
- Temperature

This is THE KEY FUNCTION - it decides which physics is valid!
"""
function infer_regime(values::Dict{Symbol, Float64})::ScaleRegime
    # 1. Check for relativistic regime (v/c > 0.1)
    if haskey(values, :v)
        β = values[:v] / c
        if β > 0.1
            return RELATIVISTIC
        end
    end
    
    # 2. Check for quantum regime (de Broglie wavelength ~ size)
    # λ_dB = h/p = h/(mv)
    if haskey(values, :E) && haskey(values, :m)
        # For particle with kinetic energy E = ½mv²
        v = sqrt(2 * values[:E] / values[:m])
        λ_dB = ℏ / (values[:m] * v)
        
        # If characteristic length is similar to de Broglie wavelength
        if haskey(values, :L) && λ_dB / values[:L] > 0.1
            return QUANTUM_MICRO
        end
        
        # Or if energy is in eV scale (< keV)
        if values[:E] < 1e-16  # ~1 keV
            return QUANTUM_MICRO
        end
    end
    
    # 3. Check for statistical/mesoscopic (Knudsen number)
    if haskey(values, :L) && haskey(values, :P) && haskey(values, :T)
        kn = compute_knudsen(values[:L], values[:P], values[:T])
        if !isnothing(kn)
            if kn > 10
                return STATISTICAL_MESO  # Free molecular
            elseif kn > 0.01
                return STATISTICAL_MESO  # Transitional
            end
        end
    end
    
    # 4. Default: Classical macroscopic
    return CLASSICAL_MACRO
end

"""
    infer_substance(values::Dict{Symbol, Float64}) -> SubstanceType

Detect what substance we're dealing with based on variables
"""
function infer_substance(values::Dict{Symbol, Float64})::SubstanceType
    # Electromagnetism variables
    if any(k in keys(values) for k in [:Q, :E, :V, :lambda, :sigma])
        if haskey(values, :Q)
            return POINT_CHARGES
        else
            return FIELDS
        end
    end
    
    # Gas variables (P, V, T, n)
    if any(k in keys(values) for k in [:P, :V, :n, :T])
        # Check if ideal gas regime (low P, high T)
        if haskey(values, :P) && haskey(values, :T)
            # Ideal gas valid if P < 10 atm and T > 100K (rough)
            if values[:P] < 1e6 && values[:T] > 100
                return IDEAL_GAS
            else
                return REAL_GAS
            end
        end
        return IDEAL_GAS  # Default
    end
    
    # Thermodynamics variables (Q, W, U)
    if any(k in keys(values) for k in [:Q, :W, :U, :ΔU])
        return IDEAL_GAS  # Assume gas for thermo
    end
    
    return IDEAL_GAS  # Safe default
end

"""
    infer_context(values::Dict{Symbol, Float64}) -> SystemContext

Automatically infer the complete system context from input variables.
This is called by the dispatcher to determine valid solvers!
"""
function infer_context(values::Dict{Symbol, Float64})::SystemContext
    regime = infer_regime(values)
    substance = infer_substance(values)
    
    # Extract physical parameters if present
    L = get(values, :L, nothing)
    v = get(values, :v, nothing)
    T = get(values, :T, nothing)
    P = get(values, :P, nothing)
    E = get(values, :E, nothing)
    
    return SystemContext(
        regime=regime,
        system_type=CLOSED,  # Default
        boundary_type=FLEXIBLE,  # Default
        substance=substance,
        characteristic_length=L,
        characteristic_velocity=v,
        temperature=T,
        pressure=P,
        particle_energy=E
    )
end

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

"""
Check if given physics is valid in this regime
"""
function is_regime_valid(context::SystemContext, physics::Symbol)::Bool
    if physics == :classical_thermodynamics
        return context.regime == CLASSICAL_MACRO
        
    elseif physics == :ideal_gas_law
        return context.regime == CLASSICAL_MACRO && 
               context.substance == IDEAL_GAS
               
    elseif physics == :quantum_mechanics
        return context.regime == QUANTUM_MICRO
        
    elseif physics == :statistical_mechanics
        return context.regime in [STATISTICAL_MESO, QUANTUM_MICRO]
        
    elseif physics == :relativistic_mechanics
        return context.regime == RELATIVISTIC
        
    elseif physics == :electrostatics
        return context.substance in [POINT_CHARGES, FIELDS]
    end
    
    return true  # Default: assume valid
end

"""
Get human-readable description of regime
"""
function describe_regime(regime::ScaleRegime)::String
    if regime == CLASSICAL_MACRO
        return "Classical Macroscopic (L > 1μm, v << c, kT >> ℏω)"
    elseif regime == STATISTICAL_MESO
        return "Statistical/Mesoscopic (Molecular scale, Knudsen effects)"
    elseif regime == QUANTUM_MICRO
        return "Quantum Microscopic (λ_dB ~ L, ℏ matters)"
    elseif regime == RELATIVISTIC
        return "Relativistic (v ≈ c, E ≈ mc²)"
    end
    return "Unknown"
end