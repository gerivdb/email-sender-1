// Tests unitaires pour LMCacheAdapter, RedisAdapter, SQLiteAdapter

package cachemanager

import (
	"testing"
	"time"
)

func TestLMCacheAdapter_StoreAndGetLog(t *testing.T) {
	lmc := NewLMCacheAdapter()
	entry := LogEntry{Level: "INFO", Source: "lmc", Message: "log lmc", Timestamp: time.Now()}
	if err := lmc.StoreLog(entry); err != nil {
		t.Fatalf("StoreLog LMCacheAdapter a échoué: %v", err)
	}
	logs, err := lmc.GetLogs(LogQuery{Level: "INFO"})
	if err != nil || len(logs) == 0 {
		t.Fatalf("GetLogs LMCacheAdapter a échoué: %v", err)
	}
}

func TestRedisAdapter_StoreAndGetLog(t *testing.T) {
	redis := NewRedisAdapter()
	entry := LogEntry{Level: "INFO", Source: "redis", Message: "log redis", Timestamp: time.Now()}
	if err := redis.StoreLog(entry); err != nil {
		t.Fatalf("StoreLog RedisAdapter a échoué: %v", err)
	}
	logs, err := redis.GetLogs(LogQuery{Level: "INFO"})
	if err != nil || len(logs) == 0 {
		t.Fatalf("GetLogs RedisAdapter a échoué: %v", err)
	}
}

func TestSQLiteAdapter_StoreAndGetLog(t *testing.T) {
	sqlite := NewSQLiteAdapter()
	entry := LogEntry{Level: "INFO", Source: "sqlite", Message: "log sqlite", Timestamp: time.Now()}
	if err := sqlite.StoreLog(entry); err != nil {
		t.Fatalf("StoreLog SQLiteAdapter a échoué: %v", err)
	}
	logs, err := sqlite.GetLogs(LogQuery{Level: "INFO"})
	if err != nil || len(logs) == 0 {
		t.Fatalf("GetLogs SQLiteAdapter a échoué: %v", err)
	}
}
