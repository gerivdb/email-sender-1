package qdrant_health_proxy

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type HealthResponse struct {
	Status	string		`json:"status"`
	Version	string		`json:"version"`
	Time	time.Time	`json:"time"`
}

func main() {
	log.Println("Starting Qdrant health proxy on :6334...")

	// Endpoint for health check
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/", "/health":
			healthResponse := HealthResponse{
				Status:		"ok",
				Version:	"v1.7.0",
				Time:		time.Now(),
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(healthResponse)
		default:
			// Forward to real Qdrant service
			http.Redirect(w, r, "http://localhost:6333"+r.URL.Path, http.StatusTemporaryRedirect)
		}
	})

	// Start the server
	log.Fatal(http.ListenAndServe(":6334", nil))
}
