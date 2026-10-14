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

