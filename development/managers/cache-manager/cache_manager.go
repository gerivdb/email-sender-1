// CacheManager v74 — Gestion centralisée des caches et logs (implémentation réelle)

package cachemanager

import (
	"errors"
	"sync"
	"time"
)

// Interfaces des adapters
type CacheAdapter interface {
	StoreLog(entry LogEntry) error
	GetLogs(query LogQuery) ([]LogEntry, error)
	StoreContext(key string, value interface{}) error
	GetContext(key string) (interface{}, error)
}

// Structure du log (conforme à logging_format_spec.json)
type LogEntry struct {
	Timestamp time.Time              `json:"timestamp"`
	Level     string                 `json:"level"`
	Source    string                 `json:"source"`
	Message   string                 `json:"message"`
	Context   map[string]interface{} `json:"context,omitempty"`
	TraceID   string                 `json:"trace_id,omitempty"`
	User      string                 `json:"user,omitempty"`
}

// Structure de requête de logs
type LogQuery struct {
	Level   string
	Source  string
	From    *time.Time
	To      *time.Time
	TraceID string
}

// CacheManager principal
type CacheManager struct {
	mu          sync.RWMutex
	lmcCache    CacheAdapter
	redisCache  CacheAdapter
	sqliteCache CacheAdapter
	backends    []CacheAdapter
}

// Initialisation du CacheManager
func NewCacheManager(lmc, redis, sqlite CacheAdapter) *CacheManager {
	backends := []CacheAdapter{}
	if lmc != nil {
		backends = append(backends, lmc)
	}
	if redis != nil {
		backends = append(backends, redis)
	}
	if sqlite != nil {
		backends = append(backends, sqlite)
	}
	return &CacheManager{
		lmcCache:    lmc,
		redisCache:  redis,
		sqliteCache: sqlite,
		backends:    backends,
	}
}

// StoreLog — Orchestration selon la politique (LMCache prioritaire)
func (cm *CacheManager) StoreLog(entry LogEntry) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	var lastErr error
	for _, backend := range cm.backends {
		if backend != nil {
			if err := backend.StoreLog(entry); err == nil {
				return nil
			} else {
				lastErr = err
			}
		}
	}
	if lastErr != nil {
		return lastErr
	}
	return errors.New("aucun backend de cache disponible")
}

// GetLogs — Recherche unifiée (LMCache prioritaire)
func (cm *CacheManager) GetLogs(query LogQuery) ([]LogEntry, error) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	for _, backend := range cm.backends {
		if backend != nil {
			logs, err := backend.GetLogs(query)
			if err == nil {
				return logs, nil
			}
		}
	}
	return nil, errors.New("aucun backend de cache disponible")
}

// StoreContext — Stockage contextuel
func (cm *CacheManager) StoreContext(key string, value interface{}) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	var lastErr error
	for _, backend := range cm.backends {
		if backend != nil {
			if err := backend.StoreContext(key, value); err == nil {
				return nil
			} else {
				lastErr = err
			}
		}
	}
	if lastErr != nil {
		return lastErr
	}
	return errors.New("aucun backend de cache disponible")
}

// GetContext — Récupération contextuelle
func (cm *CacheManager) GetContext(key string) (interface{}, error) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	for _, backend := range cm.backends {
		if backend != nil {
			val, err := backend.GetContext(key)
			if err == nil {
				return val, nil
			}
		}
	}
	return nil, errors.New("aucun backend de cache disponible")
}
