import TOML
using Random

# PHYSICAL CONSTANTS (SI units)

# Geometry of the filter chamber
const R_outer = 0.05        # outer radius (aluminum foil) in m
const R_inner = 0.001       # wire radius (copper) in m
const H = 0.20              # chamber height in m

# Electrical quantities
const U = 10000.0           # voltage in V
const ε₀ = 8.85e-12         # permittivity of vacuum in F/m
const ε_r = 3.0             # relative permittivity of soot

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

# Gravitation
const g = 9.81              # gravitational acceleration in m/s²

# Pulsing (NE555, artificially reduced to 5 Hz)
const pulse_frequency = 5.0
const pulse_period = 1.0 / pulse_frequency
const pulse_duration = 0.5 * pulse_period

# Simulation
const dt = 0.001            # time step in s
const n_steps = 10000       # number of time steps (10 s)
const n_particles = 1000    # number of particles

function electric_field_strength(r)
    return U / (r * log(R_outer / R_inner))
end

function saturation_charge(r, E)
    return 4π * ε₀ * (1 + 2*(ε_r - 1)/(ε_r + 2)) * E * r^2
# ============================================================
end

function simulate_particle(seed)
    Random.seed!(seed)

    r_particle = r_min + rand() * (r_max - r_min)
    m = ρ * (4/3) * π * r_particle^3

    x = 0.0; z = 0.0
    for _ in 1:100
        x = (rand() - 0.5) * 2 * (R_outer - r_particle)
        z = (rand() - 0.5) * 2 * (R_outer - r_particle)
        if sqrt(x^2 + z^2) <= R_outer - r_particle
            break
        end
    end
    y = 0.0

    vx = 0.01 * randn()
    vy = 0.01 * randn()
    vz = 0.01 * randn()

    positions = Vector{Vector{Float64}}()
    push!(positions, [x, y, z])

    absorbed_at = -1

    for i in 1:n_steps
        t = i * dt

        r = sqrt(x^2 + z^2)
        if r < 1e-9
            r = 1e-9
        end

        F_flow_x = 6π * μ * r_particle * (0 - vx)
        F_flow_y = 6π * μ * r_particle * (v_gas - vy)
        F_flow_z = 6π * μ * r_particle * (0 - vz)

        pulse_active = (t % pulse_period) < pulse_duration
        if pulse_active
            E = electric_field_strength(r)
            q = saturation_charge(r_particle, E)
            F_coulomb_x = q * E * (x / r)
            F_coulomb_z = q * E * (z / r)
        else
            F_coulomb_x = 0.0
            F_coulomb_z = 0.0
        end

        σ_brown = sqrt(2 * k_B * T * 6π * μ * r_particle / dt)
        F_brown_x = σ_brown * randn()
        F_brown_y = σ_brown * randn()
        F_brown_z = σ_brown * randn()

        F_grav_y = -m * g

        F_x = F_flow_x + F_coulomb_x + F_brown_x
        F_y = F_flow_y + F_brown_y + F_grav_y
        F_z = F_flow_z + F_coulomb_z + F_brown_z

        vx = vx + (F_x / m) * dt
        vy = vy + (F_y / m) * dt
        vz = vz + (F_z / m) * dt

        x = x + vx * dt
        y = y + vy * dt
        z = z + vz * dt

        r_new = sqrt(x^2 + z^2)

        if r_new >= R_outer - r_particle
            x = (R_outer - r_particle) * x / r_new
            z = (R_outer - r_particle) * z / r_new
            vx = 0.0; vy = 0.0; vz = 0.0
            absorbed_at = i
            push!(positions, [x, y, z])
            break
        end

        if y > H
            push!(positions, [x, y, z])
            break
        end

        if i % 50 == 0
            push!(positions, [x, y, z])
        end
    end

    return r_particle, absorbed_at, positions
end



function main()
    all_particles = []
    n_absorbed = 0

    for i in 1:n_particles
        r, absorbed, pos = simulate_particle(i)
        push!(all_particles, Dict(
            "id" => i - 1,
            "radius" => r,
            "absorbed_at" => absorbed,
            "positions" => pos
        ))
        if absorbed > 0
            n_absorbed += 1
        end
        if i % 200 == 0
            println("  $i / $n_particles particles simulated")
        end
    end

    efficiency = n_absorbed / n_particles * 100
    println()
    println("============================================")
    println("  Collection efficiency: $(round(efficiency, digits=1)) %")
    println("  Collected: $n_absorbed / $n_particles")
    println("============================================")


    data = Dict(
        "meta" => Dict(
            "chamber_radius" => R_outer,
            "chamber_height" => H,
            "dt" => dt,
            "n_steps" => n_steps,
            "n_particles" => n_particles,
            "efficiency" => efficiency
        ),
        "particles" => all_particles
    )

    open("simulation.toml", "w") do io
        TOML.print(io, data)
    end
    println()
    println("File 'simulation.toml' has been written.")
end

main()