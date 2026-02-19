# =============================================================================
# FILE 6: display.jl
# =============================================================================
# PURPOSE: This file handles ALL output formatting.
#          It takes the result Dict and prints it beautifully.
#
# IT DOES NOT SOLVE ANYTHING. It only formats and prints.
# Keeping display separate means you can change how things look
# without touching any solver or parsing code.
# =============================================================================


# =============================================================================
# DISPLAY THE FINAL SOLUTION
# =============================================================================

"""
    display_result(input::String, values::Dict, solver)

Print a clean, formatted solution report.
"""
function display_result(input::String, values::Dict{Symbol, Float64}, solver::PhysicsSolver)
    domain  = get_domain(solver)
    solver_name = typeof(solver)

    println()
    println("╔" * "═"^60 * "╗")
    println("║" * "  SOLUTION" * " "^50 * "║")
    println("╠" * "═"^60 * "╣")
    println("║  Input:  " * rpad(input, 50) * "║")
    println("║  Solver: " * rpad(string(solver_name), 50) * "║")
    println("║  Domain: " * rpad(string(domain), 50) * "║")
    println("╠" * "═"^60 * "╣")
    println("║  Results:                                              ║")

    # Print each variable and its value
    for (var, val) in sort(collect(values))
        # Skip our internal markers
        if var == :unknown_was
            continue
        end

        # Format the number nicely
        val_str = format_value(val)
        line = "║    $(rpad(string(var), 10)) =  $(val_str)"
        println(line * " "^max(0, 61 - length(line)) * "║")
    end

    println("╚" * "═"^60 * "╝")
    println()
end


# =============================================================================
# DISPLAY THE EQUATION THAT WAS USED
# =============================================================================

"""
    display_equation(solver, values)

Print the equation with numbers substituted in.
"""
function display_equation(solver::PhysicsSolver, values::Dict{Symbol, Float64})
    if typeof(solver) == FirstLawSolver
        Q  = get(values, :Q,  get(values, :q,  get(values, :heat, "?")))
        W  = get(values, :W,  get(values, :w,  get(values, :work, "?")))
        U  = get(values, :ΔU, get(values, :U,  get(values, :u,  "?")))

        println("  Equation: ΔU = Q - W")
        println("  With values: ΔU = $U = $Q - $W")

    elseif typeof(solver) == IdealGasSolver
        println("  Equation: PV = nRT")

    elseif typeof(solver) == HeatCapacitySolver
        println("  Equation: Q = mcΔT")
    end
end


# =============================================================================
# HELPER: Format a number nicely
# =============================================================================

"""
    format_value(val::Float64) -> String

Format a number for display.
- Large numbers use scientific notation
- Small decimals show more decimal places
- Normal numbers show 4 decimal places
"""
function format_value(val::Float64)::String
    if abs(val) >= 100_000 || (abs(val) < 0.001 && val != 0.0)
        return @sprintf("%.4e", val)   # Scientific notation
    else
        return @sprintf("%.4f", val)   # Normal decimal
    end
end


# =============================================================================
# ERROR DISPLAY
# =============================================================================

"""
    display_error(msg::String)

Print an error message in a visible format.
"""
function display_error(msg::String)
    println()
    println("╔" * "═"^60 * "╗")
    println("║  ❌ ERROR" * " "^51 * "║")
    println("╠" * "═"^60 * "╣")
    for line in split(msg, "\n")
        println("║  " * rpad(line, 58) * "║")
    end
    println("╚" * "═"^60 * "╝")
    println()
end


# =============================================================================
# HELP DISPLAY
# =============================================================================

"""
    display_help()

Print usage instructions.
"""
function display_help()
    println("""
    
    ╔══════════════════════════════════════════════════════════════╗
    ║                    HOW TO USE THIS SOLVER                   ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Enter variables and values using = signs, separated by     ║
    ║  commas. The solver finds the unknown automatically.        ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  THERMODYNAMICS EXAMPLES:                                   ║
    ║                                                              ║
    ║  First Law (ΔU = Q - W):                                    ║
    ║    Q=100, W=40         → finds ΔU                          ║
    ║    heat=200, work=80   → finds ΔU  (aliases work too!)     ║
    ║    ΔU=60, W=40         → finds Q                           ║
    ║    Q=100, ΔU=60        → finds W                           ║
    ║                                                              ║
    ║  Ideal Gas Law (PV = nRT):                                  ║
    ║    P=101325, V=0.5, T=300    → finds n                     ║
    ║    P=101325, n=2, T=300      → finds V                     ║
    ║                                                              ║
    ║  Heat Capacity (Q = mcΔT):                                  ║
    ║    m=2, c=4186, dT=10        → finds Q                     ║
    ║    Q=83720, m=2, c=4186      → finds dT                    ║
    ║                                                              ║
    ║  COMMANDS:                                                   ║
    ║    help       → show this help                              ║
    ║    solvers    → list all available solvers                  ║
    ║    quit       → exit                                        ║
    ╚══════════════════════════════════════════════════════════════╝
    """)
end


