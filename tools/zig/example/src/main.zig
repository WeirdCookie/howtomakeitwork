const std = @import("std");
const net = std.net;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const tool = std.process.getEnvVar("TOOL_NAME") catch "zig-tool";
    const port = std.process.getEnvVar("PORT") catch "8089";
    const port_num = try std.fmt.parseInt(u16, port, 10);

    var server = try net.Server.listen(.{ .address = .any, .port = port_num }, allocator);
    defer server.deinit();

    std.log.info("Zig tool starting on port {d}", .{port_num});

    while (true) {
        const conn = try server.accept();
        spawn(handleConnection(conn, tool));
    }
}

fn handleConnection(conn: net.TcpConnection, tool: []const u8) void {
    var buf: [4096]u8 = undefined;
    const n = conn.read(&buf) catch { conn.close(); return; };
    const req = buf[0..n];

    const response = if (std.mem.startsWith(req, "GET /health")) {
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"ok\",\"tool\":\"" ++ tool ++ "\",\"language\":\"zig\"}"
    } else if (std.mem.startsWith(req, "GET / ")) {
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"message\":\"Zig Tool l\\u00e4uft!\",\"tool\":\"" ++ tool ++ "\"}"
    } else if (std.mem.startsWith(req, "POST /api/echo")) {
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"input\":{},\"language\":\"zig\"}"
    } else {
        "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"error\":\"not found\"}"
    };

    _ = conn.write(response) catch {};
    conn.close();
}