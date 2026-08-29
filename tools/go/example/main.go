package main

import (
	"encoding/json"
	"net/http"
	"os"
)

type Health struct {
	Status   string `json:"status"`
	Tool     string `json:"tool"`
	Language string `json:"language"`
}

func main() {
	tool := os.Getenv("TOOL_NAME")
	if tool == "" { tool = "go-tool" }
	port := os.Getenv("PORT")
	if port == "" { port = "8083" }

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Health{"ok", tool, "go"})
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"message": "Go Tool läuft!", "tool": tool})
	})
	http.HandleFunc("/api/echo", func(w http.ResponseWriter, r *http.Request) {
		var data map[string]interface{}
		json.NewDecoder(r.Body).Decode(&data)
		json.NewEncoder(w).Encode(map[string]interface{}{"input": data, "language": "go"})
	})

	println("Go tool starting on port", port)
	http.ListenAndServe(":"+port, nil)
}