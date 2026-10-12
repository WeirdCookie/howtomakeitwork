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
const R_outer = 0.075 #Außenradius Alufolie in m
const R_inner = 0.001 #Drahtradius Kupfer  in m
const H = 0.25 #Höhe der Kammer in m

#