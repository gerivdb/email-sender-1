package cachemanager

import (
	"errors"
	"testing"
	"time"
)

// MockAdapter pour les tests
type MockAdapter struct {
	failStoreLog   bool
	storeLogCalled bool
}

func (m *MockAdapter) StoreLog(entry LogEntry) error {
	m.storeLogCalled = true
	if m.failStoreLog {
		return errors.New("failStoreLog")
	}
	return nil
}
func (m *MockAdapter) GetLogs(query LogQuery) ([]LogEntry, error)       { return nil, nil }
func (m *MockAdapter) StoreContext(key string, value interface{}) error { return nil }
func (m *MockAdapter) GetContext(key string) (interface{}, error)       { return nil, nil }

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
}
