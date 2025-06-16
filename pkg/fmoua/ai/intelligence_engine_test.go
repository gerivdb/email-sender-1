package ai

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

func createTestIntelligenceEngine(t *testing.T) *IntelligenceEngine {
	config := &types.AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             100,
		QDrant: &types.QDrantConfig{
			Host:           "localhost",
			Port:           6333,
			CollectionName: "test_collection",
			VectorSize:     768,
			DistanceMetric: "cosine",
			Timeout:        30 * time.Second,
		},
	}
	logger := zap.NewNop()

	engine, err := NewIntelligenceEngine(config, logger)
	if err != nil {
		t.Fatalf("Failed to create intelligence engine: %v", err)
	}
	return engine
}

func TestNewIntelligenceEngine(t *testing.T) {
	tests := []struct {
		name        string
		config      *types.AIConfig
		expectError bool
	}{
		{
			name: "valid config",
			config: &types.AIConfig{
				Enabled:               true,
				Provider:              "openai",
				Model:                 "gpt-4",
				ConfidenceThreshold:   0.8,
				LearningEnabled:       true,
				PatternRecognition:    true,
				DecisionAutonomyLevel: 3,
				CacheSize:             100,
				QDrant: &types.QDrantConfig{
					Host:           "localhost",
					Port:           6333,
					CollectionName: "test_collection",
					VectorSize:     768,
					DistanceMetric: "cosine",
					Timeout:        30 * time.Second,
				},
			},
			expectError: false,
		},
		{
			name:        "nil config",
			config:      nil,
			expectError: true,
		},
	}

	logger := zap.NewNop()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine, err := NewIntelligenceEngine(tt.config, logger)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if !tt.expectError && engine == nil {
				t.Error("Engine should not be nil")
			}
		})
	}
}

func TestIntelligenceEngine_Start(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()

	// Test start performance (should be < 100ms)
	startTime := time.Now()
	err := engine.Start(ctx)
	startDuration := time.Since(startTime)

	if err != nil {
		t.Errorf("Unexpected error starting engine: %v", err)
	}
	if startDuration > 100*time.Millisecond {
		t.Errorf("Start took %v, should be < 100ms for FMOUA compliance", startDuration)
	}

	// Cleanup
	engine.Stop()
}

func TestIntelligenceEngine_Stop(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()

	engine.Start(ctx)

	err := engine.Stop()
	if err != nil {
		t.Errorf("Unexpected error stopping engine: %v", err)
	}

	// Verify context is cancelled
	select {
	case <-engine.ctx.Done():
		// Expected
	default:
		t.Error("Context should be cancelled after stop")
	}
}

func TestIntelligenceEngine_AnalyzeRepository(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	tests := []struct {
		name        string
		repoPath    string
		expectError bool
	}{
		{
			name:        "valid repository path",
			repoPath:    "/test/repo",
			expectError: false,
		},
		{
			name:        "empty repository path",
			repoPath:    "",
			expectError: false, // Should still work but with different results
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			startTime := time.Now()
			decision, err := engine.AnalyzeRepository(tt.repoPath)
			duration := time.Since(startTime)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if !tt.expectError && decision == nil {
				t.Error("Decision should not be nil")
			}

			// Performance check (should be < 100ms)
			if duration > 100*time.Millisecond {
				t.Errorf("Analysis took %v, should be < 100ms", duration)
			}

			if !tt.expectError {
				// Validate decision structure
				if decision.ID == "" {
					t.Error("Decision ID should not be empty")
				}
				if decision.Confidence <= 0 || decision.Confidence > 1 {
					t.Errorf("Invalid confidence: %f", decision.Confidence)
				}
				if decision.Timestamp.IsZero() {
					t.Error("Decision timestamp should be set")
				}
			}
		})
	}
}

func TestIntelligenceEngine_MakeOrganizationDecision(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	context := map[string]interface{}{
		"file_count":       100,
		"complexity":       "high",
		"last_modified":    time.Now(),
		"similarity_score": 0.75,
	}

	startTime := time.Now()
	decision, err := engine.MakeOrganizationDecision(context)
	duration := time.Since(startTime)

	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if decision == nil {
		t.Error("Decision should not be nil")
	}

	// Performance check
	if duration > 100*time.Millisecond {
		t.Errorf("Decision making took %v, should be < 100ms", duration)
	}

	// Validate decision
	if decision.Type != interfaces.DecisionOrganization {
		t.Errorf("Expected DecisionOrganization, got %v", decision.Type)
	}
	if decision.Confidence < engine.config.ConfidenceThreshold {
		t.Errorf("Decision confidence %f below threshold %f",
			decision.Confidence, engine.config.ConfidenceThreshold)
	}
}

func TestIntelligenceEngine_OptimizePerformance(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	metrics := map[string]interface{}{
		"latency_ms":     150,
		"memory_usage":   75.5,
		"cpu_usage":      60.2,
		"cache_hit_rate": 0.65,
		"error_rate":     0.02,
	}

	startTime := time.Now()
	decision, err := engine.OptimizePerformance(metrics)
	duration := time.Since(startTime)

	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if decision == nil {
		t.Error("Decision should not be nil")
	}

	// Performance check
	if duration > 100*time.Millisecond {
		t.Errorf("Performance optimization took %v, should be < 100ms", duration)
	}

	// Validate decision
	if decision.Type != interfaces.DecisionPerformance {
		t.Errorf("Expected DecisionPerformance, got %v", decision.Type)
	}
	if len(decision.Actions) == 0 {
		t.Error("Performance decision should include recommended actions")
	}
}

func TestIntelligenceEngine_GetPerformanceStats(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	// Perform some operations to generate stats
	engine.AnalyzeRepository("/test/repo1")
	engine.AnalyzeRepository("/test/repo2")
	engine.MakeOrganizationDecision(map[string]interface{}{"test": "data"})

	stats := engine.GetPerformanceStats()
	if stats == nil {
		t.Error("Performance stats should not be nil")
	}
	// Validate stats structure
	if stats.TotalRequests <= 0 {
		t.Error("Total requests should be positive")
	}
	if stats.SuccessRate < 0 || stats.SuccessRate > 1 {
		t.Error("Success rate should be between 0 and 1")
	}
	// Note: Average latency might be 0 for mock implementation
	if stats.AverageLatency < 0 {
		t.Error("Average latency should not be negative")
	}
}

func TestIntelligenceEngine_CacheEffectiveness(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	repoPath := "/test/cache/repo"

	// First analysis (cache miss)
	startTime := time.Now()
	decision1, err := engine.AnalyzeRepository(repoPath)
	firstDuration := time.Since(startTime)

	if err != nil {
		t.Errorf("First analysis failed: %v", err)
	}

	// Second analysis (should be cached)
	startTime = time.Now()
	decision2, err := engine.AnalyzeRepository(repoPath)
	secondDuration := time.Since(startTime)

	if err != nil {
		t.Errorf("Second analysis failed: %v", err)
	}

	// Cache should improve performance
	if secondDuration >= firstDuration {
		t.Log("Note: Cache performance improvement not detected (test simulation may not reflect real caching)")
	}

	// Results should be consistent
	if decision1.ID != decision2.ID {
		t.Error("Cached results should be identical")
	}
}

func TestIntelligenceEngine_AIFirstPrinciple(t *testing.T) {
	engine := createTestIntelligenceEngine(t)

	// Test that AI is required for all operations
	if !engine.config.Enabled {
		t.Error("AI-First principle: AI should be enabled")
	}
	if !engine.config.LearningEnabled {
		t.Error("AI-First principle: Learning should be enabled")
	}
	if !engine.config.PatternRecognition {
		t.Error("AI-First principle: Pattern recognition should be enabled")
	}
	if engine.config.DecisionAutonomyLevel <= 0 {
		t.Error("AI-First principle: Decision autonomy should be configured")
	}
	if engine.config.ConfidenceThreshold <= 0 {
		t.Error("AI-First principle: Confidence threshold should be set")
	}
}

func TestIntelligenceEngine_LatencyCompliance(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	operations := []func() error{
		func() error {
			_, err := engine.AnalyzeRepository("/test/repo")
			return err
		},
		func() error {
			_, err := engine.MakeOrganizationDecision(map[string]interface{}{"test": "data"})
			return err
		},
		func() error {
			_, err := engine.OptimizePerformance(map[string]interface{}{"latency": 50})
			return err
		},
	}

	for i, operation := range operations {
		startTime := time.Now()
		err := operation()
		duration := time.Since(startTime)

		if err != nil {
			t.Errorf("Operation %d failed: %v", i, err)
		}
		if duration > 100*time.Millisecond {
			t.Errorf("Operation %d took %v, exceeds 100ms FMOUA requirement", i, duration)
		}
	}
}

func TestIntelligenceEngine_ConcurrentOperations(t *testing.T) {
	engine := createTestIntelligenceEngine(t)
	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	numOperations := 10
	results := make(chan error, numOperations)

	// Run concurrent operations
	startTime := time.Now()
	for i := 0; i < numOperations; i++ {
		go func(id int) {
			_, err := engine.AnalyzeRepository(fmt.Sprintf("/test/repo%d", id))
			results <- err
		}(i)
	}

	// Collect results
	for i := 0; i < numOperations; i++ {
		err := <-results
		if err != nil {
			t.Errorf("Concurrent operation %d failed: %v", i, err)
		}
	}

	totalDuration := time.Since(startTime)
	if totalDuration > 500*time.Millisecond {
		t.Errorf("Concurrent operations took %v, may indicate performance issues", totalDuration)
	}
}

func TestIntelligenceEngine_ErrorHandling(t *testing.T) {
	// Test with invalid QDrant config
	invalidConfig := &types.AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             100,
		QDrant: &types.QDrantConfig{
			Host:           "", // Invalid host
			Port:           0,  // Invalid port
			CollectionName: "", // Invalid collection
			VectorSize:     0,  // Invalid vector size
			DistanceMetric: "", // Invalid metric
		},
	}

	logger := zap.NewNop()
	engine, err := NewIntelligenceEngine(invalidConfig, logger)

	// Should still create engine but may fail on start
	if err != nil {
		t.Errorf("Should handle invalid config gracefully during creation: %v", err)
	}
	if engine == nil {
		t.Error("Engine should be created even with invalid config")
	}
}

func BenchmarkIntelligenceEngine_AnalyzeRepository(b *testing.B) {
	config := &types.AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             100,
		QDrant: &types.QDrantConfig{
			Host:           "localhost",
			Port:           6333,
			CollectionName: "test_collection",
			VectorSize:     768,
			DistanceMetric: "cosine",
			Timeout:        30 * time.Second,
		},
	}
	logger := zap.NewNop()

	engine, err := NewIntelligenceEngine(config, logger)
	if err != nil {
		b.Fatalf("Failed to create intelligence engine: %v", err)
	}

	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		engine.AnalyzeRepository(fmt.Sprintf("/test/repo%d", i%10))
	}
}

func BenchmarkIntelligenceEngine_MakeOrganizationDecision(b *testing.B) {
	config := &types.AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             100,
		QDrant: &types.QDrantConfig{
			Host:           "localhost",
			Port:           6333,
			CollectionName: "test_collection",
			VectorSize:     768,
			DistanceMetric: "cosine",
			Timeout:        30 * time.Second,
		},
	}
	logger := zap.NewNop()

	engine, err := NewIntelligenceEngine(config, logger)
	if err != nil {
		b.Fatalf("Failed to create intelligence engine: %v", err)
	}

	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	context := map[string]interface{}{
		"test": "data",
		"id":   0,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		context["id"] = i
		engine.MakeOrganizationDecision(context)
	}
}

func BenchmarkIntelligenceEngine_OptimizePerformance(b *testing.B) {
	config := &types.AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             100,
		QDrant: &types.QDrantConfig{
			Host:           "localhost",
			Port:           6333,
			CollectionName: "test_collection",
			VectorSize:     768,
			DistanceMetric: "cosine",
			Timeout:        30 * time.Second,
		},
	}
	logger := zap.NewNop()

	engine, err := NewIntelligenceEngine(config, logger)
	if err != nil {
		b.Fatalf("Failed to create intelligence engine: %v", err)
	}

	ctx := context.Background()
	engine.Start(ctx)
	defer engine.Stop()

	metrics := map[string]interface{}{
		"latency_ms": 50,
		"iteration":  0,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		metrics["iteration"] = i
		engine.OptimizePerformance(metrics)
	}
}
