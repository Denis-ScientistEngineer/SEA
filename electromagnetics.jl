# electromagnetics.jl - Context-Aware Electromagnetics Solvers
include("abstract_solver.jl")

# Constants
const eps_0 = 8.854e-12  # F/m
const K = 1.0 / (4 * π * eps_0)  # Coulomb's constant ≈ 8.99e9

# =============================================================================
# POINT CHARGE ELECTRIC FIELD: E = kQ/r²
# =============================================================================

struct PointChargeFieldSolver <: PhysicsSolver end

function can_solve(::PointChargeFieldSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    # Valid in classical regime for point charges
    if context.regime == QUANTUM_MICRO
        return false  # Use quantum mechanics instead!
    end
    if context.substance != POINT_CHARGES && context.substance != FIELDS
        return false
    end
    
    has_charge = :Q in variables
    has_field_point = all(v in variables for v in [:x, :y, :z])
    has_charge_location = all(v in variables for v in [:x0, :y0, :z0])
    return has_charge && has_field_point && has_charge_location
end

function validate_inputs(::PointChargeFieldSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q, :x, :y, :z, :x0, :y0, :z0]
    return all(haskey(values, v) for v in required)
end

get_required_regime(::PointChargeFieldSolver) = CLASSICAL_MACRO
get_required_substance(::PointChargeFieldSolver) = [POINT_CHARGES]
get_physics_type(::PointChargeFieldSolver) = :electrostatics
get_priority(::PointChargeFieldSolver) = 80

get_description(::PointChargeFieldSolver) = "Point Charge Electric Field (E = kQ/r²)"
get_equation(::PointChargeFieldSolver) = "E⃗ = (kQ/r²)r̂, k ≈ 8.99×10⁹ N·m²/C²"
get_domain(::PointChargeFieldSolver) = :electromagnetics

function get_output_units(::PointChargeFieldSolver)::Dict{Symbol, String}
    return Dict(
        :Ex => "N/C",
        :Ey => "N/C",
        :Ez => "N/C",
        :E_magnitude => "N/C"
    )
end

function get_input_constraints(::PointChargeFieldSolver)::Dict{Symbol, String}
    return Dict(
        :Q => "Charge in Coulombs",
        :x => "Field point x-coordinate (m)",
        :y => "Field point y-coordinate (m)",
        :z => "Field point z-coordinate (m)",
        :x0 => "Charge x-location (m)",
        :y0 => "Charge y-location (m)",
        :z0 => "Charge z-location (m)"
    )
end

function solve(::PointChargeFieldSolver, values::Dict{Symbol, Float64})
    Q = values[:Q]
    field_point = [values[:x], values[:y], values[:z]]
    charge_position = [values[:x0], values[:y0], values[:z0]]
    
    r_vec = field_point - charge_position
    r = sqrt(sum(r_vec.^2))
    
    if r < 1e-15
        values[:Ex] = 0.0
        values[:Ey] = 0.0
        values[:Ez] = 0.0
        values[:E_magnitude] = 0.0
        return values
    end
    
    r_hat = r_vec / r
    E_vec = (K * Q / r^2) * r_hat
    
    values[:Ex] = E_vec[1]
    values[:Ey] = E_vec[2]
    values[:Ez] = E_vec[3]
    values[:E_magnitude] = sqrt(sum(E_vec.^2))
    
    return values
end

# =============================================================================
# COULOMB'S LAW: F = kQ₁Q₂/r²
# =============================================================================

struct CoulombForceSolver <: PhysicsSolver end

function can_solve(::CoulombForceSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime == QUANTUM_MICRO
        return false
    end
    if context.substance != POINT_CHARGES
        return false
    end
    
    has_charges = :Q1 in variables && :Q2 in variables
    has_charge1_pos = all(v in variables for v in [:x1, :y1, :z1])
    has_charge2_pos = all(v in variables for v in [:x2, :y2, :z2])
    return has_charges && has_charge1_pos && has_charge2_pos
end

function validate_inputs(::CoulombForceSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q1, :Q2, :x1, :y1, :z1, :x2, :y2, :z2]
    return all(haskey(values, v) for v in required)
end

get_required_regime(::CoulombForceSolver) = CLASSICAL_MACRO
get_required_substance(::CoulombForceSolver) = [POINT_CHARGES]
get_physics_type(::CoulombForceSolver) = :electrostatics
get_priority(::CoulombForceSolver) = 85

get_description(::CoulombForceSolver) = "Coulomb's Law (F = kQ₁Q₂/r²)"
get_equation(::CoulombForceSolver) = "F⃗ = k(Q₁Q₂/r²)r̂"
get_domain(::CoulombForceSolver) = :electromagnetics

function get_output_units(::CoulombForceSolver)::Dict{Symbol, String}
    return Dict(
        :Fx => "N",
        :Fy => "N",
        :Fz => "N",
        :F_magnitude => "N"
    )
end

function solve(::CoulombForceSolver, values::Dict{Symbol, Float64})
    Q1 = values[:Q1]
    Q2 = values[:Q2]
    pos1 = [values[:x1], values[:y1], values[:z1]]
    pos2 = [values[:x2], values[:y2], values[:z2]]
    
    r_vec = pos2 - pos1
    r = sqrt(sum(r_vec.^2))
    
    if r < 1e-15
        values[:Fx] = 0.0
        values[:Fy] = 0.0
        values[:Fz] = 0.0
        values[:F_magnitude] = 0.0
        return values
    end
    
    r_hat = r_vec / r
    F_vec = (K * Q1 * Q2 / r^2) * r_hat
    
    values[:Fx] = F_vec[1]
    values[:Fy] = F_vec[2]
    values[:Fz] = F_vec[3]
    values[:F_magnitude] = sqrt(sum(F_vec.^2))
    
    return values
end

# =============================================================================
# INFINITE LINE CHARGE: E = λ/(2πε₀r)
# =============================================================================

struct InfiniteLineChargeSolver <: PhysicsSolver end

function can_solve(::InfiniteLineChargeSolver, variables::Set{Symbol}, context::SystemContext)::Bool
    if context.regime != CLASSICAL_MACRO
        return false
    end
    
    has_lambda = :lambda in variables || :λ in variables
    has_field_point = (:x in variables && :y in variables)
    return has_lambda && has_field_point
end

function validate_inputs(::InfiniteLineChargeSolver, values::Dict{Symbol, Float64})::Bool
    has_lambda = haskey(values, :lambda) || haskey(values, :λ)
    has_xy = haskey(values, :x) && haskey(values, :y)
    return has_lambda && has_xy
end

get_required_regime(::InfiniteLineChargeSolver) = CLASSICAL_MACRO
get_physics_type(::InfiniteLineChargeSolver) = :electrostatics
get_priority(::InfiniteLineChargeSolver) = 70

get_description(::InfiniteLineChargeSolver) = "Infinite Line Charge (E = λ/2πε₀r)"
get_equation(::InfiniteLineChargeSolver) = "E = λ/(2πε₀r), perpendicular to line"
get_domain(::InfiniteLineChargeSolver) = :electromagnetics

function get_output_units(::InfiniteLineChargeSolver)::Dict{Symbol, String}
    return Dict(:Ex => "N/C", :Ey => "N/C", :Ez => "N/C", :E_magnitude => "N/C")
end

function solve(::InfiniteLineChargeSolver, values::Dict{Symbol, Float64})
    λ = get_any(values, :lambda, :λ)
    x = values[:x]
    y = values[:y]
    
    r = sqrt(x^2 + y^2)
    
    if r < 1e-15
        values[:Ex] = 0.0
        values[:Ey] = 0.0
        values[:Ez] = 0.0
        values[:E_magnitude] = 0.0
        return values
    end
    
    E_magnitude = λ / (2 * π * eps_0 * r)
    
    r_hat_x = x / r
    r_hat_y = y / r
    
    values[:Ex] = E_magnitude * r_hat_x
    values[:Ey] = E_magnitude * r_hat_y
    values[:Ez] = 0.0
    values[:E_magnitude] = E_magnitude
    
    return values
end

# Continue with other E&M solvers (Ring, Disk, Capacitor)...
# [I'll abbreviate here - same pattern for all remaining solvers]

# Add get_required_regime, get_physics_type, get_equation, get_output_units
# to ChargedRingSolver, ChargedDiskSolver, ParallelPlateCapacitorSolver, etc.