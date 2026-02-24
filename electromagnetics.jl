# electromagnetics.jl - Electric Field Solvers
include("abstract_solver.jl")

# Constants
const eps_0 = 8.854e-12  # Permittivity of free space
const K = 1.0 / (4 * π * eps_0)  # Coulomb's constant

# =============================================================================
# POINT CHARGE ELECTRIC FIELD: E = kQ/r²
# =============================================================================

struct PointChargeFieldSolver <: PhysicsSolver end

function can_solve(::PointChargeFieldSolver, variables::Set{Symbol})::Bool
    # Need: Q (charge), x, y, z (field point), x0, y0, z0 (charge location)
    has_charge = :Q in variables
    has_field_point = all(v in variables for v in [:x, :y, :z])
    has_charge_location = all(v in variables for v in [:x0, :y0, :z0])
    
    return has_charge && has_field_point && has_charge_location
end

function validate_inputs(::PointChargeFieldSolver, values::Dict{Symbol, Float64})::Bool
    # Check all required variables are present
    required = [:Q, :x, :y, :z, :x0, :y0, :z0]
    return all(haskey(values, v) for v in required)
end

function get_priority(::PointChargeFieldSolver)::Int
    return 80  # High priority - very specific calculation
end

function get_description(::PointChargeFieldSolver)::String
    return "Point Charge Electric Field (E = kQ/r²)"
end

function solve(::PointChargeFieldSolver, values::Dict{Symbol, Float64})
    # Get charge
    Q = values[:Q]
    
    # Get field point
    field_point = [values[:x], values[:y], values[:z]]
    
    # Get charge location
    charge_position = [values[:x0], values[:y0], values[:z0]]
    
    # Calculate displacement vector
    r_vec = field_point - charge_position
    r = sqrt(r_vec[1]^2 + r_vec[2]^2 + r_vec[3]^2)
    
    # Check for singularity
    if r < 1e-15
        @warn "Field point too close to charge location"
        values[:Ex] = 0.0
        values[:Ey] = 0.0
        values[:Ez] = 0.0
        values[:E_magnitude] = 0.0
        return values
    end
    
    # Unit vector
    r_hat = r_vec / r
    
    # Calculate electric field: E = kQ/r² * r_hat
    E_magnitude = K * abs(Q) / r^2
    E_vec = (K * Q / r^2) * r_hat
    
    # Store results
    values[:Ex] = E_vec[1]
    values[:Ey] = E_vec[2]
    values[:Ez] = E_vec[3]
    values[:E_magnitude] = E_magnitude
    
    return values
end

get_domain(::PointChargeFieldSolver) = :electromagnetics

# =============================================================================
# ELECTRIC POTENTIAL: V = kQ/r
# =============================================================================

struct ElectricPotentialSolver <: PhysicsSolver end

function can_solve(::ElectricPotentialSolver, variables::Set{Symbol})::Bool
    # Need: Q (charge), x, y, z (field point), x0, y0, z0 (charge location)
    # But NOT asking for E field components
    has_charge = :Q in variables
    has_field_point = all(v in variables for v in [:x, :y, :z])
    has_charge_location = all(v in variables for v in [:x0, :y0, :z0])
    wants_potential = !any(v in variables for v in [:Ex, :Ey, :Ez])
    
    return has_charge && has_field_point && has_charge_location && wants_potential
end

function validate_inputs(::ElectricPotentialSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q, :x, :y, :z, :x0, :y0, :z0]
    return all(haskey(values, v) for v in required)
end

function get_priority(::ElectricPotentialSolver)::Int
    return 75  # Slightly lower than field solver
end

function get_description(::ElectricPotentialSolver)::String
    return "Electric Potential (V = kQ/r)"
end

function solve(::ElectricPotentialSolver, values::Dict{Symbol, Float64})
    Q = values[:Q]
    field_point = [values[:x], values[:y], values[:z]]
    charge_position = [values[:x0], values[:y0], values[:z0]]
    
    r_vec = field_point - charge_position
    r = sqrt(r_vec[1]^2 + r_vec[2]^2 + r_vec[3]^2)
    
    if r < 1e-15
        @warn "Field point too close to charge location"
        values[:V] = Inf
        return values
    end
    
    # V = kQ/r
    values[:V] = K * Q / r
    
    return values
end

get_domain(::ElectricPotentialSolver) = :electromagnetics

# =============================================================================
# COULOMB'S LAW: F = kQ1Q2/r²
# =============================================================================

struct CoulombForceSolver <: PhysicsSolver end

function can_solve(::CoulombForceSolver, variables::Set{Symbol})::Bool
    # Need two charges and their positions
    has_charges = :Q1 in variables && :Q2 in variables
    has_charge1_pos = all(v in variables for v in [:x1, :y1, :z1])
    has_charge2_pos = all(v in variables for v in [:x2, :y2, :z2])
    
    return has_charges && has_charge1_pos && has_charge2_pos
end

function validate_inputs(::CoulombForceSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q1, :Q2, :x1, :y1, :z1, :x2, :y2, :z2]
    return all(haskey(values, v) for v in required)
end

function get_priority(::CoulombForceSolver)::Int
    return 85  # Very specific - two charges
end

function get_description(::CoulombForceSolver)::String
    return "Coulomb's Law (F = kQ₁Q₂/r²)"
end

function solve(::CoulombForceSolver, values::Dict{Symbol, Float64})
    Q1 = values[:Q1]
    Q2 = values[:Q2]
    
    pos1 = [values[:x1], values[:y1], values[:z1]]
    pos2 = [values[:x2], values[:y2], values[:z2]]
    
    r_vec = pos2 - pos1
    r = sqrt(r_vec[1]^2 + r_vec[2]^2 + r_vec[3]^2)
    
    if r < 1e-15
        @warn "Charges at same location"
        values[:Fx] = 0.0
        values[:Fy] = 0.0
        values[:Fz] = 0.0
        values[:F_magnitude] = 0.0
        return values
    end
    
    r_hat = r_vec / r
    
    # F = kQ1Q2/r² along r_hat direction
    F_magnitude = K * abs(Q1 * Q2) / r^2
    F_vec = (K * Q1 * Q2 / r^2) * r_hat
    
    values[:Fx] = F_vec[1]
    values[:Fy] = F_vec[2]
    values[:Fz] = F_vec[3]
    values[:F_magnitude] = F_magnitude
    
    return values
end

get_domain(::CoulombForceSolver) = :electromagnetics