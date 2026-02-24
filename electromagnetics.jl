# All files must include the abstract_sover to include the contract
 module Electromagnetics

 using LinearAlgebra
 using QuadGK


struct PointCharge <: PhysicsSolver
    Q::Union{Float64, Nothing}
    location::Vector{Float64}
end


# Since every solver in every domain must follow the contract of PhysicsSolver, we need to implement the three required functions: can_solve, solve, and get_domain


end