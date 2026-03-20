# SEA 1.4 - B-SPEC Framework
### Physics Solver with Four Pillars of Mechanics Integration

[![Status](https://img.shields.io/badge/status-experimental-orange.svg)](https://github.com/Denis-ScientistEngineer/SEA1.4)
[![Julia](https://img.shields.io/badge/Julia-1.10-blue.svg)](https://julialang.org/)

> **B-SPEC Framework**: Boundary-System-Properties-Equilibrium-Condition  
> Developed by **Denis Muinde** for Kyoto University of Advanced Science (KUAS) Graduate Program Application

---

## 🎯 Project Vision

SEA 1.4 represents a **fundamental rethinking** of how physics solvers should work. Instead of treating mechanics as separate domains (classical, quantum, statistical, relativistic), B-SPEC recognizes that **all mechanics unifies through four foundational pillars** based on scale and speed.

This is not just a physics solver - it's an **architectural framework** for understanding how physical laws emerge at different regimes.

---

## ✨ The Four Pillars of Mechanics

### **The Foundation**

All of physics can be understood through four fundamental regimes:

```
┌─────────────────────────────────────────────────────────────┐
│  CLASSICAL     │  v << c, L >> λ_dB                         │
│  (Newton)      │  Everyday objects, macroscopic scale       │
├─────────────────────────────────────────────────────────────┤
│  STATISTICAL   │  N > 1000 particles                        │
│  (Boltzmann)   │  Thermodynamics emerges from statistics    │
├─────────────────────────────────────────────────────────────┤
│  QUANTUM       │  L ~ λ_dB, v << c                          │
│  (Schrödinger) │  Wave-particle duality, atomic scale       │
├─────────────────────────────────────────────────────────────┤
│  RELATIVISTIC  │  v ~ c, L >> λ_dB                          │
│  (Einstein)    │  High speeds, spacetime effects            │
└─────────────────────────────────────────────────────────────┘
```

**Key Insight:** The regime is **automatically detected** from the input values!

---

## 🏗️ B-SPEC Architecture

### **What is B-SPEC?**

**B** - Boundary Conditions (Open? Closed? Isolated?)  
**S** - System Type (Thermodynamic? Electromagnetic? Mechanical?)  
**P** - Properties (Temperature, pressure, charge, etc.)  
**E** - Equilibrium State (What are we solving for?)  
**C** - Constraints (What's constant? What's changing?)

### **How It Works**

```
Input Values
    ↓
Regime Detection (Automatic!)
    ├─ β = v/c → Relativistic?
    ├─ λ_dB/L → Quantum?
    ├─ N > 1000 → Statistical?
    └─ Else → Classical
    ↓
System Inference
    ├─ Thermodynamic System
    ├─ Electromagnetic System
    └─ Mechanical System
    ↓
Solver Selection
    ├─ Filter by regime compatibility
    ├─ Check variable matching
    └─ Return highest priority
    ↓
Solve & Return Result
```

---

## 📊 Current Capabilities

### **11 Working Solvers Across 3 Domains**

#### **Thermodynamics (3 solvers)**
- First Law: `ΔU = Q - W`
- Ideal Gas Law: `PV = nRT`
- Heat Capacity: `Q = mcΔT`

#### **Thermodynamic Cycles (5 solvers)**
- Heat Engine Efficiency
- Carnot Cycle
- Otto Cycle (gasoline engine)
- Diesel Cycle
- Rankine Cycle (steam turbine)

#### **Electromagnetics (3 solvers)**
- Point Charge Electric Field: `E = kQ/r²`
- Coulomb Force: `F = kQ₁Q₂/r²`
- Infinite Line Charge: `E = λ/(2πε₀r)`

**All solvers are regime-aware!** They check if the problem matches their applicable physics regime.

---

## 🚀 Quick Start

### **Local Setup**

```bash
# Clone repository
git clone https://github.com/Denis-ScientistEngineer/SEA1.4.git
cd SEA1.4

# Install Julia 1.10+
# Download from: https://julialang.org/downloads/

# Install dependencies
julia -e 'using Pkg; Pkg.add(["HTTP", "JSON"])'

# Run server
julia server.jl

# Open browser
http://localhost:8080
```

### **Example Problems**

```
# First Law of Thermodynamics
Q=1000, W=300
→ Regime: CLASSICAL
→ System: Thermodynamic
→ Result: ΔU = 700 J

# Ideal Gas Law
P=101325, V=0.0224, T=273
→ Regime: CLASSICAL → STATISTICAL (many particles)
→ Result: n = 1.0 mol

# Point Charge Electric Field
Q=1e-6, x=1, y=0, z=0, x0=0, y0=0, z0=0
→ Regime: CLASSICAL
→ System: Electromagnetic
→ Result: Ex = 8990 N/C, E_magnitude = 8990 N/C

# Carnot Cycle
Th=600, Tc=300, Qh=1000, carnot=1
→ Regime: STATISTICAL
→ Result: efficiency = 50%, W = 500 J
```

---

## 🎓 The Innovation: Regime Detection

### **Automatic Physics Regime Inference**

Unlike traditional solvers that require you to know which equations apply, B-SPEC **automatically detects the physics regime** from your input:

```julia
function infer_regime(values::Dict{Symbol, Property})::PhysicsRegime
    # Extract physical quantities
    v = maximum_velocity(values)
    L = characteristic_length(values)
    N = particle_count(values)
    
    # Speed parameter
    β = v / c  # c = speed of light
    
    # Quantum parameter  
    λ_dB = ℏ / (m * v)  # de Broglie wavelength
    quantum_param = λ_dB / L
    
    # Decision tree
    if quantum_param > 0.1 && β > 0.1
        return QUANTUM_FIELD  # QED, particle physics
    elseif β > 0.1
        return RELATIVISTIC   # Special/general relativity
    elseif quantum_param > 0.1
        return QUANTUM        # Schrödinger equation
    elseif N > 1000
        return STATISTICAL    # Thermodynamics
    else
        return CLASSICAL      # Newton's laws
    end
end
```

**This is groundbreaking** because it mirrors how physics actually works - the same system can be classical at one scale and quantum at another!

---

## 📁 File Structure

```
SEA 1.4/
├── PhysicsTemplate.jl          # Core: Four Pillars framework
│   ├── PhysicsRegime enum      # CLASSICAL, STATISTICAL, QUANTUM, etc.
│   ├── infer_regime()          # Automatic regime detection
│   └── RegimeRules             # Physics constraints per regime
│
├── system_definition.jl        # System types with regime awareness
│   ├── ThermodynamicSystem
│   ├── ElectromagneticSystem  
│   ├── MechanicalSystem
│   └── infer_system()          # Automatic system detection
│
├── solver_interface.jl         # Abstract solver interface
│   ├── can_solve()             # Does this solver apply?
│   ├── is_regime_compatible()  # Is regime correct?
│   └── solve()                 # Execute calculation
│
├── registry.jl                 # Solver registration system
├── dispatcher.jl               # Intelligent solver selection
├── tokenizer.jl                # Input parsing
│
├── thermodynamics_solvers.jl   # 3 thermo solvers
├── cycle_solvers.jl            # 5 cycle solvers
├── electromagnetics_solvers.jl # 3 EM solvers
│
├── server.jl                   # HTTP server with regime info
└── index.html                  # UI with Four Pillars display
```

---

## 🔬 Technical Highlights

### **1. Type-Safe Properties**

```julia
struct Property{T}
    value::T
    unit::String
    regime::PhysicsRegime
end

# Properties know their own physics context!
temp = Property(300.0, "K", CLASSICAL)
```

### **2. Regime-Aware Solvers**

```julia
struct IdealGasSolver <: PhysicsSolver end

function get_compatible_regimes(::IdealGasSolver)
    return [CLASSICAL, STATISTICAL]  # Valid in both regimes
end

function solve(::IdealGasSolver, values)
    # Physics constants
    const R = 8.314  # J/(mol·K)
    
    # Standard PV = nRT calculation
    # ...
end
```

### **3. System Inference**

```julia
function infer_system(values::Dict{Symbol, Property})
    # Check for thermodynamic variables
    if has_any(values, :Q, :W, :ΔU, :P, :V, :T)
        regime = infer_regime(values)
        return ThermodynamicSystem(regime, boundaries, process)
    end
    
    # Check for electromagnetic variables
    if has_any(values, :E, :B, :Q, :F, :charge)
        regime = infer_regime(values)
        return ElectromagneticSystem(regime, charge_dist)
    end
    
    # Mechanical system by default
    return MechanicalSystem(CLASSICAL)
end
```

---

## 🎯 For KUAS Application Reviewers

### **Why This Matters**

**Traditional Approach:**
- User must know which equation applies
- Separate solvers for each domain
- No connection between regimes
- Manual regime selection

**B-SPEC Approach:**
- Automatic regime detection
- Unified framework across all physics
- Regime transitions are natural
- System understands physical context

### **Research Contribution**

This framework demonstrates:

1. **Deep Physics Understanding**  
   - Recognition that mechanics unifies across scales
   - Implementation of regime boundaries
   - Proper handling of quantum/classical transitions

2. **Software Architecture Innovation**  
   - Extensible solver registry
   - Type-safe property system
   - Intelligent dispatch mechanism

3. **Practical Implementation**  
   - Working code, not just theory
   - 11 validated solvers
   - Web-accessible interface

---

## 📈 Roadmap

### **Phase 2: Domain Expansion** (Next)

- **Classical Mechanics**: F=ma, projectile motion, energy conservation
- **Waves/Optics**: Wave equation, Snell's law, interference
- **Quantum Mechanics**: Particle in box, de Broglie, photoelectric effect
- **Statistical Mechanics**: Boltzmann distribution, partition functions

### **Phase 3: Advanced Features**

- Multi-step problem solving
- Regime transition visualization
- Uncertainty quantification
- Graph plotting capabilities

---

## 🔬 Physical Constants

```julia
# Universal constants (PhysicsTemplate.jl)
const ℏ = 1.054571817e-34  # J·s (reduced Planck constant)
const c = 299792458.0      # m/s (speed of light)
const k_B = 1.380649e-23   # J/K (Boltzmann constant)

# Electromagnetic constants
const ε₀ = 8.854187817e-12 # F/m (vacuum permittivity)
const k_e = 8.987551787e9  # N·m²/C² (Coulomb constant)

# Thermodynamic constants  
const R = 8.314462618      # J/(mol·K) (gas constant)
```

---

## 📝 Development Notes

### **Design Principles**

1. **Physical Correctness First**  
   - Regime boundaries are physically meaningful
   - Equations match textbook formulations
   - Units are always explicit

2. **Extensibility**  
   - Adding new solvers is straightforward
   - New regimes can be added easily
   - System types are modular

3. **Type Safety**  
   - Properties carry regime information
   - Compile-time checks where possible
   - Clear error messages

### **Adding a New Solver**

```julia
# 1. Define the solver type
struct MySolver <: PhysicsSolver end

# 2. Specify compatible regimes
function get_compatible_regimes(::MySolver)
    return [CLASSICAL]
end

# 3. Implement can_solve
function can_solve(::MySolver, values::Dict{Symbol, Property})::Bool
    return has_required_variables(values, [:x, :y, :z])
end

# 4. Implement solve
function solve(::MySolver, values::Dict{Symbol, Property})
    # Your physics calculation here
    return PhysicsState(results)
end

# 5. Register it
register_solver(MySolver())
```

---

## 🎓 Educational Value

### **For Students**

- See how physics regimes emerge naturally
- Understand when different laws apply
- Learn proper problem classification
- Visualize regime boundaries

### **For Researchers**

- Framework for multi-scale physics
- Regime transition handling
- Extensible solver architecture
- Type-safe property system

---

## 📊 Project Statistics

- **Development Time**: 3 weeks (concurrent with production SEA)
- **Total Solvers**: 11 (all regime-aware)
- **Lines of Code**: ~2,000
- **Regimes Implemented**: 5 (Classical, Statistical, Quantum, Relativistic, QFT)
- **System Types**: 3 (Thermodynamic, Electromagnetic, Mechanical)

---

## 🙏 Acknowledgments

**Conceptual Foundation:**
- Four Pillars framework inspired by scale/speed analysis of fundamental physics
- Regime detection based on dimensional analysis

**Built With:**
- [Julia Programming Language](https://julialang.org/)
- HTTP.jl for web serving
- JSON.jl for data serialization

**Developed For:**
- Kyoto University of Advanced Science (KUAS) undergraduate Program Application
- Demonstration of research thinking and software engineering skills

---

## 📧 Contact

**Developer:** Denis Muinde  
Email: denismuok@gmail.com
**Application:** KUAS undergraduate Mechnical Engineering Program  
**Repository:** [github.com/Denis-ScientistEngineer/SEA1.4](https://github.com/Denis-ScientistEngineer/SEA1.4)

---

## 📄 License

MIT License - See LICENSE file for details

---

**Status:** Experimental Framework - Active Development  
**Version:** 1.4.0-alpha  
**Last Updated:** March 2026

---

## 🚀 Vision Statement

*"Physics is not a collection of separate theories - it's a unified understanding that manifests differently at different scales. B-SPEC embodies this unity by automatically detecting which regime your problem lives in and applying the appropriate laws. This is how physics should be taught, and this is how physics solvers should work."*

— Denis Muok, Framework Developer
---

**Thank you for reviewing my work. I look forward to the opportunity to discuss this project and my future research interests with you.**