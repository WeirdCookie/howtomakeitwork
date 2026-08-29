using HTTP, JSON, Sockets

const TOOL = get(ENV, "TOOL_NAME", "julia-tool")
const PORT = parse(Int, get(ENV, "PORT", "8086"))

function health(req::HTTP.Request)
    HTTP.Response(200, ["Content-Type" => "application/json"], 
        JSON.json(Dict("status" => "ok", "tool" => TOOL, "language" => "julia")))
end

function index(req::HTTP.Request)
    HTTP.Response(200, ["Content-Type" => "application/json"], 
        JSON.json(Dict("message" => "Julia Tool läuft!", "tool" => TOOL)))
end

function echo(req::HTTP.Request)
    data = JSON.parse(String(req.body))
    HTTP.Response(200, ["Content-Type" => "application/json"], 
        JSON.json(Dict("input" => data, "language" => "julia")))
end

router = HTTP.Router()
router["GET", "/health"] = health
router["GET", "/"] = index
router["POST", "/api/echo"] = echo

println("Julia tool starting on port $PORT")
HTTP.serve(router, Sockets.localhost, PORT)