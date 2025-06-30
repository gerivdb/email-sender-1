// Adapter SQLite pour CacheManager v74 (implémentation réelle simulée)

package cachemanager

import (
	"errors"
	"fmt"
	"sync"
)

// Simule un client SQLite (à remplacer par l’intégration réelle)
type SQLiteClient struct {
	mu    sync.RWMutex
	store map[string]interface{}
	logs  []LogEntry
}

func NewSQLiteClient() *SQLiteClient {
	return &SQLiteClient{
		store: make(map[string]interface{}),
		logs:  []LogEntry{},
	}
}

// SQLiteAdapter — implémente CacheAdapter pour SQLite
type SQLiteAdapter struct {
	client *SQLiteClient
}

func NewSQLiteAdapter() *SQLiteAdapter {
	return &SQLiteAdapter{
		client: NewSQLiteClient(),
	}
}

func (s *SQLiteAdapter) StoreLog(entry LogEntry) error {
	s.client.mu.Lock()
	defer s.client.mu.Unlock()
	s.client.logs = append(s.client.logs, entry)
	return nil
}

func (s *SQLiteAdapter) GetLogs(query LogQuery) ([]LogEntry, error) {
	s.client.mu.RLock()
	defer s.client.mu.RUnlock()
	var result []LogEntry
	for _, log := range s.client.logs {
		if query.Level != "" && log.Level != query.Level {
			continue
		}
		if query.Source != "" && log.Source != query.Source {
			continue
		}
		result = append(result, log)
	}
	if len(result) == 0 {
		return nil, errors.New("aucun log trouvé")
	}
	return result, nil
}

func (s *SQLiteAdapter) StoreContext(key string, value interface{}) error {
	s.client.mu.Lock()
	defer s.client.mu.Unlock()
	s.client.store[key] = value
	return nil
}

func (s *SQLiteAdapter) GetContext(key string) (interface{}, error) {
	s.client.mu.RLock()
	defer s.client.mu.RUnlock()
	val, ok := s.client.store[key]
	if !ok {
		return nil, fmt.Errorf("clé %s non trouvée", key)
	}
	return val, nil
}
