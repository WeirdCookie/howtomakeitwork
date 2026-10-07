import TOML

my_datas = Dict(
    "name" => "Electrostatic precipator",
)

output_path = joinpath(@__DIR__, "simulation.toml")
open(output_path, "w") do io
    TOML.print(io, my_datas)
end

