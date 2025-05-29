package email

import (
	"context"
	"fmt"
	"log"
	"time"

	"email_sender/pkg/cache/ttl"

	"github.com/redis/go-redis/v9"
)

// EmailService provides email functionality with intelligent caching
type EmailService struct {
	cacheManager *ttl.TTLManager
	analyzer     ttl.Analyzer
	metrics      *ttl.CacheMetrics
	invalidator  *ttl.InvalidationManager
	redisClient  *redis.Client
	ctx          context.Context
}

// EmailTemplate represents an email template
type EmailTemplate struct {
	ID      string    `json:"id"`
	Name    string    `json:"name"`
	Subject string    `json:"subject"`
	Body    string    `json:"body"`
	Type    string    `json:"type"`
	Created time.Time `json:"created"`
	Updated time.Time `json:"updated"`
}

// UserPreferences represents user email preferences
type UserPreferences struct {
	UserID          string    `json:"user_id"`
	Language        string    `json:"language"`
	Timezone        string    `json:"timezone"`
	EmailFrequency  string    `json:"email_frequency"`
	Categories      []string  `json:"categories"`
	UnsubscribeList []string  `json:"unsubscribe_list"`
	LastUpdated     time.Time `json:"last_updated"`
}

// EmailStats represents email statistics
type EmailStats struct {
	TotalSent       int64     `json:"total_sent"`
	DeliveryRate    float64   `json:"delivery_rate"`
	OpenRate        float64   `json:"open_rate"`
	ClickRate       float64   `json:"click_rate"`
	BounceRate      float64   `json:"bounce_rate"`
	UnsubscribeRate float64   `json:"unsubscribe_rate"`
	LastCalculated  time.Time `json:"last_calculated"`
}

// MLModel represents cached ML model results
type MLModel struct {
	ModelID    string                 `json:"model_id"`
	Version    string                 `json:"version"`
	Results    map[string]interface{} `json:"results"`
	Confidence float64                `json:"confidence"`
	CreatedAt  time.Time              `json:"created_at"`
}

// NewEmailService creates a new email service with TTL cache management
func NewEmailService(redisClient *redis.Client) *EmailService {
	ctx := context.Background()
	// Initialize TTL manager with optimized settings
	manager := ttl.NewTTLManager(redisClient, ttl.DefaultTTLConfig())

	// Initialize analyzer for automatic optimization
	analyzer := ttl.NewTTLAnalyzer(manager)

	// Initialize metrics collection
	metrics := ttl.NewCacheMetrics(redisClient)
	// Initialize invalidation manager
	invalidator := ttl.NewInvalidationManager(redisClient, nil)

	service := &EmailService{
		cacheManager: manager,
		analyzer:     analyzer,
		metrics:      metrics,
		invalidator:  invalidator,
		redisClient:  redisClient,
		ctx:          ctx,
	}

	// Start background services
	service.startBackgroundServices()

	return service
}

// startBackgroundServices starts monitoring and optimization services
func (s *EmailService) startBackgroundServices() {
	// Start metrics collection every 10 seconds
	go s.metrics.StartMetricsCollection(s.ctx, 10*time.Second)

	// Start automatic TTL optimization every 30 minutes
	go s.analyzer.StartAutoOptimization(s.ctx, 30*time.Minute)

	// Set up alerts for cache performance
	s.setupCacheAlerts()

	log.Println("Email service background services started")
}

// setupCacheAlerts configures cache performance alerts
func (s *EmailService) setupCacheAlerts() {
	// Alert if hit rate drops below 80%
	hitRateAlert := ttl.AlertConfig{
		MetricType: "hit_rate_alert",
		Threshold:  0.8,
		Action:     "log_alert",
	}
	s.metrics.AddAlert(hitRateAlert)

	// Alert if memory usage exceeds 500MB
	memoryAlert := ttl.AlertConfig{
		MetricType: "memory_alert",
		Threshold:  500.0, // 500MB
		Action:     "log_alert",
	}
	s.metrics.AddAlert(memoryAlert)

	// Alert if latency exceeds 5ms
	latencyAlert := ttl.AlertConfig{
		MetricType: "latency_alert",
		Threshold:  5.0, // 5ms
		Action:     "log_alert",
	}
	s.metrics.AddAlert(latencyAlert)
}

// Email Template Operations with Intelligent Caching

// GetEmailTemplate retrieves an email template with caching
func (s *EmailService) GetEmailTemplate(templateID string) (*EmailTemplate, error) {
	cacheKey := fmt.Sprintf("email_template:%s", templateID)

	var template EmailTemplate
	found, err := s.cacheManager.Get(cacheKey, &template)
	if err != nil {
		return nil, fmt.Errorf("cache error: %w", err)
	}

	if found {
		log.Printf("Template %s served from cache", templateID)
		return &template, nil
	}

	// Simulate database lookup
	template = EmailTemplate{
		ID:      templateID,
		Name:    "Welcome Email",
		Subject: "Welcome to our service!",
		Body:    "Thank you for joining us...",
		Type:    "welcome",
		Created: time.Now().Add(-24 * time.Hour),
		Updated: time.Now(),
	}

	// Cache the template with configuration TTL (30 minutes)
	err = s.cacheManager.Set(cacheKey, template, ttl.Configuration)
	if err != nil {
		log.Printf("Failed to cache template %s: %v", templateID, err)
	}

	log.Printf("Template %s loaded from database and cached", templateID)
	return &template, nil
}

// InvalidateEmailTemplate invalidates a specific template cache
func (s *EmailService) InvalidateEmailTemplate(templateID string) error {
	cacheKey := fmt.Sprintf("email_template:%s", templateID)
	return s.cacheManager.Delete(cacheKey)
}

// InvalidateAllTemplates invalidates all template caches
func (s *EmailService) InvalidateAllTemplates() error {
	return s.invalidator.InvalidateByPattern("email_template:*")
}

// User Preferences Operations

// GetUserPreferences retrieves user email preferences with caching
func (s *EmailService) GetUserPreferences(userID string) (*UserPreferences, error) {
	cacheKey := fmt.Sprintf("user_prefs:%s", userID)

	var prefs UserPreferences
	found, err := s.cacheManager.Get(cacheKey, &prefs)
	if err != nil {
		return nil, fmt.Errorf("cache error: %w", err)
	}

	if found {
		log.Printf("User preferences for %s served from cache", userID)
		return &prefs, nil
	}

	// Simulate database lookup
	prefs = UserPreferences{
		UserID:          userID,
		Language:        "en",
		Timezone:        "UTC",
		EmailFrequency:  "daily",
		Categories:      []string{"news", "updates"},
		UnsubscribeList: []string{},
		LastUpdated:     time.Now(),
	}

	// Cache with user session TTL (2 hours)
	err = s.cacheManager.Set(cacheKey, prefs, ttl.UserSessions)
	if err != nil {
		log.Printf("Failed to cache user preferences for %s: %v", userID, err)
	}

	log.Printf("User preferences for %s loaded from database and cached", userID)
	return &prefs, nil
}

// UpdateUserPreferences updates user preferences and invalidates cache
func (s *EmailService) UpdateUserPreferences(userID string, prefs *UserPreferences) error {
	// Update in database (simulated)
	prefs.LastUpdated = time.Now()

	// Invalidate cache to force refresh
	cacheKey := fmt.Sprintf("user_prefs:%s", userID)
	err := s.cacheManager.Delete(cacheKey)
	if err != nil {
		log.Printf("Failed to invalidate user preferences cache for %s: %v", userID, err)
	}

	// Invalidate related patterns if user unsubscribed
	if len(prefs.UnsubscribeList) > 0 {
		err = s.invalidator.InvalidateByEvent("user_update", fmt.Sprintf("user:*:%s", userID))
		if err != nil {
			log.Printf("Failed to invalidate related caches for user %s: %v", userID, err)
		}
	}

	log.Printf("User preferences updated for %s", userID)
	return nil
}

// Email Statistics Operations

// GetEmailStats retrieves email statistics with long-term caching
func (s *EmailService) GetEmailStats() (*EmailStats, error) {
	cacheKey := "email_stats:global"

	var stats EmailStats
	found, err := s.cacheManager.Get(cacheKey, &stats)
	if err != nil {
		return nil, fmt.Errorf("cache error: %w", err)
	}

	if found {
		log.Println("Email stats served from cache")
		return &stats, nil
	}

	// Simulate heavy calculation
	stats = EmailStats{
		TotalSent:       10000,
		DeliveryRate:    0.98,
		OpenRate:        0.25,
		ClickRate:       0.05,
		BounceRate:      0.02,
		UnsubscribeRate: 0.001,
		LastCalculated:  time.Now(),
	}

	// Cache with statistics TTL (24 hours)
	err = s.cacheManager.Set(cacheKey, stats, ttl.Statistics)
	if err != nil {
		log.Printf("Failed to cache email stats: %v", err)
	}

	log.Println("Email stats calculated and cached")
	return &stats, nil
}

// ML Model Operations

// GetMLModelResults retrieves ML model results with caching
func (s *EmailService) GetMLModelResults(modelID, inputHash string) (*MLModel, error) {
	cacheKey := fmt.Sprintf("ml_model:%s:%s", modelID, inputHash)

	var model MLModel
	found, err := s.cacheManager.Get(cacheKey, &model)
	if err != nil {
		return nil, fmt.Errorf("cache error: %w", err)
	}

	if found {
		log.Printf("ML model results for %s served from cache", modelID)
		return &model, nil
	}

	// Simulate ML model inference
	model = MLModel{
		ModelID: modelID,
		Version: "1.0.0",
		Results: map[string]interface{}{
			"sentiment": "positive",
			"score":     0.85,
			"category":  "customer_service",
		},
		Confidence: 0.92,
		CreatedAt:  time.Now(),
	}

	// Cache with ML models TTL (1 hour)
	err = s.cacheManager.Set(cacheKey, model, ttl.MLModels)
	if err != nil {
		log.Printf("Failed to cache ML model results for %s: %v", modelID, err)
	}

	log.Printf("ML model results for %s calculated and cached", modelID)
	return &model, nil
}

// InvalidateMLModelResults invalidates ML model cache when model is updated
func (s *EmailService) InvalidateMLModelResults(modelID string, version string) error {
	// Invalidate by version to clear old model results
	return s.invalidator.InvalidateByVersion(fmt.Sprintf("ml_model:%s", modelID), version)
}

// Cache Analytics and Optimization

// GetCacheMetrics returns current cache performance metrics
func (s *EmailService) GetCacheMetrics() *ttl.MetricData {
	return s.metrics.GetCurrentMetrics()
}

// GetCacheAnalysis provides detailed cache analysis
func (s *EmailService) GetCacheAnalysis() map[string]*ttl.PatternAnalysis {
	patterns := []string{
		"email_template:*",
		"user_prefs:*",
		"email_stats:*",
		"ml_model:*",
	}

	analysis := make(map[string]*ttl.PatternAnalysis)
	for _, pattern := range patterns {
		if result := s.analyzer.AnalyzePattern(pattern); result != nil {
			analysis[pattern] = result
		}
	}

	return analysis
}

// OptimizeCache performs cache optimization based on usage patterns
func (s *EmailService) OptimizeCache() error {
	patterns := []string{
		"email_template:*",
		"user_prefs:*",
		"email_stats:*",
		"ml_model:*",
	}

	for _, pattern := range patterns {
		err := s.analyzer.OptimizeTTL(pattern)
		if err != nil {
			log.Printf("Failed to optimize TTL for pattern %s: %v", pattern, err)
		}
	}

	log.Println("Cache optimization completed")
	return nil
}

// GetOptimizationRecommendations returns suggestions for cache improvements
func (s *EmailService) GetOptimizationRecommendations() []ttl.OptimizationRecommendation {
	return s.analyzer.GetOptimizationRecommendations()
}

// Cleanup performs cache cleanup and resource management
func (s *EmailService) Cleanup() error {
	// Stop background services
	if s.ctx != nil {
		// In a real implementation, you'd cancel the context
		log.Println("Stopping background services...")
	}

	// Perform final cache optimization
	s.OptimizeCache()

	// Clear expired keys
	err := s.invalidator.InvalidateByAge(time.Hour * 24)
	if err != nil {
		log.Printf("Failed to clear expired keys: %v", err)
	}

	log.Println("Email service cleanup completed")
	return nil
}

// Health Check Operations

// HealthCheck performs a comprehensive health check
func (s *EmailService) HealthCheck() map[string]interface{} {
	health := make(map[string]interface{})

	// Check Redis connectivity
	pong := s.redisClient.Ping(s.ctx)
	health["redis"] = pong.Err() == nil

	// Check cache metrics
	metrics := s.metrics.GetCurrentMetrics()
	health["cache_hit_rate"] = metrics.HitRate
	health["cache_memory_usage"] = metrics.MemoryUsage
	health["cache_total_keys"] = metrics.CacheSize

	// Check if hit rate is healthy (>70%)
	health["cache_healthy"] = metrics.HitRate > 0.7

	// Overall health
	health["overall_healthy"] = health["redis"].(bool) && health["cache_healthy"].(bool)

	return health
}
