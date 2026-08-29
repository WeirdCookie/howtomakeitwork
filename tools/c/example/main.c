#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <cjson/cJSON.h>

#define PORT_ENV "PORT"
#define TOOL_ENV "TOOL_NAME"
#define DEFAULT_PORT 8090
#define BUF_SIZE 4096

char* get_env(const char* name, const char* def) {
    char* val = getenv(name);
    return val ? val : (char*)def;
}

void send_response(int client_fd, int status, const char* content_type, const char* body) {
    char header[512];
    int len = snprintf(header, sizeof(header),
        "HTTP/1.1 %d OK\r\nContent-Type: %s\r\nContent-Length: %zu\r\n\r\n",
        status, content_type, strlen(body));
    write(client_fd, header, len);
    write(client_fd, body, strlen(body));
}

int main() {
    char* tool = get_env(TOOL_ENV, "c-tool");
    int port = atoi(get_env(PORT_ENV, "8090"));

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    bind(server_fd, (struct sockaddr*)&addr, sizeof(addr));
    listen(server_fd, 10);

    printf("C tool starting on port %d\n", port);

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        char buf[BUF_SIZE] = {0};
        read(client_fd, buf, BUF_SIZE);

        if (strstr(buf, "GET /health")) {
            cJSON* json = cJSON_CreateObject();
            cJSON_AddStringToObject(json, "status", "ok");
            cJSON_AddStringToObject(json, "tool", tool);
            cJSON_AddStringToObject(json, "language", "c");
            char* body = cJSON_PrintUnformatted(json);
            send_response(client_fd, 200, "application/json", body);
            free(body);
            cJSON_Delete(json);
        } else if (strstr(buf, "GET / ")) {
            cJSON* json = cJSON_CreateObject();
            cJSON_AddStringToObject(json, "message", "C Tool l\u00e4uft!");
            cJSON_AddStringToObject(json, "tool", tool);
            char* body = cJSON_PrintUnformatted(json);
            send_response(client_fd, 200, "application/json", body);
            free(body);
            cJSON_Delete(json);
        } else if (strstr(buf, "POST /api/echo")) {
            send_response(client_fd, 200, "application/json", "{\"input\":{},\"language\":\"c\"}");
        } else {
            send_response(client_fd, 404, "application/json", "{\"error\":\"not found\"}");
        }
        close(client_fd);
    }
}