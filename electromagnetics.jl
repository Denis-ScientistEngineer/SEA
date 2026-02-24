# electromagnetics.jl - Complete Electric Field Solver Suite
include("abstract_solver.jl")

# Constants
const eps_0 = 8.854e-12  # Permittivity of free space (F/m)
const K = 1.0 / (4 * π * eps_0)  # Coulomb's constant ≈ 8.99e9

# =============================================================================
# POINT CHARGE ELECTRIC FIELD: E = kQ/r²
# =============================================================================

struct PointChargeFieldSolver <: PhysicsSolver end

function can_solve(::PointChargeFieldSolver, variables::Set{Symbol})::Bool
    has_charge = :Q in variables
    has_field_point = all(v in variables for v in [:x, :y, :z])
    has_charge_location = all(v in variables for v in [:x0, :y0, :z0])
    return has_charge && has_field_point && has_charge_location
end

function validate_inputs(::PointChargeFieldSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q, :x, :y, :z, :x0, :y0, :z0]
    return all(haskey(values, v) for v in required)
end

get_priority(::PointChargeFieldSolver) = 80
get_description(::PointChargeFieldSolver) = "Point Charge Electric Field (E = kQ/r²)"
get_domain(::PointChargeFieldSolver) = :electromagnetics

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
# ELECTRIC POTENTIAL: V = kQ/r
# =============================================================================

struct ElectricPotentialSolver <: PhysicsSolver end

function can_solve(::ElectricPotentialSolver, variables::Set{Symbol})::Bool
    has_charge = :Q in variables
    has_field_point = all(v in variables for v in [:x, :y, :z])
    has_charge_location = all(v in variables for v in [:x0, :y0, :z0])
    return has_charge && has_field_point && has_charge_location
end

function validate_inputs(::ElectricPotentialSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q, :x, :y, :z, :x0, :y0, :z0]
    return all(haskey(values, v) for v in required)
end

get_priority(::ElectricPotentialSolver) = 75
get_description(::ElectricPotentialSolver) = "Electric Potential (V = kQ/r)"
get_domain(::ElectricPotentialSolver) = :electromagnetics

function solve(::ElectricPotentialSolver, values::Dict{Symbol, Float64})
    Q = values[:Q]
    field_point = [values[:x], values[:y], values[:z]]
    charge_position = [values[:x0], values[:y0], values[:z0]]
    
    r_vec = field_point - charge_position
    r = sqrt(sum(r_vec.^2))
    
    if r < 1e-15
        values[:V] = Inf
    else
        values[:V] = K * Q / r
    end
    
    return values
end

# =============================================================================
# COULOMB'S LAW (Force): F = kQ₁Q₂/r²
# =============================================================================

struct CoulombForceSolver <: PhysicsSolver end

function can_solve(::CoulombForceSolver, variables::Set{Symbol})::Bool
    has_charges = :Q1 in variables && :Q2 in variables
    has_charge1_pos = all(v in variables for v in [:x1, :y1, :z1])
    has_charge2_pos = all(v in variables for v in [:x2, :y2, :z2])
    return has_charges && has_charge1_pos && has_charge2_pos
end

function validate_inputs(::CoulombForceSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q1, :Q2, :x1, :y1, :z1, :x2, :y2, :z2]
    return all(haskey(values, v) for v in required)
end

get_priority(::CoulombForceSolver) = 85
get_description(::CoulombForceSolver) = "Coulomb's Law (F = kQ₁Q₂/r²)"
get_domain(::CoulombForceSolver) = :electromagnetics

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
# INFINITE LINE CHARGE: E = (λ/2πε₀) * (1/r) perpendicular to line
# =============================================================================

struct InfiniteLineChargeSolver <: PhysicsSolver end

function can_solve(::InfiniteLineChargeSolver, variables::Set{Symbol})::Bool
    # Need: lambda (linear charge density), perpendicular distance r from line
    # For line along z-axis: need x, y (field point)
    has_lambda = :lambda in variables || :λ in variables
    has_field_point = (:x in variables && :y in variables)
    return has_lambda && has_field_point
end

function validate_inputs(::InfiniteLineChargeSolver, values::Dict{Symbol, Float64})::Bool
    has_lambda = haskey(values, :lambda) || haskey(values, :λ)
    has_xy = haskey(values, :x) && haskey(values, :y)
    return has_lambda && has_xy
end

get_priority(::InfiniteLineChargeSolver) = 70
get_description(::InfiniteLineChargeSolver) = "Infinite Line Charge (E = λ/2πε₀r)"
get_domain(::InfiniteLineChargeSolver) = :electromagnetics

function solve(::InfiniteLineChargeSolver, values::Dict{Symbol, Float64})
    λ = get(values, :lambda, get(values, :λ, 0.0))
    x = values[:x]
    y = values[:y]
    
    # Distance from z-axis
    r = sqrt(x^2 + y^2)
    
    if r < 1e-15
        values[:Ex] = 0.0
        values[:Ey] = 0.0
        values[:Ez] = 0.0
        values[:E_magnitude] = 0.0
        return values
    end
    
    # E field magnitude: E = λ/(2πε₀r)
    E_magnitude = λ / (2 * π * eps_0 * r)
    
    # Direction: radially outward from z-axis
    r_hat_x = x / r
    r_hat_y = y / r
    
    values[:Ex] = E_magnitude * r_hat_x
    values[:Ey] = E_magnitude * r_hat_y
    values[:Ez] = 0.0
    values[:E_magnitude] = E_magnitude
    
    return values
end

# =============================================================================
# INFINITE PLANE CHARGE: E = σ/2ε₀
# =============================================================================

struct InfinitePlaneSolver <: PhysicsSolver end

function can_solve(::InfinitePlaneSolver, variables::Set{Symbol})::Bool
    # Need: sigma (surface charge density)
    # Field is uniform, independent of position!
    has_sigma = :sigma in variables || :σ in variables
    return has_sigma
end

function validate_inputs(::InfinitePlaneSolver, values::Dict{Symbol, Float64})::Bool
    return haskey(values, :sigma) || haskey(values, :σ)
end

get_priority(::InfinitePlaneSolver) = 65
get_description(::InfinitePlaneSolver) = "Infinite Plane Charge (E = σ/2ε₀)"
get_domain(::InfinitePlaneSolver) = :electromagnetics

function solve(::InfinitePlaneSolver, values::Dict{Symbol, Float64})
    σ = get(values, :sigma, get(values, :σ, 0.0))
    
    # E field magnitude (uniform, perpendicular to plane)
    E_magnitude = σ / (2 * eps_0)
    
    # Assuming plane is xy-plane, field points in z-direction
    values[:Ex] = 0.0
    values[:Ey] = 0.0
    values[:Ez] = E_magnitude
    values[:E_magnitude] = abs(E_magnitude)
    
    return values
end

# =============================================================================
# UNIFORMLY CHARGED RING: E on axis
# =============================================================================

struct ChargedRingSolver <: PhysicsSolver end

function can_solve(::ChargedRingSolver, variables::Set{Symbol})::Bool
    # Need: Q (total charge), R (radius), z (distance along axis)
    has_charge = :Q in variables
    has_radius = :R in variables
    has_z = :z in variables
    return has_charge && has_radius && has_z
end

function validate_inputs(::ChargedRingSolver, values::Dict{Symbol, Float64})::Bool
    required = [:Q, :R, :z]
    return all(haskey(values, v) for v in required)
end

get_priority(::ChargedRingSolver) = 75
get_description(::ChargedRingSolver) = "Uniformly Charged Ring on Axis"
get_domain(::ChargedRingSolver) = :electromagnetics

function solve(::ChargedRingSolver, values::Dict{Symbol, Float64})
    Q = values[:Q]
    R = values[:R]
    z = values[:z]
    
    # E field on axis: E_z = kQz/(R² + z²)^(3/2)
    denom = (R^2 + z^2)^1.5
    
    if denom < 1e-15
        values[:Ex] = 0.0
        values[:Ey] = 0.0
        values[:Ez] = 0.0
        values[:E_magnitude] = 0.0
        return values
    end
    
    E_z = K * Q * z / denom
    
    values[:Ex] = 0.0
    values[:Ey] = 0.0
    values[:Ez] = E_z
    values[:E_magnitude] = abs(E_z)
    
    return values
end

# =============================================================================
# UNIFORMLY CHARGED DISK: E on axis
# =============================================================================

struct ChargedDiskSolver <: PhysicsSolver end

function can_solve(::ChargedDiskSolver, variables::Set{Symbol})::Bool
    # Need: sigma (surface charge density), R (radius), z (distance along axis)
    has_sigma = :sigma in variables || :σ in variables
    has_radius = :R in variables
    has_z = :z in variables
    return has_sigma && has_radius && has_z
end

function validate_inputs(::ChargedDiskSolver, values::Dict{Symbol, Float64})::Bool
    has_sigma = haskey(values, :sigma) || haskey(values, :σ)
    has_R = haskey(values, :R)
    has_z = haskey(values, :z)
    return has_sigma && has_R && has_z
end

get_priority(::ChargedDiskSolver) = 75
get_description(::ChargedDiskSolver) = "Uniformly Charged Disk on Axis"
get_domain(::ChargedDiskSolver) = :electromagnetics

function solve(::ChargedDiskSolver, values::Dict{Symbol, Float64})
    σ = get(values, :sigma, get(values, :σ, 0.0))
    R = values[:R]
    z = values[:z]
    
    # E field on axis: E_z = (σ/2ε₀)[1 - z/√(R² + z²)]
    sqrt_term = sqrt(R^2 + z^2)
    
    if sqrt_term < 1e-15
        values[:Ez] = σ / (2 * eps_0)
    else
        E_z = (σ / (2 * eps_0)) * (1 - z / sqrt_term)
        values[:Ez] = E_z
    end
    
    values[:Ex] = 0.0
    values[:Ey] = 0.0
    values[:E_magnitude] = abs(values[:Ez])
    
    return values
end

# =============================================================================
# FINITE LINE CHARGE (Numerical Integration)
# =============================================================================

struct FiniteLineChargeSolver <: PhysicsSolver end

function can_solve(::FiniteLineChargeSolver, variables::Set{Symbol})::Bool
    # Need: lambda, line endpoints, field point
    has_lambda = :lambda in variables || :λ in variables
    has_line_start = all(v in variables for v in [:x0, :y0, :z0])
    has_line_end = all(v in variables for v in [:x1, :y1, :z1])
    has_field_point = all(v in variables for v in [:x, :y, :z])
    return has_lambda && has_line_start && has_line_end && has_field_point
end

function validate_inputs(::FiniteLineChargeSolver, values::Dict{Symbol, Float64})::Bool
    has_lambda = haskey(values, :lambda) || haskey(values, :λ)
    required = [:x0, :y0, :z0, :x1, :y1, :z1, :x, :y, :z]
    return has_lambda && all(haskey(values, v) for v in required)
end

get_priority(::FiniteLineChargeSolver) = 90  # Very specific!
get_description(::FiniteLineChargeSolver) = "Finite Line Charge (Numerical)"
get_domain(::FiniteLineChargeSolver) = :electromagnetics

function solve(::FiniteLineChargeSolver, values::Dict{Symbol, Float64})
    λ = get(values, :lambda, get(values, :λ, 0.0))
    
    # Line endpoints
    r_start = [values[:x0], values[:y0], values[:z0]]
    r_end = [values[:x1], values[:y1], values[:z1]]
    
    # Field point
    field_point = [values[:x], values[:y], values[:z]]
    
    # Numerical integration
    n_points = 1000
    E_total = [0.0, 0.0, 0.0]
    
    for i in 1:n_points
        # Parametric position along line
        t = (i - 0.5) / n_points
        r_prime = r_start + t * (r_end - r_start)
        
        # Vector from source element to field point
        r_vec = field_point - r_prime
        r = sqrt(sum(r_vec.^2))
        
        if r < 1e-15
            continue
        end
        
        r_hat = r_vec / r
        
        # Differential length element
        dl = sqrt(sum((r_end - r_start).^2)) / n_points
        
        # dE = k * λ * dl / r² * r̂
        dE = (K * λ * dl / r^2) * r_hat
        E_total += dE
    end
    
    values[:Ex] = E_total[1]
    values[:Ey] = E_total[2]
    values[:Ez] = E_total[3]
    values[:E_magnitude] = sqrt(sum(E_total.^2))
    
    return values
end

# =============================================================================
# PARALLEL PLATE CAPACITOR
# =============================================================================

struct ParallelPlateCapacitorSolver <: PhysicsSolver end

function can_solve(::ParallelPlateCapacitorSolver, variables::Set{Symbol})::Bool
    # Can solve for C, Q, V, or E given the others
    # Need: A (area), d (separation), and two of {C, Q, V, E}
    has_geometry = (:A in variables && :d in variables)
    
    electric_vars = [:C, :Q, :V, :E]
    num_known = count(v -> v in variables, electric_vars)
    
    return has_geometry && num_known >= 2
end

function validate_inputs(::ParallelPlateCapacitorSolver, values::Dict{Symbol, Float64})::Bool
    has_geometry = haskey(values, :A) && haskey(values, :d)
    
    electric_vars = [:C, :Q, :V, :E]
    num_known = count(v -> haskey(values, v), electric_vars)
    
    return has_geometry && num_known >= 2
end

get_priority(::ParallelPlateCapacitorSolver) = 80
get_description(::ParallelPlateCapacitorSolver) = "Parallel Plate Capacitor"
get_domain(::ParallelPlateCapacitorSolver) = :electromagnetics

function solve(::ParallelPlateCapacitorSolver, values::Dict{Symbol, Float64})
    A = values[:A]
    d = values[:d]
    
    # C = ε₀A/d
    C_calc = eps_0 * A / d
    
    # Get known values
    C = get(values, :C, nothing)
    Q = get(values, :Q, nothing)
    V = get(values, :V, nothing)
    E = get(values, :E, nothing)
    
    # Solve for missing variables using relationships:
    # Q = CV, V = Ed, E = Q/(ε₀A) = σ/ε₀
    
    if isnothing(C)
        values[:C] = C_calc
        C = C_calc
    end
    
    if !isnothing(Q) && !isnothing(V)
        # Both known, check others
        if isnothing(E)
            values[:E] = V / d
        end
    elseif !isnothing(Q) && !isnothing(E)
        if isnothing(V)
            values[:V] = E * d
        end
    elseif !isnothing(V) && !isnothing(E)
        if isnothing(Q)
            values[:Q] = C * V
        end
    elseif !isnothing(Q)
        values[:V] = Q / C
        values[:E] = values[:V] / d
    elseif !isnothing(V)
        values[:Q] = C * V
        values[:E] = V / d
    elseif !isnothing(E)
        values[:V] = E * d
        values[:Q] = C * values[:V]
    end
    
    return values
end