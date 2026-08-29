#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdio>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <cstring>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

std::string getEnv(const char* name, const char* def = "") {
    const char* val = std::getenv(name);
    return val ? val : def;
}

void handleRequest(int client_fd, const std::string& tool) {
    char buffer[4096];
    read(client_fd, buffer, sizeof(buffer));
    
    std::string req(buffer);
    std::string response;
    
    if (req.find("GET /health") != std::string::npos) {
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n" + 
            json{{"status", "ok"}, {"tool", tool}, {"language", "cpp"}}.dump();
    } else if (req.find("GET / ") != std::string::npos) {
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n" + 
            json{{"message", "C++ Tool läuft!"}, {"tool", tool}}.dump();
    } else if (req.find("POST /api/echo") != std::string::npos) {
        size_t bodyStart = req.find("\r\n\r\n");
        std::string body = bodyStart != std::string::npos ? req.substr(bodyStart + 4) : "{}";
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n" + 
            json{{"input", json::parse(body)}, {"language", "cpp"}}.dump();
    } else {
        response = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n" + 
            json{{"error", "not found"}}.dump();
    }
    
    write(client_fd, response.c_str(), response.size());
}

int main() {
    std::string tool = getEnv("TOOL_NAME", "cpp-tool");
    int port = std::stoi(getEnv("PORT", "8084"));
    
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    
    bind(server_fd, (sockaddr*)&addr, sizeof(addr));
    listen(server_fd, 10);
    
    std::cout << "C++ tool starting on port " << port << std::endl;
    
    while (true) {
        int client_fd = accept(server_fd, nullptr, nullptr);
        handleRequest(client_fd, tool);
        close(client_fd);
    }
}