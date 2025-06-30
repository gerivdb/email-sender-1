// Adapter LMCache pour CacheManager v74 (implémentation réelle simulée)

package cachemanager

import (
	"errors"
	"fmt"
	"sync"
)

// Simule un client LMCache (à remplacer par l’intégration réelle)
type LMCacheClient struct {
	mu    sync.RWMutex
	store map[string]interface{}
	logs  []LogEntry
}

func NewLMCacheClient() *LMCacheClient {
	return &LMCacheClient{
		store: make(map[string]interface{}),
		logs:  []LogEntry{},
	}
}

// LMCacheAdapter — implémente CacheAdapter pour LMCache
type LMCacheAdapter struct {
	client *LMCacheClient
}

func NewLMCacheAdapter() *LMCacheAdapter {
	return &LMCacheAdapter{
		client: NewLMCacheClient(),
	}
}

func (l *LMCacheAdapter) StoreLog(entry LogEntry) error {
	l.client.mu.Lock()
	defer l.client.mu.Unlock()
	l.client.logs = append(l.client.logs, entry)
	return nil
}

func (l *LMCacheAdapter) GetLogs(query LogQuery) ([]LogEntry, error) {
	l.client.mu.RLock()
	defer l.client.mu.RUnlock()
	var result []LogEntry
	for _, log := range l.client.logs {
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

func (l *LMCacheAdapter) StoreContext(key string, value interface{}) error {
	l.client.mu.Lock()
	defer l.client.mu.Unlock()
	l.client.store[key] = value
	return nil
}

func (l *LMCacheAdapter) GetContext(key string) (interface{}, error) {
	l.client.mu.RLock()
	defer l.client.mu.RUnlock()
	val, ok := l.client.store[key]
	if !ok {
		return nil, fmt.Errorf("clé %s non trouvée", key)
	}
	return val, nil
}
