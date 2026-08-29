import httpServer, json, os

proc health(req: Request): string = 
  %*{"status": "ok", "tool": getEnv("TOOL_NAME", "nim-tool"), "language": "nim"}

proc index(req: Request): string = 
  %*{"message": "Nim Tool läuft!", "tool": getEnv("TOOL_NAME", "nim-tool")}

proc echo(req: Request): string = 
  let data = parseJson(req.body)
  %*{"input": data, "language": "nim"}

let server = newHttpServer()
server.route("/health", health)
server.route("/", index)
server.route("/api/echo", echo)

let port = getEnv("PORT", "8082").parseInt()
echo "Nim tool starting on port ", port
server.serve(port=Port(port))