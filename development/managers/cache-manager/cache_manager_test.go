import (
	"testing"
	"time"
)

// ... (tests précédents)

func TestCacheManager_MultiBackend_FallbackPolicy(t *testing.T) {
	// LMCache échoue, Redis fonctionne
	mockLMC := &MockAdapter{failStoreLog: true}
	mockRedis := &MockAdapter{}
	mockSQLite := &MockAdapter{}
	cm := NewCacheManager(mockLMC, mockRedis, mockSQLite)
	entry := LogEntry{Level: "INFO", Source: "test", Message: "multi-backend", Timestamp: time.Now()}
	err := cm.StoreLog(entry)
	if err != nil {
		t.Errorf("StoreLog multi-backend fallback a échoué: %v", err)
	}
	if !mockLMC.storeLogCalled || !mockRedis.storeLogCalled {
		t.Error("StoreLog n'a pas fallback sur Redis")
	}
	// Redis échoue aussi, fallback SQLite
	mockLMC = &MockAdapter{failStoreLog: true}
	mockRedis = &MockAdapter{failStoreLog: true}
	mockSQLite = &MockAdapter{}
	cm = NewCacheManager(mockLMC, mockRedis, mockSQLite)
	err = cm.StoreLog(entry)
	if err != nil {
		t.Errorf("StoreLog fallback SQLite a échoué: %v", err)
	}
	if !mockSQLite.storeLogCalled {
		t.Error("StoreLog n'a pas fallback sur SQLite")
	}
}
