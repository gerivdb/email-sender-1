package email_server

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"

	"email_sender/pkg/email"
)

var (
	Version		= "1.0.0"
	BuildDate	= "2024-01-01"
)

type Server struct {
	emailService	*email.EmailService
	router		*mux.Router
	httpServer	*http.Server
	redisClient	*redis.Client
}

func main() {
	var (
		port		= flag.String("port", "8080", "HTTP server port")
		redisAddr	= flag.String("redis-addr", "localhost:6379", "Redis server address")
		redisPass	= flag.String("redis-pass", "", "Redis password")
		redisDB		= flag.Int("redis-db", 0, "Redis database number")
	)
	flag.Parse()

	log.Printf("Starting Email Sender Server v%s (built %s)", Version, BuildDate)

	// Initialize Redis client
	redisClient := redis.NewClient(&redis.Options{
		Addr:		*redisAddr,
		Password:	*redisPass,
		DB:		*redisDB,
	})

	// Test Redis connection
	ctx := context.Background()
	pong := redisClient.Ping(ctx)
	if pong.Err() != nil {
		log.Printf("Redis connection failed: %v", pong.Err())
		log.Println("Continuing without Redis - some features will be limited")
	} else {
		log.Println("Redis connection established successfully")
	}

	// Create server
	server := &Server{
		emailService:	email.NewEmailService(redisClient),
		redisClient:	redisClient,
	}

	// Setup router and routes
	server.setupRoutes()

	// Create HTTP server
	server.httpServer = &http.Server{
		Addr:		":" + *port,
		Handler:	server.router,
		ReadTimeout:	15 * time.Second,
		WriteTimeout:	15 * time.Second,
		IdleTimeout:	60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Server starting on port %s", *port)
		if err := server.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	server.shutdown()
}

func (s *Server) setupRoutes() {
	s.router = mux.NewRouter()

	// Health check endpoint
	s.router.HandleFunc("/health", s.healthHandler).Methods("GET")
	s.router.HandleFunc("/health/detailed", s.detailedHealthHandler).Methods("GET")

	// Email template endpoints
	s.router.HandleFunc("/api/v1/templates/{id}", s.getTemplateHandler).Methods("GET")
	s.router.HandleFunc("/api/v1/templates/{id}/invalidate", s.invalidateTemplateHandler).Methods("POST")
	s.router.HandleFunc("/api/v1/templates/invalidate-all", s.invalidateAllTemplatesHandler).Methods("POST")

	// User preferences endpoints
	s.router.HandleFunc("/api/v1/users/{id}/preferences", s.getUserPreferencesHandler).Methods("GET")
	s.router.HandleFunc("/api/v1/users/{id}/preferences", s.updateUserPreferencesHandler).Methods("PUT")

	// Statistics endpoints
	s.router.HandleFunc("/api/v1/stats", s.getStatsHandler).Methods("GET")

	// ML model endpoints
	s.router.HandleFunc("/api/v1/ml/{modelId}/results", s.getMLResultsHandler).Methods("GET")
	s.router.HandleFunc("/api/v1/ml/{modelId}/invalidate", s.invalidateMLResultsHandler).Methods("POST")

	// Cache management endpoints
	s.router.HandleFunc("/api/v1/cache/metrics", s.getCacheMetricsHandler).Methods("GET")
	s.router.HandleFunc("/api/v1/cache/analysis", s.getCacheAnalysisHandler).Methods("GET")
	s.router.HandleFunc("/api/v1/cache/optimize", s.optimizeCacheHandler).Methods("POST")
	s.router.HandleFunc("/api/v1/cache/recommendations", s.getCacheRecommendationsHandler).Methods("GET")

	// Prometheus metrics endpoint
	s.router.Handle("/metrics", promhttp.Handler())

	// Add middleware
	s.router.Use(s.loggingMiddleware)
	s.router.Use(s.corsMiddleware)
}

// Health check handlers

func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {
	health := s.emailService.HealthCheck()

	w.Header().Set("Content-Type", "application/json")
	if health["overall_healthy"].(bool) {
		w.WriteHeader(http.StatusOK)
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":	"ok",
		"version":	Version,
		"healthy":	health["overall_healthy"],
	})
}

func (s *Server) detailedHealthHandler(w http.ResponseWriter, r *http.Request) {
	health := s.emailService.HealthCheck()

	w.Header().Set("Content-Type", "application/json")
	if health["overall_healthy"].(bool) {
		w.WriteHeader(http.StatusOK)
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	health["version"] = Version
	health["build_date"] = BuildDate
	health["timestamp"] = time.Now().UTC()

	json.NewEncoder(w).Encode(health)
}

// Email template handlers

func (s *Server) getTemplateHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	templateID := vars["id"]

	template, err := s.emailService.GetEmailTemplate(templateID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get template: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(template)
}

func (s *Server) invalidateTemplateHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	templateID := vars["id"]

	err := s.emailService.InvalidateEmailTemplate(templateID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to invalidate template: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":	"success",
		"message":	fmt.Sprintf("Template %s invalidated", templateID),
	})
}

func (s *Server) invalidateAllTemplatesHandler(w http.ResponseWriter, r *http.Request) {
	err := s.emailService.InvalidateAllTemplates()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to invalidate all templates: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":	"success",
		"message":	"All templates invalidated",
	})
}

// User preferences handlers

func (s *Server) getUserPreferencesHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	prefs, err := s.emailService.GetUserPreferences(userID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get user preferences: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(prefs)
}

func (s *Server) updateUserPreferencesHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	var prefs email.UserPreferences
	if err := json.NewDecoder(r.Body).Decode(&prefs); err != nil {
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	prefs.UserID = userID
	err := s.emailService.UpdateUserPreferences(userID, &prefs)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to update user preferences: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":	"success",
		"message":	fmt.Sprintf("User preferences updated for %s", userID),
	})
}

// Statistics handlers

func (s *Server) getStatsHandler(w http.ResponseWriter, r *http.Request) {
	stats, err := s.emailService.GetEmailStats()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get email stats: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// ML model handlers

func (s *Server) getMLResultsHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	modelID := vars["modelId"]
	inputHash := r.URL.Query().Get("input_hash")

	if inputHash == "" {
		http.Error(w, "input_hash query parameter required", http.StatusBadRequest)
		return
	}

	results, err := s.emailService.GetMLModelResults(modelID, inputHash)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get ML results: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func (s *Server) invalidateMLResultsHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	modelID := vars["modelId"]
	version := r.URL.Query().Get("version")

	if version == "" {
		http.Error(w, "version query parameter required", http.StatusBadRequest)
		return
	}

	err := s.emailService.InvalidateMLModelResults(modelID, version)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to invalidate ML results: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":	"success",
		"message":	fmt.Sprintf("ML model %s (v%s) results invalidated", modelID, version),
	})
}

// Cache management handlers

func (s *Server) getCacheMetricsHandler(w http.ResponseWriter, r *http.Request) {
	metrics := s.emailService.GetCacheMetrics()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(metrics)
}

func (s *Server) getCacheAnalysisHandler(w http.ResponseWriter, r *http.Request) {
	analysis := s.emailService.GetCacheAnalysis()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(analysis)
}

func (s *Server) optimizeCacheHandler(w http.ResponseWriter, r *http.Request) {
	err := s.emailService.OptimizeCache()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to optimize cache: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":	"success",
		"message":	"Cache optimization completed",
	})
}

func (s *Server) getCacheRecommendationsHandler(w http.ResponseWriter, r *http.Request) {
	recommendations := s.emailService.GetOptimizationRecommendations()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(recommendations)
}

// Middleware

func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.RequestURI, time.Since(start))
	})
}

func (s *Server) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// Shutdown gracefully closes the server
func (s *Server) shutdown() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Shutdown HTTP server
	if err := s.httpServer.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	// Cleanup email service
	if s.emailService != nil {
		s.emailService.Cleanup()
	}

	// Close Redis connection
	if s.redisClient != nil {
		s.redisClient.Close()
	}

	log.Println("Server shutdown complete")
}
