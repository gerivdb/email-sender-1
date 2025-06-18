package middleware

import (
	"sync"
	"time"
)

// RateLimiter interface pour la limitation de taux
type RateLimiter interface {
	Allow(identifier string) bool
	GetLimits(identifier string) (*RateLimit, error)
	Reset(identifier string) error
}

// TokenBucketRateLimiter implémentation avec Token Bucket
type TokenBucketRateLimiter struct {
	buckets map[string]*TokenBucket
	mu      sync.RWMutex
	config  *RateLimit
}

// TokenBucket représente un seau de jetons
type TokenBucket struct {
	tokens     float64
	capacity   float64
	refillRate float64
	lastRefill time.Time
	mu         sync.Mutex
}

// NewTokenBucketRateLimiter crée un nouveau rate limiter
func NewTokenBucketRateLimiter(config *RateLimit) RateLimiter {
	return &TokenBucketRateLimiter{
		buckets: make(map[string]*TokenBucket),
		config:  config,
	}
}

func (rl *TokenBucketRateLimiter) Allow(identifier string) bool {
	rl.mu.Lock()
	bucket, exists := rl.buckets[identifier]
	if !exists {
		bucket = &TokenBucket{
			tokens:     float64(rl.config.BurstLimit),
			capacity:   float64(rl.config.BurstLimit),
			refillRate: float64(rl.config.RequestsPerMinute) / 60.0, // tokens per second
			lastRefill: time.Now(),
		}
		rl.buckets[identifier] = bucket
	}
	rl.mu.Unlock()

	return bucket.consume(1.0)
}

func (rl *TokenBucketRateLimiter) GetLimits(identifier string) (*RateLimit, error) {
	return rl.config, nil
}

func (rl *TokenBucketRateLimiter) Reset(identifier string) error {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	delete(rl.buckets, identifier)
	return nil
}

func (tb *TokenBucket) consume(tokens float64) bool {
	tb.mu.Lock()
	defer tb.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(tb.lastRefill).Seconds()

	// Ajouter des jetons basés sur le temps écoulé
	tb.tokens += elapsed * tb.refillRate
	if tb.tokens > tb.capacity {
		tb.tokens = tb.capacity
	}

	tb.lastRefill = now

	// Vérifier si nous pouvons consommer les jetons
	if tb.tokens >= tokens {
		tb.tokens -= tokens
		return true
	}

	return false
}

// MemoryRateLimiter implémentation simple en mémoire
type MemoryRateLimiter struct {
	requests map[string][]time.Time
	mu       sync.RWMutex
	config   *RateLimit
}

func NewMemoryRateLimiter(config *RateLimit) RateLimiter {
	limiter := &MemoryRateLimiter{
		requests: make(map[string][]time.Time),
		config:   config,
	}

	// Nettoyer les anciennes entrées périodiquement
	go limiter.cleanup()

	return limiter
}

func (rl *MemoryRateLimiter) Allow(identifier string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	windowStart := now.Add(-rl.config.WindowDuration)

	// Nettoyer les anciennes requêtes
	requests := rl.requests[identifier]
	var validRequests []time.Time
	for _, reqTime := range requests {
		if reqTime.After(windowStart) {
			validRequests = append(validRequests, reqTime)
		}
	}

	// Vérifier la limite
	if len(validRequests) >= rl.config.RequestsPerMinute {
		rl.requests[identifier] = validRequests
		return false
	}

	// Ajouter la nouvelle requête
	validRequests = append(validRequests, now)
	rl.requests[identifier] = validRequests

	return true
}

func (rl *MemoryRateLimiter) GetLimits(identifier string) (*RateLimit, error) {
	return rl.config, nil
}

func (rl *MemoryRateLimiter) Reset(identifier string) error {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	delete(rl.requests, identifier)
	return nil
}

func (rl *MemoryRateLimiter) cleanup() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		windowStart := now.Add(-rl.config.WindowDuration)

		for identifier, requests := range rl.requests {
			var validRequests []time.Time
			for _, reqTime := range requests {
				if reqTime.After(windowStart) {
					validRequests = append(validRequests, reqTime)
				}
			}

			if len(validRequests) == 0 {
				delete(rl.requests, identifier)
			} else {
				rl.requests[identifier] = validRequests
			}
		}
		rl.mu.Unlock()
	}
}
