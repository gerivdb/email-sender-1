package apigateway

import (
	"net/http"
	"strings"
	"sync"
	"time"
)

// RateLimiter gère le rate limiting par clé (IP, API Key, etc.)
type RateLimiter struct {
	limits map[string]*rateLimitEntry
	mu     sync.Mutex
	limit  int           // requêtes max
	window time.Duration // fenêtre de temps
}

type rateLimitEntry struct {
	count     int
	windowEnd time.Time
}

// NewRateLimiter crée un rate limiter
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		limits: make(map[string]*rateLimitEntry),
		limit:  limit,
		window: window,
	}
}

// Allow vérifie si la clé peut faire une requête
func (rl *RateLimiter) Allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	entry, exists := rl.limits[key]
	now := time.Now()
	if !exists || now.After(entry.windowEnd) {
		rl.limits[key] = &rateLimitEntry{count: 1, windowEnd: now.Add(rl.window)}
		return true
	}
	if entry.count < rl.limit {
		entry.count++
		return true
	}
	return false
}

// APIGateway gère le routage, l’authentification et le rate limiting
type APIGateway struct {
	rateLimiter *RateLimiter
	apiKeys     map[string]bool
	routes      map[string]http.HandlerFunc
}

// NewAPIGateway crée une API Gateway
func NewAPIGateway(rateLimit int, window time.Duration, apiKeys []string) *APIGateway {
	keyMap := make(map[string]bool)
	for _, k := range apiKeys {
		keyMap[k] = true
	}
	return &APIGateway{
		rateLimiter: NewRateLimiter(rateLimit, window),
		apiKeys:     keyMap,
		routes:      make(map[string]http.HandlerFunc),
	}
}

// RegisterRoute ajoute une route protégée
func (gw *APIGateway) RegisterRoute(path string, handler http.HandlerFunc) {
	gw.routes[path] = handler
}

// ServeHTTP implémente http.Handler
func (gw *APIGateway) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	apiKey := r.Header.Get("X-API-Key")
	clientIP := strings.Split(r.RemoteAddr, ":")[0]
	key := apiKey
	if key == "" {
		key = clientIP
	}
	if !gw.rateLimiter.Allow(key) {
		http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
		return
	}
	if apiKey != "" && !gw.apiKeys[apiKey] {
		http.Error(w, "Invalid API Key", http.StatusUnauthorized)
		return
	}
	handler, exists := gw.routes[r.URL.Path]
	if !exists {
		http.NotFound(w, r)
		return
	}
	handler(w, r)
}

// Example usage (to be integrated in main.go or server.go)
/*
func main() {
gateway := apigateway.NewAPIGateway(100, time.Minute, []string{"my-secret-key"})
gateway.RegisterRoute("/api/v1/secure", func(w http.ResponseWriter, r *http.Request) {
w.Write([]byte("Secure endpoint OK"))
})
http.ListenAndServe(":8080", gateway)
}
*/
