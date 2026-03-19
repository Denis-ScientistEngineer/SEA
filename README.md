# ⚛️ Physics Problem Solver: A Context-Aware Computational Framework

[![Live Demo](https://img.shields.io/badge/demo-live-success)](https://denis-sea.up.railway.app)
[![Julia](https://img.shields.io/badge/julia-v1.9+-purple.svg)](https://julialang.org/)
[![Status](https://img.shields.io/badge/status-active_development-blue.svg)]()

> A novel computational framework for solving multi-domain physics problems using context-aware regime detection and boundary-based solver selection.

**Live Application:** [https://denis-sea.up.railway.app](https://denis-sea.up.railway.app)
If doesn't work --- Another approach deployed on render:
   ** Live server: ** https://sea-1-4.onrender.com

---

## 📌 About This Repository

**Repository Status:** Private (Shared for Academic Review)

This repository contains my independent research project in computational physics, developed as part of my undergraduate work and included in my application to Kyoto Institute of Advanced Science (KUAS). Access is granted to:

- KUAS admissions committee
- Academic reviewers
- Potential research supervisors
- Professional references

**Contact:** denismuok@gmail.com 
**Application Context:** Undergraduate Program Application - KUAS  
**Development Period:** February - March 2026

---

## 🎯 Project Vision

Traditional physics problem solvers treat each equation as an isolated calculation. This project introduces a fundamentally different approach: **treating physical systems as entities defined by their boundaries, regimes, and processes** rather than merely as collections of variables.

This paradigm shift enables:
- **Automatic regime detection** (Classical, Quantum, Statistical, Relativistic)
- **Context-aware solver selection** based on physical validity
- **Multi-domain problem solving** across thermodynamics, electromagnetics, mechanics, and optics
- **Process-aware calculations** that understand HOW systems change, not just their states

---

## 🔬 Technical Innovation

### The Boundary-Based Approach

Unlike conventional solvers that match variables to equations, this system:

1. **Analyzes the physical context** of the problem
2. **Determines applicable physics** based on scale, energy, and boundary conditions
3. **Selects appropriate solvers** that respect physical constraints
4. **Prevents invalid calculations** (e.g., applying classical thermodynamics at quantum scales)

### Architecture Highlights
```
Input Variables → Context Inference → Regime Detection → Solver Selection → Solution
                     ↓                      ↓                    ↓
                 System Type          Scale Analysis      Priority Ranking
                 Boundary Type        Energy Regime       Validation
                 Substance Type       Physical Limits     Error Handling
```

### Key Technical Features

- **Plugin Architecture**: Modular solver system allowing domain-specific extensions
- **Priority-Based Dispatch**: Intelligent solver ranking based on specificity and context
- **Regime Detection**: Automatic classification using Knudsen numbers, de Broglie wavelengths, and relativistic parameters
- **Process Modeling**: State tracking through thermodynamic processes and cycles
- **Comprehensive Validation**: Multi-level input validation with physical constraint checking

---

## 🏗️ System Architecture

### Core Components
```
┌─────────────────────────────────────────────────────────┐
│                    Web Interface (HTML/JS)               │
│                    User Input & Visualization            │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              HTTP Server (Julia/HTTP.jl)                │
│              Request Handling & API                      │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                 System Context Layer                     │
│         Regime Detection | Boundary Analysis            │
│         Scale Classification | Substance Inference      │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              Solver Registry & Dispatcher                │
│         Priority Ranking | Context Matching             │
│         Validation | Solver Selection                   │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                   Physics Solvers                        │
│  ┌──────────┬──────────┬──────────┬─────────────────┐  │
│  │  Thermo  │   E&M    │ Mechanics│  Waves/Optics   │  │
│  │  12 Solv │  9 Solv  │  (Planned)│   (Planned)    │  │
│  └──────────┴──────────┴──────────┴─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Physics Domains Implemented

#### 1. **Thermodynamics** (12 Solvers)
   - **Basic Laws**: First Law, Ideal Gas, Heat Capacity
   - **Processes**: Isothermal, Adiabatic, Isobaric, Isochoric, Polytropic
   - **Cycles**: Carnot, Otto, Diesel, Rankine

#### 2. **Electromagnetics** (9 Solvers)
   - Point Charge Electric Field
   - Coulomb Force
   - Infinite Line Charge
   - Infinite Plane
   - Charged Ring (axial field)
   - Charged Disk (axial field)
   - Finite Line Charge (numerical integration)
   - Parallel Plate Capacitor
   - Electric Potential

#### 3. **Mechanics** (In Development)
   - Kinematics, Dynamics, Energy Conservation

#### 4. **Waves & Optics** (Planned)
   - Wave phenomena, Doppler effect, Snell's law

---

## 📐 Scientific Foundation

### Physical Regime Classification

The system uses scientifically rigorous criteria to classify problems:

| Regime | Criteria | Physics |
|--------|----------|---------|
| **Classical Macroscopic** | L > 1μm, v << c, kT >> ℏω | Newton's Laws, Classical Thermo |
| **Statistical Mesoscopic** | 0.01 < Kn < 10 | Kinetic Theory, Stat Mech |
| **Quantum Microscopic** | λ_dB ~ L, ℏ significant | Quantum Mechanics |
| **Relativistic** | v ≈ c, β > 0.1 | Special Relativity |

**Knudsen Number**: `Kn = λ/L` (mean free path / characteristic length)  
**de Broglie Wavelength**: `λ_dB = h/(mv)`  
**Relativistic Parameter**: `β = v/c`

### Boundary Types

Following classical thermodynamic system theory:

- **Isolated**: No mass, no energy transfer (dE=0, dM=0)
- **Closed**: Energy transfer, no mass (dE≠0, dM=0)
- **Open**: Both mass and energy transfer (dE≠0, dM≠0)

Boundary properties:
- **Rigid**: Fixed volume (dV=0)
- **Flexible**: Movable boundary (dV≠0)
- **Permeable**: Mass can pass (dN≠0)
- **Conducting/Insulating**: Heat transfer properties

---

## 💻 Running the Application

### Prerequisites

- Julia 1.9 or higher
- Git (for cloning)

### Local Installation
```bash
# Clone this repository
git clone [repository-url]
cd physics-solver

# Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run the server
julia server.jl
```

The application will start on `http://localhost:8080`

### Live Deployment

The application is currently deployed and accessible at:  
**https://denis-sea.up.railway.app**

Cloud deployment uses Railway.app with automatic deployment from this repository.

---

## 🎮 Usage Examples

### Example 1: Basic Thermodynamics
```
Input: Q=100, W=40
Output: ΔU = 60 J
Solver: First Law of Thermodynamics (ΔU = Q - W)
Regime: Classical Macroscopic
```

### Example 2: Ideal Gas Law
```
Input: P=101325, V=0.5, T=300
Output: n = 20.3 mol
Solver: Ideal Gas Law (PV = nRT)
Context: IDEAL_GAS substance detected
```

### Example 3: Electromagnetics with Scientific Notation
```
Input: Q=1e-6, x=1, y=0, z=0, x0=0, y0=0, z0=0
Output: E_magnitude = 8.99e+03 N/C
Solver: Point Charge Electric Field
Regime: Classical Macroscopic
Substance: POINT_CHARGES detected
```

### Example 4: Thermodynamic Process
```
Input: P1=200000, V1=1.0, V2=0.5, isothermal=1
Output: P2 = 400000 Pa, W = -138629 J
Solver: Isothermal Process (PV = constant)
Process Type: Isothermal detected
```

### Example 5: Heat Engine Cycle
```
Input: Th=600, Tc=300, Qh=1000, carnot=1
Output: efficiency = 50%, W = 500 J, Qc = 500 J
Solver: Carnot Cycle (η = 1 - Tc/Th)
Analysis: Maximum theoretical efficiency calculated
```

---

## 🔬 Research Contributions & Novelty

### Novel Approaches

1. **Context-Aware Computing in Physics**
   - First implementation of regime-aware solver selection in a general-purpose physics calculator
   - Prevents physically invalid calculations through boundary analysis
   - Automatic scale detection from input values

2. **Unified Multi-Domain Framework**
   - Single architecture handles multiple physics domains without domain-specific hacks
   - Process-aware calculations that model system evolution, not just states
   - Extensible plugin system for new domains

3. **Educational Innovation**
   - Step-by-step solution generation showing methodology
   - Clear explanation of applicable physics and constraints
   - Visual feedback on regime and boundary conditions
   - Error messages with constructive suggestions

### Potential Applications

- **Engineering Education**: Teaching tool that explains *why* certain equations apply
- **Rapid Prototyping**: Quick validation of engineering calculations with automatic physics checking
- **Research Tools**: Framework for multi-physics simulations with automatic regime transitions
- **AI Training Data**: Generate physically valid problem-solution pairs for ML models

### Academic Significance

This project demonstrates:
- **Independent Research Capability**: Identified problem, designed solution, implemented system
- **Interdisciplinary Thinking**: Bridges computational science, physics, and software engineering
- **Practical Implementation**: Not just theory—deployed, tested, functional system
- **Scalable Architecture**: Design allows for continuous expansion and improvement

---

## 📊 Development Progress

### Completed (Weeks 1-3) ✅

**Week 1: Foundation**
- [x] Plugin architecture design
- [x] Abstract solver interface
- [x] Basic thermodynamics solvers (3)
- [x] Basic electromagnetics solvers (9)
- [x] Cloud deployment pipeline

**Week 2: Intelligence**
- [x] Context inference system
- [x] Regime detection algorithms
- [x] Priority-based dispatcher
- [x] Comprehensive validation
- [x] Error handling with suggestions
- [x] Step-by-step solution formatting
- [x] Scientific notation support

**Week 3: Sophistication**
- [x] Thermodynamic process solvers (5)
- [x] Thermodynamic cycle analyzers (4)
- [x] Process-aware calculations
- [x] Enhanced UI with two-column layout

### In Development 🚧
- [ ] Mechanics domain (kinematics, dynamics, energy)
- [ ] Waves and optics solvers
- [ ] Multi-step problem decomposition
- [ ] P-V diagram visualization

### Future Roadmap 🔮
- [ ] State tracking through multi-process sequences
- [ ] Real-time collaboration features
- [ ] LaTeX equation rendering
- [ ] Advanced visualization (3D field plots)
- [ ] Integration with symbolic math engines

---

## 🏛️ Technical Stack

- **Backend**: Julia 1.9+ (High-performance numerical computing)
- **Web Server**: HTTP.jl (Native Julia HTTP server)
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Deployment**: Railway.app (Cloud platform)
- **Version Control**: Git/GitHub

### Why Julia?

Julia was chosen for its:
- **Performance**: Near-C speed for numerical computations
- **Multiple Dispatch**: Natural fit for physics solver architecture
- **Scientific Computing Ecosystem**: Built-in support for complex mathematics
- **Type System**: Strong typing enables compile-time optimizations
- **Readability**: Clean syntax suitable for academic review

---

## 📚 Code Structure & Documentation

### File Structure
```
physics-solver/
├── server.jl                  # HTTP server and API endpoints
├── system_context.jl          # Regime detection and context inference
├── abstract_solver.jl         # Base solver interface and contracts
├── registry.jl                # Solver registration system
├── dispatcher.jl              # Context-aware solver selection
├── tokenizer.jl               # Input parsing (scientific notation)
├── solution_formatter.jl      # Step-by-step solution generation
├── thermodynamics.jl          # Thermodynamics solvers
├── processes.jl               # Thermodynamic process solvers
├── cycles.jl                  # Thermodynamic cycle analyzers
├── electromagnetics.jl        # Electromagnetics solvers
├── index.html                 # Web interface
├── test_system.jl             # Comprehensive test suite
├── Project.toml               # Julia dependencies
├── nixpacks.toml              # Deployment configuration
└── README.md                  # This file
```

### Core Abstractions

#### PhysicsSolver Interface
```julia
abstract type PhysicsSolver end

# Required methods
can_solve(solver, variables, context)::Bool
solve(solver, values)::Dict{Symbol, Float64}
get_domain(solver)::Symbol

# Optional methods (with defaults)
get_priority(solver)::Int
validate_inputs(solver, values)::Bool
get_required_regime(solver)::ScaleRegime
get_equation(solver)::String
get_output_units(solver)::Dict{Symbol, String}
```

---

## 🧪 Testing & Validation

Comprehensive test suite covering:
- **Tokenizer**: Scientific notation parsing accuracy
- **Context Inference**: Regime detection correctness
- **Solver Selection**: Priority and validation logic
- **Physics Calculations**: Numerical accuracy validation
- **Boundary Violations**: Detection of invalid physics applications

Run complete test suite:
```bash
julia test_system.jl
```

Expected output: All tests pass with regime detection and calculation validation confirmed.

---

## 📈 Project Metrics

- **Total Lines of Code**: ~3,200
- **Physics Solvers**: 21 implemented, 10+ planned
- **Test Coverage**: Comprehensive unit and integration tests
- **Response Time**: Sub-second for all calculations
- **Deployment Status**: Live production environment
- **Development Time**: 3 weeks intensive development
- **Languages**: Julia (backend), JavaScript (frontend)

---

## 🎓 Academic Context

### Development Background

This project was developed independently during my undergraduate studies as a demonstration of:
- **Research Capability**: Identifying gaps in existing tools and proposing novel solutions
- **Technical Execution**: Full-stack development from concept to production deployment
- **Scientific Rigor**: Proper implementation of physical principles with appropriate validation
- **Interdisciplinary Thinking**: Combining physics, computer science, and engineering

### Learning Outcomes

Through this project, I gained deep understanding of:
- Advanced software architecture patterns
- Computational physics methods
- Multi-domain physics integration
- Cloud deployment and DevOps
- User interface design for technical applications

### Application to Graduate Studies

This project demonstrates readiness for graduate-level work by showing:
- Independent research and problem-solving
- Ability to work at intersection of theory and practice
- Technical skills in computational methods
- Commitment to creating practical, usable tools
- Foundation for future research in computational engineering

---

## 📖 References & Theoretical Foundation

### Core Physics Texts
1. Cengel, Y. A., & Boles, M. A. (2015). *Thermodynamics: An Engineering Approach*. McGraw-Hill.
2. Griffiths, D. J. (2017). *Introduction to Electrodynamics*. Cambridge University Press.
3. Pathria, R. K., & Beale, P. D. (2011). *Statistical Mechanics*. Academic Press.

### Computational Methods
4. Press, W. H., et al. (2007). *Numerical Recipes: The Art of Scientific Computing*. Cambridge University Press.
5. Bezanson, J., et al. (2017). "Julia: A Fresh Approach to Numerical Computing." *SIAM Review*, 59(1), 65-98.

### System Design
6. Gamma, E., et al. (1994). *Design Patterns: Elements of Reusable Object-Oriented Software*. Addison-Wesley.

---

## 👨‍💻 About the Developer

**Denis Muinde**  
Undergraduate Student  
Applying to: Kyoto Institute of Advanced Science (KUAS)

### Contact Information
- **Email**: [Your Email]
- **GitHub**: [This Private Repository]
- **Live Demo**: https://denis-sea.up.railway.app

### Project Context
This repository is shared as part of my graduate program application to demonstrate:
- Technical capability in computational physics
- Software engineering and architecture skills
- Independent research and problem-solving ability
- Readiness for graduate-level research

### Skills Demonstrated
- **Physics**: Multi-domain understanding (thermodynamics, E&M, mechanics)
- **Programming**: Julia, JavaScript, system architecture
- **Mathematics**: Numerical methods, computational algorithms
- **Engineering**: Full-stack development, deployment, testing
- **Research**: Problem identification, solution design, implementation

---

## 💬 Questions or Feedback?

For questions about this project, technical details, or my application:

**Email**: [Your Email]  
**Response Time**: Typically within 24 hours

I'm happy to:
- Explain technical decisions and architecture choices
- Discuss future development plans
- Provide additional documentation or demonstrations
- Answer questions about my background and qualifications

---

## 🔒 Repository Access

**Access Level**: Private  
**Intended Audience**: Academic reviewers, admissions committee  
**Sharing Policy**: Please do not redistribute without permission

If you received access to this repository, it's because you're reviewing my application or serving as a reference. Thank you for taking the time to explore my work!

---

## 📅 Version History

- **v3.0** (March 2026): Week 3 completion - Cycles and processes
- **v2.0** (March 2026): Week 2 completion - Context awareness and validation
- **v1.0** (February 2026): Week 1 completion - Core architecture and basic solvers

---

*"The boundary between what is known and what is discoverable is not a line, but a landscape rich with possibility. This project is my first exploration of that terrain."*

---

**Last Updated**: March 2026  
**Status**: Active Development  
**Purpose**: Academic Portfolio & Graduate Application Supporting Material

---

## 🙏 Acknowledgments

- Julia Computing community for the excellent language and ecosystem
- Physics education community for inspiration and pedagogical insights
- Open source contributors whose libraries enabled this work
- Mentors and advisors who provided guidance throughout development

---

**Thank you for reviewing my work. I look forward to the opportunity to discuss this project and my future research interests with you.**