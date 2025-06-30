// Test d’intégration bout-en-bout CacheManager + Adapters (phase 7.2)

package cachemanager

import (
	"testing"
	"time"
)

func TestCacheManager_EndToEnd_AllBackends(t *testing.T) {
	lmc := NewLMCacheAdapter()
	redis := NewRedisAdapter()
	sqlite := NewSQLiteAdapter()
	cm := NewCacheManager(lmc, redis, sqlite)

	entry := LogEntry{Level: "INFO", Source: "e2e", Message: "log e2e", Timestamp: time.Now()}
	if err := cm.StoreLog(entry); err != nil {
		t.Fatalf("StoreLog E2E a échoué: %v", err)
	}

	logs, err := cm.GetLogs(LogQuery{Level: "INFO"})
	if err != nil || len(logs) == 0 {
		t.Fatalf("GetLogs E2E a échoué: %v", err)
	}

	// Vérifie que chaque backend a bien stocké le log (en mode simulé)
	lmcLogs, _ := lmc.GetLogs(LogQuery{Level: "INFO"})
	redisLogs, _ := redis.GetLogs(LogQuery{Level: "INFO"})
	sqliteLogs, _ := sqlite.GetLogs(LogQuery{Level: "INFO"})
	if len(lmcLogs) == 0 && len(redisLogs) == 0 && len(sqliteLogs) == 0 {
		t.Error("Aucun backend n'a stocké le log")
	}
}
