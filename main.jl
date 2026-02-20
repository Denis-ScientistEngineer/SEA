# =============================================================================
# FILE 7: main.jl  ← THIS IS WHERE YOU RUN THE PROGRAM
# =============================================================================
# PURPOSE: The entry point. This file:
#   1. Loads all other files (in the right order)
#   2. Registers all available solvers
#   3. Starts the interactive loop
#   4. For each user input: calls tokenizer → dispatcher → display
#
# THIS IS THE ONLY FILE YOU EVER RUN:
#   julia main.jl
# =============================================================================

# Load Printf for number formatting (used in display.jl)
using Printf

# =============================================================================
# STEP 1: LOAD ALL FILES (ORDER MATTERS!)
#
# abstract_solver.jl   → Must be FIRST (defines the contract)
# thermodynamics.jl    → Needs abstract_solver.jl (it implements the contract)
# registry.jl          → Needs abstract_solver.jl (stores PhysicsSolver list)
# tokenizer.jl         → Independent (just string processing)
# dispatcher.jl        → Needs registry.jl (searches the registry)
# display.jl           → Needs thermodynamics.jl (for typeof checks)
# =============================================================================

println("Loading system...")

include("abstract_solver.jl")    # ← The contract (FIRST!)
include("thermo.jl")     # ← All thermodynamics solvers
include("Registry.jl")           # ← The phonebook of solvers
include("tokenizer.jl")          # ← String → Dict conversion
include("dispatcher.jl")         # ← Routes Dict to right solver
include("display.jl")            # ← Pretty output formatting

println("All files loaded.\n")


# =============================================================================
# STEP 2: REGISTER ALL SOLVERS
#
# This tells the registry "these solvers exist and are available".
# When you create a new solver (e.g., solid_mechanics.jl), you just add
# one more register_solver() line here.
# =============================================================================

function initialize_solvers()
    println("Registering solvers...")
    register_solver(FirstLawSolver())        # ΔU = Q - W
    #register_solver(IdealGasSolver())        # PV = nRT
    #register_solver(HeatCapacitySolver())    # Q = mcΔT
    println("Done.\n")
end


# =============================================================================
# STEP 3: THE CORE PIPELINE
#
# This is the heart of the program.
# Every user input goes through these exact steps:
#
#   "Q=100, W=40"
#        ↓
#   [TOKENIZER]  → Dict(:Q => 100.0, :W => 40.0)
#        ↓
#   [DISPATCHER] → Finds FirstLawSolver
#        ↓
#   [SOLVER]     → Runs FirstLawSolver.solve() → adds :ΔU => 60.0
#        ↓
#   [DISPLAY]    → Prints the formatted result
# =============================================================================

"""
    process_input(input::String)

Full pipeline: user string → tokenizer → dispatcher → solver → display.
"""
function process_input(input::AbstractString)
    println("\n" * "─"^62)
    println("Processing: \"$input\"")
    println("─"^62)

    # ── STAGE 1: TOKENIZER ─────────────────────────────────────────────────
    # File: tokenizer.jl
    # This is where string manipulation happens.
    # Converts "Q=100, W=40" → Dict(:Q => 100.0, :W => 40.0)
    println("[1] Tokenizer:")
    values = parse_input(input)

    # If tokenizer failed (bad input), stop here
    if values === nothing
        return
    end

    # ── STAGE 2: DISPATCHER ────────────────────────────────────────────────
    # File: dispatcher.jl
    # Looks at the variable names (:Q, :W) and searches the registry
    # for a solver that can handle them. Returns that solver + result.
    println("[2] Dispatcher:")
    outcome = dispatch_and_solve(values)

    # If dispatcher failed (no solver found), stop here
    if outcome === nothing
        return
    end

    # ── STAGE 3: DISPLAY ───────────────────────────────────────────────────
    # File: display.jl
    # Takes the result Dict and prints it nicely.
    println("[3] Display:")
    display_result(input, outcome.result, outcome.solver)
end


# =============================================================================
# STEP 4: INTERACTIVE LOOP
# Keeps asking the user for input until they type "quit"
# =============================================================================

function run()
    println("╔══════════════════════════════════════════════════════════════╗")
    println("║             PHYSICS PROBLEM SOLVER  v1.0                     ║")
    println("║          Plugin Architecture  |  Julia Language              ║")
    println("╚══════════════════════════════════════════════════════════════╝")
    println()
    println("Type 'help' for examples or 'quit' to exit.")
    println()

    while true
        print("Enter problem: ")
        input = String(strip(readline()))  # Read user input, remove leading/trailing spaces

        # ── Handle special commands ─────────────────────────────────────
        if isempty(input)
            continue  # User just pressed Enter → ignore

        elseif lowercase(input) in ["quit", "exit", "q"]
            println("\nGoodbye! 👋")
            break

        elseif lowercase(input) == "help"
            display_help()

        elseif lowercase(input) == "solvers"
            list_registered_solvers()

        else
            # ── Normal input: run the full pipeline ─────────────────────
            process_input(input)
        end
    end
end


# =============================================================================
# STEP 5: START THE PROGRAM
# =============================================================================

initialize_solvers()    # Register all solvers first
run()                   # Start the interactive loop