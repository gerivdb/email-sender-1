package security

import (
	"crypto/rand"
	"encoding/base64"
	"sync"
	"time"
)

// APIKeyStore gère les clés/tokens actifs et historiques
type APIKeyStore struct {
	currentKey   string
	previousKeys []string
	rotationIntv time.Duration
	mu           sync.RWMutex
	stopCh       chan struct{}
}

// NewAPIKeyStore crée un store avec rotation automatique
func NewAPIKeyStore(rotationIntv time.Duration) *APIKeyStore {
	store := &APIKeyStore{
		rotationIntv: rotationIntv,
		stopCh:       make(chan struct{}),
	}
	store.rotateKey()
	go store.autoRotate()
	return store
}

// rotateKey génère une nouvelle clé et archive l’ancienne
func (s *APIKeyStore) rotateKey() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.currentKey != "" {
		s.previousKeys = append(s.previousKeys, s.currentKey)
		if len(s.previousKeys) > 5 {
			s.previousKeys = s.previousKeys[1:]
		}
	}
	s.currentKey = generateRandomKey(32)
}

// autoRotate lance la rotation périodique
func (s *APIKeyStore) autoRotate() {
	ticker := time.NewTicker(s.rotationIntv)
	defer ticker.Stop()
	for {
		select {
		case <-s.stopCh:
			return
		case <-ticker.C:
			s.rotateKey()
		}
	}
}

// Stop arrête la rotation automatique
func (s *APIKeyStore) Stop() {
	close(s.stopCh)
}

// GetCurrentKey retourne la clé active
func (s *APIKeyStore) GetCurrentKey() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.currentKey
}

// ValidateKey vérifie si une clé est valide (active ou récente)
func (s *APIKeyStore) ValidateKey(key string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if key == s.currentKey {
		return true
	}
	for _, k := range s.previousKeys {
		if key == k {
			return true
		}
	}
	return false
}

// generateRandomKey génère une clé base64
func generateRandomKey(length int) string {
	b := make([]byte, length)
	_, _ = rand.Read(b)
	return base64.StdEncoding.EncodeToString(b)
}

// Example usage:
/*
func main() {
store := security.NewAPIKeyStore(24 * time.Hour)
defer store.Stop()
key := store.GetCurrentKey()
valid := store.ValidateKey(key)
}
*/
