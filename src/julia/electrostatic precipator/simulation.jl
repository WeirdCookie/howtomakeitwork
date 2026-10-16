import TOML

my_datas = Dict(
    "name" => "Electrostatic precipator",
)

output_path = joinpath(@__DIR__, "simulation.toml")
open(output_path, "w") do io
    TOML.print(io, my_datas)
end


#Variables (immutable)


#Geometry of the filter chamber
const R_outer = 0.075   #outer radius aluminium foil in m
const R_inner = 0.001   #wire radius copper in m
const H = 0.25          #height of the chamber in m

# Electrical quantities
const U = 10000.0           # voltage in V
const ε₀ = 8.85e-12         # permittivity of vacuum in F/m
const ε_r = 3.0             # relative permittivity of soot
const e = 1.6e-19           # elementary charge in C

# Flow
const v_gas = 0.5           # gas velocity in m/s
const μ = 1.8e-5            # air viscosity in Pa·s

# Thermal quantities
const k_B = 1.38e-23        # Boltzmann constant in J/K
const T = 293.0             # temperature in K

# Particles
const ρ = 1000.0            # soot density in kg/m³
const r_min = 0.5e-4        # minimum particle radius in m
const r_max = 1.5e-4        # maximum particle radius in m

# Gravity
const g = 9.81              # gravitational acceleration in m/s²

# Pulsing (NE555, artificially reduced to 5 Hz)
const puls_frequenz = 5.0
const puls_periode = 1.0 / puls_frequenz
const puls_dauer = 0.5 * puls_periode

# Simulation
const dt = 0.001            # time step in s
const n_steps = 10000       # number of time steps (10 s)
const n_particles = 1000    # number of particles