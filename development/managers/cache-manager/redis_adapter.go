// Adapter Redis pour CacheManager v74 (implémentation réelle simulée)

package cachemanager

import (
	"errors"
	"fmt"
	"sync"
)

// Simule un client Redis (à remplacer par l’intégration réelle)
type RedisClient struct {
	mu    sync.RWMutex
	store map[string]interface{}
	logs  []LogEntry
}

func NewRedisClient() *RedisClient {
	return &RedisClient{
		store: make(map[string]interface{}),
		logs:  []LogEntry{},
	}
}

// RedisAdapter — implémente CacheAdapter pour Redis
type RedisAdapter struct {
	client *RedisClient
}

func NewRedisAdapter() *RedisAdapter {
	return &RedisAdapter{
		client: NewRedisClient(),
	}
}

func (r *RedisAdapter) StoreLog(entry LogEntry) error {
	r.client.mu.Lock()
	defer r.client.mu.Unlock()
	r.client.logs = append(r.client.logs, entry)
	return nil
}

func (r *RedisAdapter) GetLogs(query LogQuery) ([]LogEntry, error) {
	r.client.mu.RLock()
	defer r.client.mu.RUnlock()
	var result []LogEntry
	for _, log := range r.client.logs {
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

func (r *RedisAdapter) StoreContext(key string, value interface{}) error {
	r.client.mu.Lock()
	defer r.client.mu.Unlock()
	r.client.store[key] = value
	return nil
}

func (r *RedisAdapter) GetContext(key string) (interface{}, error) {
	r.client.mu.RLock()
	defer r.client.mu.RUnlock()
	val, ok := r.client.store[key]
	if !ok {
		return nil, fmt.Errorf("clé %s non trouvée", key)
	}
	return val, nil
}
