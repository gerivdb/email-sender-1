// API REST CacheManager v74 — Serveur Go natif

package api

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	cachemanager "github.com/gerivdb/email-sender-1/development/managers/cache-manager"
)

var (
	cm     *cachemanager.CacheManager
	cmOnce sync.Once
)

func getCacheManager() *cachemanager.CacheManager {
	cmOnce.Do(func() {
		cm = cachemanager.NewCacheManager(
			cachemanager.NewLMCacheAdapter(),
			cachemanager.NewRedisAdapter(),
			cachemanager.NewSQLiteAdapter(),
		)
	})
	return cm
}

func logsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		var entry cachemanager.LogEntry
		if err := json.NewDecoder(r.Body).Decode(&entry); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if err := getCacheManager().StoreLog(entry); err != nil {
			http.Error(w, "StoreLog error: "+err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
	case http.MethodGet:
		var query cachemanager.LogQuery
		if err := json.NewDecoder(r.Body).Decode(&query); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		logs, err := getCacheManager().GetLogs(query)
		if err != nil {
			http.Error(w, "GetLogs error: "+err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(logs)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func contextHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		var req struct {
			Key   string      `json:"key"`
			Value interface{} `json:"value"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if err := getCacheManager().StoreContext(req.Key, req.Value); err != nil {
			http.Error(w, "StoreContext error: "+err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
	case http.MethodGet:
		key := r.URL.Query().Get("key")
		if key == "" {
			http.Error(w, "Missing key", http.StatusBadRequest)
			return
		}
		val, err := getCacheManager().GetContext(key)
		if err != nil {
			http.Error(w, "GetContext error: "+err.Error(), http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"key": key, "value": val})
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func main() {
	http.HandleFunc("/logs", logsHandler)
	http.HandleFunc("/context", contextHandler)
	log.Println("CacheManager API server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
