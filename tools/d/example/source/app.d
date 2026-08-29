import vibe.d;
import std.json;
import std.getopt;
import std.process;

void main(string[] args) {
    string tool = environment.get("TOOL_NAME", "d-tool");
    ushort port = environment.get("PORT", "8088").to!ushort;

    auto router = new URLRouter;
    router.get("/health", (req, res) {
        res.writeJsonBody(["status": "ok", "tool": tool, "language": "d"]);
    });
    router.get("/", (req, res) {
        res.writeJsonBody(["message": "D Tool läuft!", "tool": tool]);
    });
    router.post("/api/echo", (req, res) {
        auto data = parseJSON(req.bodyReader.readAllUTF8());
        res.writeJsonBody(["input": data, "language": "d"]);
    });

    auto settings = new HTTPServerSettings;
    settings.port = port;
    settings.bindAddresses = ["0.0.0.0"];

    logInfo("D tool starting on port %d", port);
    listenHTTP(settings, router);
    runApplication();
}