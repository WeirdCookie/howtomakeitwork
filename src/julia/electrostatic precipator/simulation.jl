import TOML
using Random

# ============================================================
#  Parameters – everything tunable lives in config.toml.
#  load_config() reads, checks and converts it into one NamedTuple
#  that is passed through the functions below.
#  There are no global constants: the values are ordinary arguments.
# ============================================================

function load_config(path = joinpath(@__DIR__, "config.toml"))
    isfile(path) || error("Config file not found: $path")
    raw = TOML.parsefile(path)

    required = ["geometry", "electrical", "flow", "thermal",
                "particles", "gravitation", "pulsing", "simulation"]
    for section in required
        haskey(raw, section) || error("Missing section [$section] in $path")
    end

    geo = raw["geometry"]; ele = raw["electrical"]; flo = raw["flow"]
    the = raw["thermal"];  par = raw["particles"];  gra = raw["gravitation"]
    pul = raw["pulsing"];  sim = raw["simulation"]

    frequency  = Float64(pul["frequency"])
    duty_cycle = Float64(pul["duty_cycle"])

    p = (
        # geometry of the filter chamber
        R_outer = Float64(geo["r_outer"]),    # outer radius (aluminum foil) [m]
        R_inner = Float64(geo["r_inner"]),    # wire radius (copper) [m]
        H       = Float64(geo["height"]),     # chamber height [m]
        # electrical quantities
        U   = Float64(ele["voltage"]),        # voltage [V]
        ε₀  = Float64(ele["epsilon_0"]),      # permittivity of vacuum [F/m]
        ε_r = Float64(ele["epsilon_r"]),      # relative permittivity of soot
        # gas flow
        v_gas = Float64(flo["gas_velocity"]), # gas velocity [m/s]
        μ     = Float64(flo["viscosity"]),    # air viscosity [Pa·s]
        # thermal quantities
        k_B = Float64(the["boltzmann_constant"]),  # Boltzmann constant [J/K]
        T   = Float64(the["temperature"]),         # temperature [K]
        # particles
        ρ     = Float64(par["density"]),      # soot density [kg/m³]
        r_min = Float64(par["radius_min"]),   # minimum particle radius [m]
        r_max = Float64(par["radius_max"]),   # maximum particle radius [m]
        # gravitation
        g = Float64(gra["gravity"]),          # gravitational acceleration [m/s²]
        # pulsing (NE555)
        pulse_frequency = frequency,
        duty_cycle      = duty_cycle,
        pulse_period    = 1.0 / frequency,
        pulse_duration  = duty_cycle / frequency,
        # simulation control
        dt          = Float64(sim["dt"]),     # time step [s]
        n_steps     = Int(sim["n_steps"]),
        n_particles = Int(sim["n_particles"]),
        seed_base   = Int(sim["seed"]),       # 0 = use particle index as seed
        output_file = String(sim["output"]),
        config_file = basename(path),
    )

    check_params(p)
    return p
end

function check_params(p)
    if p.r_min <= 0 || p.r_max < p.r_min
        error("Invalid particle radii: radius_min = $(p.r_min), radius_max = $(p.r_max)")
    end
    if !(0.0 <= p.duty_cycle <= 1.0)
        error("duty_cycle must be between 0 and 1, got $(p.duty_cycle)")
    end
    if p.R_inner <= 0 || p.R_outer <= p.R_inner
        error("Require 0 < r_inner < r_outer, got r_inner = $(p.R_inner), r_outer = $(p.R_outer)")
    end
    if p.dt <= 0 || p.n_steps < 1 || p.n_particles < 1
        error("Require dt > 0, n_steps ≥ 1, n_particles ≥ 1")
    end
    return nothing
end

function electric_field_strength(r, p)
    return p.U / (r * log(p.R_outer / p.R_inner))
end

function saturation_charge(r, E, p)
    return 4π * p.ε₀ * (1 + 2*(p.ε_r - 1)/(p.ε_r + 2)) * E * r^2
end

function simulate_particle(seed, p)
    Random.seed!(seed)

    r_particle = p.r_min + rand() * (p.r_max - p.r_min)
    m = p.ρ * (4/3) * π * r_particle^3

    x = 0.0; z = 0.0
    for _ in 1:100
        x = (rand() - 0.5) * 2 * (p.R_outer - r_particle)
        z = (rand() - 0.5) * 2 * (p.R_outer - r_particle)
        if sqrt(x^2 + z^2) <= p.R_outer - r_particle
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

    for i in 1:p.n_steps
        t = i * p.dt

        r = sqrt(x^2 + z^2)
        if r < 1e-9
            r = 1e-9
        end

        F_flow_x = 6π * p.μ * r_particle * (0 - vx)
        F_flow_y = 6π * p.μ * r_particle * (p.v_gas - vy)
        F_flow_z = 6π * p.μ * r_particle * (0 - vz)

        pulse_active = (t % p.pulse_period) < p.pulse_duration
        if pulse_active
            E = electric_field_strength(r, p)
            q = saturation_charge(r_particle, E, p)
            F_coulomb_x = q * E * (x / r)
            F_coulomb_z = q * E * (z / r)
        else
            F_coulomb_x = 0.0
            F_coulomb_z = 0.0
        end

        σ_brown = sqrt(2 * p.k_B * p.T * 6π * p.μ * r_particle / p.dt)
        F_brown_x = σ_brown * randn()
        F_brown_y = σ_brown * randn()
        F_brown_z = σ_brown * randn()

        F_grav_y = -m * p.g

        F_x = F_flow_x + F_coulomb_x + F_brown_x
        F_y = F_flow_y + F_brown_y + F_grav_y
        F_z = F_flow_z + F_coulomb_z + F_brown_z

        vx = vx + (F_x / m) * p.dt
        vy = vy + (F_y / m) * p.dt
        vz = vz + (F_z / m) * p.dt

        x = x + vx * p.dt
        y = y + vy * p.dt
        z = z + vz * p.dt

        r_new = sqrt(x^2 + z^2)

        if r_new >= p.R_outer - r_particle
            x = (p.R_outer - r_particle) * x / r_new
            z = (p.R_outer - r_particle) * z / r_new
            vx = 0.0; vy = 0.0; vz = 0.0
            absorbed_at = i
            push!(positions, [x, y, z])
            break
        end

        if y > p.H
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
    p = load_config()

    all_particles = []
    n_absorbed = 0

    for i in 1:p.n_particles
        seed = p.seed_base == 0 ? i : p.seed_base + i - 1
        r, absorbed, pos = simulate_particle(seed, p)
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
            println("  $i / $(p.n_particles) particles simulated")
        end
    end

    efficiency = n_absorbed / p.n_particles * 100
    println()
    println("============================================")
    println("  Collection efficiency: $(round(efficiency, digits=1)) %")
    println("  Collected: $n_absorbed / $(p.n_particles)")
    println("============================================")


    data = Dict(
        "meta" => Dict(
            "config_file" => p.config_file,
            "chamber_radius" => p.R_outer,
            "chamber_height" => p.H,
            "voltage" => p.U,
            "gas_velocity" => p.v_gas,
            "particle_radius_min" => p.r_min,
            "particle_radius_max" => p.r_max,
            "pulse_frequency" => p.pulse_frequency,
            "duty_cycle" => p.duty_cycle,
            "dt" => p.dt,
            "n_steps" => p.n_steps,
            "n_particles" => p.n_particles,
            "efficiency" => efficiency
        ),
        "particles" => all_particles
    )

    open(p.output_file, "w") do io
        TOML.print(io, data)
    end
    println()
    println("File '$(p.output_file)' has been written.")
end

main()