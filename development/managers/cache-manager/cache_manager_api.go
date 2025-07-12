// API REST CacheManager v74 — Serveur Go natif

package cachemanager

import (
	"encoding/json"
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
		// ... reste du code ...
	}
}
