import TOML

my_datas = Dict(
    "name" => "Electrostatic precipator",
)

output_path = joinpath(@__DIR__, "simulation.toml")
open(output_path, "w") do io
    TOML.print(io, my_datas)
end


#Variablen (immutable)


#Geometrie der Filterkammer
const R_outer = 0.075   #Außenradius Alufolie in m
const R_inner = 0.001   #Drahtradius Kupfer  in m
const H = 0.25          #Höhe der Kammer in m

# Elektrische Größen
const U = 10000.0           # Spannung in V
const ε₀ = 8.85e-12         # Permittivität Vakuum in F/m
const ε_r = 3.0             # relative Permittivität Ruß
const e = 1.6e-19           # Elementarladung in C

