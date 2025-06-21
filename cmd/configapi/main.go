package main

import (
	"encoding/json"
	"net/http"
	"d\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\core\config"
)

func configAPIHandler(w http.ResponseWriter, r *http.Request) {
	cfg, _ := config.LoadConfigYAML("config.yaml")
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(cfg)
}

func main() {
	http.HandleFunc("/api/config", configAPIHandler)
	http.ListenAndServe(":8080", nil)
}
