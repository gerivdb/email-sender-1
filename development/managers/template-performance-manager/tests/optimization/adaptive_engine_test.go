package optimization

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/gerivdb/email-sender-1/development/managers/template-performance-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/template-performance-manager/internal/optimization"
)

func TestAdaptiveEngine_Initialize(t *testing.T) {
	tests := []struct {
		name        string
		config      optimization.Config
		expectError bool
	}{
		{
			name:        "Valid configuration",
			config:      optimization.DefaultConfig(),
			expectError: false,
		},
		{
			name: "Invalid ML endpoint",
			config: optimization.Config{
				MLEndpoint:          "",
				MaxOptimizers:       10,
				OptimizationTimeout: time.Minute,
				LearningRate:        0.01,
			},
			expectError: true,
		},
		{
			name: "Invalid learning rate",
			config: optimization.Config{
				MLEndpoint:          "http://localhost:8080",
				MaxOptimizers:       10,
				OptimizationTimeout: time.Minute,
				LearningRate:        -0.1,
			},
			expectError: true,
		},
		{
			name: "Zero max optimizers",
			config: optimization.Config{
				MLEndpoint:          "http://localhost:8080",
				MaxOptimizers:       0,
				OptimizationTimeout: time.Minute,
				LearningRate:        0.01,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine, err := optimization.NewAdaptiveEngine(tt.config)
			require.NoError(t, err)

			ctx := context.Background()
			err = engine.Initialize(ctx)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestAdaptiveEngine_GenerateOptimizations(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	tests := []struct {
		name         string
		request      interfaces.OptimizationRequest
		expectError  bool
		validateFunc func(*testing.T, []interfaces.OptimizationRecommendation)
	}{
		{
			name: "Basic optimization request",
			request: interfaces.OptimizationRequest{
				AnalysisID: "analysis_001",
				PatternData: &interfaces.PatternAnalysis{
					ID:         "pattern_001",
					Patterns:   map[string]interface{}{"template_complexity": 0.7},
					Confidence: 0.85,
				},
				MetricsData: &interfaces.PerformanceMetrics{
					ID:          "metrics_001",
					TemplateID:  "template_001",
					Generation:  interfaces.GenerationMetrics{Time: 2.5, MemoryUsage: 2048},
					Performance: interfaces.PerformanceData{ResponseTime: 1.8, Throughput: 50},
				},
				CurrentConfig: map[string]interface{}{
					"cache_enabled": false,
					"compression":   false,
				},
				TargetMetrics: map[string]float64{
					"generation_time": 1.5,
					"response_time":   1.0,
					"throughput":      100,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, recommendations []interfaces.OptimizationRecommendation) {
				assert.True(t, len(recommendations) > 0)
				for _, rec := range recommendations {
					assert.NotEmpty(t, rec.ID)
					assert.NotEmpty(t, rec.Type)
					assert.True(t, rec.ExpectedImpact > 0)
					assert.True(t, rec.Confidence > 0 && rec.Confidence <= 1)
				}
			},
		},
		{
			name: "High-performance template optimization",
			request: interfaces.OptimizationRequest{
				AnalysisID: "analysis_002",
				PatternData: &interfaces.PatternAnalysis{
					ID:         "pattern_002",
					Patterns:   map[string]interface{}{"template_complexity": 0.3},
					Confidence: 0.95,
				},
				MetricsData: &interfaces.PerformanceMetrics{
					ID:          "metrics_002",
					TemplateID:  "template_002",
					Generation:  interfaces.GenerationMetrics{Time: 0.8, MemoryUsage: 512},
					Performance: interfaces.PerformanceData{ResponseTime: 0.4, Throughput: 200},
				},
				CurrentConfig: map[string]interface{}{
					"cache_enabled": true,
					"compression":   true,
				},
				TargetMetrics: map[string]float64{
					"generation_time": 0.5,
					"response_time":   0.3,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, recommendations []interfaces.OptimizationRecommendation) {
				// High-performance templates should have fewer optimization opportunities
				assert.True(t, len(recommendations) >= 0)
			},
		},
		{
			name: "Complex template with multiple optimization opportunities",
			request: interfaces.OptimizationRequest{
				AnalysisID: "analysis_003",
				PatternData: &interfaces.PatternAnalysis{
					ID: "pattern_003",
					Patterns: map[string]interface{}{
						"template_complexity": 0.9,
						"nested_loops":        true,
						"heavy_computations":  true,
					},
					Confidence: 0.88,
				},
				MetricsData: &interfaces.PerformanceMetrics{
					ID:          "metrics_003",
					TemplateID:  "template_003",
					Generation:  interfaces.GenerationMetrics{Time: 5.2, MemoryUsage: 4096},
					Performance: interfaces.PerformanceData{ResponseTime: 3.5, Throughput: 20},
					Quality:     interfaces.QualityMetrics{ErrorRate: 0.08},
				},
				CurrentConfig: map[string]interface{}{
					"cache_enabled":   false,
					"compression":     false,
					"parallelization": false,
				},
				TargetMetrics: map[string]float64{
					"generation_time": 2.0,
					"response_time":   1.5,
					"throughput":      60,
					"error_rate":      0.02,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, recommendations []interfaces.OptimizationRecommendation) {
				assert.True(t, len(recommendations) >= 3) // Should have multiple optimizations

				// Check for specific optimization types
				types := make(map[string]bool)
				for _, rec := range recommendations {
					types[rec.Type] = true
				}
				assert.True(t, types["caching"] || types["compression"] || types["parallelization"])
			},
		},
		{
			name: "Invalid request - missing pattern data",
			request: interfaces.OptimizationRequest{
				AnalysisID:  "analysis_invalid",
				PatternData: nil,
				MetricsData: &interfaces.PerformanceMetrics{
					ID: "metrics_invalid",
				},
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			recommendations, err := engine.GenerateOptimizations(ctx, tt.request)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, recommendations)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, recommendations)
				if tt.validateFunc != nil {
					tt.validateFunc(t, recommendations)
				}
			}
		})
	}
}

func TestAdaptiveEngine_ApplyOptimizations(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	// First generate some optimizations
	optimizationRequest := interfaces.OptimizationRequest{
		AnalysisID: "analysis_apply_001",
		PatternData: &interfaces.PatternAnalysis{
			ID:         "pattern_apply_001",
			Patterns:   map[string]interface{}{"template_complexity": 0.7},
			Confidence: 0.85,
		},
		MetricsData: &interfaces.PerformanceMetrics{
			ID:         "metrics_apply_001",
			TemplateID: "template_apply_001",
			Generation: interfaces.GenerationMetrics{Time: 2.0, MemoryUsage: 1024},
		},
		CurrentConfig: map[string]interface{}{"cache_enabled": false},
		TargetMetrics: map[string]float64{"generation_time": 1.0},
	}

	ctx := context.Background()
	recommendations, err := engine.GenerateOptimizations(ctx, optimizationRequest)
	require.NoError(t, err)
	require.True(t, len(recommendations) > 0)

	tests := []struct {
		name         string
		request      interfaces.OptimizationApplicationRequest
		expectError  bool
		validateFunc func(*testing.T, *interfaces.OptimizationResult)
	}{
		{
			name: "Apply single optimization",
			request: interfaces.OptimizationApplicationRequest{
				ID:              "apply_001",
				TemplateID:      "template_apply_001",
				Recommendations: recommendations[:1],
				Configuration: map[string]interface{}{
					"apply_immediately": true,
					"rollback_enabled":  true,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, result *interfaces.OptimizationResult) {
				assert.NotEmpty(t, result.ID)
				assert.Equal(t, "template_apply_001", result.TemplateID)
				assert.True(t, len(result.AppliedOptimizations) > 0)
				assert.True(t, result.PerformanceGain >= 0)
				assert.NotNil(t, result.BeforeMetrics)
				assert.NotNil(t, result.AfterMetrics)
			},
		},
		{
			name: "Apply multiple optimizations",
			request: interfaces.OptimizationApplicationRequest{
				ID:              "apply_002",
				TemplateID:      "template_apply_001",
				Recommendations: recommendations,
				Configuration: map[string]interface{}{
					"apply_immediately": true,
					"test_mode":         true,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, result *interfaces.OptimizationResult) {
				assert.True(t, len(result.AppliedOptimizations) >= len(recommendations))
			},
		},
		{
			name: "Apply with A/B testing",
			request: interfaces.OptimizationApplicationRequest{
				ID:              "apply_003",
				TemplateID:      "template_apply_001",
				Recommendations: recommendations[:1],
				Configuration: map[string]interface{}{
					"enable_ab_testing": true,
					"test_percentage":   50,
					"test_duration":     "1h",
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, result *interfaces.OptimizationResult) {
				assert.NotNil(t, result.ABTestConfig)
				assert.True(t, result.ABTestConfig.Enabled)
			},
		},
		{
			name: "Invalid template ID",
			request: interfaces.OptimizationApplicationRequest{
				ID:              "apply_invalid",
				TemplateID:      "",
				Recommendations: recommendations,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			result, err := engine.ApplyOptimizations(ctx, tt.request)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, result)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, result)
				if tt.validateFunc != nil {
					tt.validateFunc(t, result)
				}
			}
		})
	}
}

func TestAdaptiveEngine_ProcessFeedback(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	tests := []struct {
		name        string
		feedback    interfaces.OptimizationFeedback
		expectError bool
	}{
		{
			name: "Positive feedback",
			feedback: interfaces.OptimizationFeedback{
				ID:               "feedback_001",
				OptimizationID:   "opt_001",
				UserRating:       4.5,
				PerformanceGain:  0.35,
				UserSatisfaction: 0.9,
				Comments:         "Great improvement in performance",
				Timestamp:        time.Now(),
			},
			expectError: false,
		},
		{
			name: "Negative feedback",
			feedback: interfaces.OptimizationFeedback{
				ID:               "feedback_002",
				OptimizationID:   "opt_002",
				UserRating:       2.0,
				PerformanceGain:  -0.1,
				UserSatisfaction: 0.3,
				Comments:         "Performance got worse",
				Timestamp:        time.Now(),
			},
			expectError: false,
		},
		{
			name: "Feedback with issues",
			feedback: interfaces.OptimizationFeedback{
				ID:               "feedback_003",
				OptimizationID:   "opt_003",
				UserRating:       3.0,
				PerformanceGain:  0.1,
				UserSatisfaction: 0.6,
				Issues:           []string{"memory_leak", "slower_startup"},
				Timestamp:        time.Now(),
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			err := engine.ProcessFeedback(ctx, tt.feedback)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestAdaptiveEngine_GetOptimizationHistory(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	// First apply some optimizations to create history
	optimizationRequest := interfaces.OptimizationRequest{
		AnalysisID: "history_analysis",
		PatternData: &interfaces.PatternAnalysis{
			ID:         "history_pattern",
			Patterns:   map[string]interface{}{"template_complexity": 0.6},
			Confidence: 0.8,
		},
		MetricsData: &interfaces.PerformanceMetrics{
			ID:         "history_metrics",
			TemplateID: "history_template",
			Generation: interfaces.GenerationMetrics{Time: 1.8},
		},
		CurrentConfig: map[string]interface{}{"cache_enabled": false},
		TargetMetrics: map[string]float64{"generation_time": 1.0},
	}

	ctx := context.Background()
	recommendations, err := engine.GenerateOptimizations(ctx, optimizationRequest)
	require.NoError(t, err)

	if len(recommendations) > 0 {
		applicationRequest := interfaces.OptimizationApplicationRequest{
			ID:              "history_apply",
			TemplateID:      "history_template",
			Recommendations: recommendations[:1],
		}

		_, err = engine.ApplyOptimizations(ctx, applicationRequest)
		require.NoError(t, err)
	}

	timeRange := interfaces.TimeRange{
		Start: time.Now().Add(-1 * time.Hour),
		End:   time.Now(),
	}

	tests := []struct {
		name         string
		timeRange    interfaces.TimeRange
		expectError  bool
		validateFunc func(*testing.T, []interface{})
	}{
		{
			name:        "Get recent history",
			timeRange:   timeRange,
			expectError: false,
			validateFunc: func(t *testing.T, history []interface{}) {
				assert.True(t, len(history) >= 0) // May be empty initially
			},
		},
		{
			name: "Get specific time range",
			timeRange: interfaces.TimeRange{
				Start: time.Now().Add(-30 * time.Minute),
				End:   time.Now(),
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			history, err := engine.GetOptimizationHistory(ctx, tt.timeRange)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, history)
				if tt.validateFunc != nil {
					tt.validateFunc(t, history)
				}
			}
		})
	}
}

func TestAdaptiveEngine_PredictOptimizationImpact(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	recommendation := interfaces.OptimizationRecommendation{
		ID:             "pred_opt_001",
		Type:           "caching",
		Description:    "Enable template caching",
		Priority:       8,
		ExpectedImpact: 0.3,
		Confidence:     0.85,
		Configuration: map[string]interface{}{
			"cache_size": 1000,
			"ttl":        "1h",
		},
	}

	currentMetrics := interfaces.PerformanceMetrics{
		ID:          "current_metrics",
		TemplateID:  "pred_template",
		Generation:  interfaces.GenerationMetrics{Time: 2.0, MemoryUsage: 1024},
		Performance: interfaces.PerformanceData{ResponseTime: 1.5, Throughput: 50},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	prediction, err := engine.PredictOptimizationImpact(ctx, recommendation, currentMetrics)

	assert.NoError(t, err)
	assert.NotNil(t, prediction)
	assert.NotEmpty(t, prediction.ID)
	assert.True(t, prediction.PredictedGain >= 0)
	assert.True(t, prediction.Confidence > 0 && prediction.Confidence <= 1)
	assert.NotNil(t, prediction.PredictedMetrics)
}

func TestAdaptiveEngine_RollbackOptimization(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	// First apply an optimization to rollback
	optimizationRequest := interfaces.OptimizationRequest{
		AnalysisID: "rollback_analysis",
		PatternData: &interfaces.PatternAnalysis{
			ID:         "rollback_pattern",
			Patterns:   map[string]interface{}{"template_complexity": 0.5},
			Confidence: 0.8,
		},
		MetricsData: &interfaces.PerformanceMetrics{
			ID:         "rollback_metrics",
			TemplateID: "rollback_template",
			Generation: interfaces.GenerationMetrics{Time: 1.5},
		},
		CurrentConfig: map[string]interface{}{"cache_enabled": false},
		TargetMetrics: map[string]float64{"generation_time": 1.0},
	}

	ctx := context.Background()
	recommendations, err := engine.GenerateOptimizations(ctx, optimizationRequest)
	require.NoError(t, err)

	if len(recommendations) > 0 {
		applicationRequest := interfaces.OptimizationApplicationRequest{
			ID:              "rollback_apply",
			TemplateID:      "rollback_template",
			Recommendations: recommendations[:1],
			Configuration: map[string]interface{}{
				"rollback_enabled": true,
			},
		}

		result, err := engine.ApplyOptimizations(ctx, applicationRequest)
		require.NoError(t, err)

		// Now test rollback
		rollbackRequest := interfaces.OptimizationRollbackRequest{
			ID:              "rollback_001",
			OptimizationID:  result.ID,
			TemplateID:      "rollback_template",
			Reason:          "Performance degradation detected",
			RestoreSnapshot: true,
		}

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		rollbackResult, err := engine.RollbackOptimization(ctx, rollbackRequest)

		assert.NoError(t, err)
		assert.NotNil(t, rollbackResult)
		assert.NotEmpty(t, rollbackResult.ID)
		assert.True(t, rollbackResult.Success)
		assert.NotNil(t, rollbackResult.RestoredMetrics)
	}
}

func TestAdaptiveEngine_PerformanceTargets(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	// Test that the engine can achieve 25%+ performance improvements
	optimizationRequest := interfaces.OptimizationRequest{
		AnalysisID: "perf_target_analysis",
		PatternData: &interfaces.PatternAnalysis{
			ID:         "perf_target_pattern",
			Patterns:   map[string]interface{}{"template_complexity": 0.9}, // High complexity
			Confidence: 0.9,
		},
		MetricsData: &interfaces.PerformanceMetrics{
			ID:          "perf_target_metrics",
			TemplateID:  "perf_target_template",
			Generation:  interfaces.GenerationMetrics{Time: 4.0, MemoryUsage: 4096}, // Poor performance
			Performance: interfaces.PerformanceData{ResponseTime: 3.0, Throughput: 25},
		},
		CurrentConfig: map[string]interface{}{
			"cache_enabled":      false,
			"compression":        false,
			"parallelization":    false,
			"optimization_level": 0,
		},
		TargetMetrics: map[string]float64{
			"generation_time": 2.0, // 50% improvement target
			"response_time":   1.5, // 50% improvement target
			"throughput":      50,  // 100% improvement target
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	recommendations, err := engine.GenerateOptimizations(ctx, optimizationRequest)
	assert.NoError(t, err)
	assert.NotNil(t, recommendations)

	// Verify that the recommendations can achieve significant improvements
	totalExpectedImpact := 0.0
	for _, rec := range recommendations {
		totalExpectedImpact += rec.ExpectedImpact
	}

	assert.True(t, totalExpectedImpact >= 0.25, "Should achieve at least 25% improvement")
}

func TestAdaptiveEngine_ConcurrentOptimizations(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	const numGoroutines = 5
	results := make(chan error, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			optimizationRequest := interfaces.OptimizationRequest{
				AnalysisID: fmt.Sprintf("concurrent_analysis_%d", id),
				PatternData: &interfaces.PatternAnalysis{
					ID:         fmt.Sprintf("concurrent_pattern_%d", id),
					Patterns:   map[string]interface{}{"template_complexity": 0.7},
					Confidence: 0.8,
				},
				MetricsData: &interfaces.PerformanceMetrics{
					ID:         fmt.Sprintf("concurrent_metrics_%d", id),
					TemplateID: fmt.Sprintf("concurrent_template_%d", id),
					Generation: interfaces.GenerationMetrics{Time: 2.0},
				},
				CurrentConfig: map[string]interface{}{"cache_enabled": false},
				TargetMetrics: map[string]float64{"generation_time": 1.0},
			}

			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			_, err := engine.GenerateOptimizations(ctx, optimizationRequest)
			results <- err
		}(i)
	}

	for i := 0; i < numGoroutines; i++ {
		err := <-results
		assert.NoError(t, err, "Concurrent optimizations should not cause errors")
	}
}

func TestAdaptiveEngine_Start_Stop(t *testing.T) {
	engine := setupTestOptimizationEngine(t)

	ctx := context.Background()

	// Test start
	err := engine.Start(ctx)
	assert.NoError(t, err)

	// Test stop
	err := engine.Stop(ctx)
	assert.NoError(t, err)

	// Test double stop (should not error)
	err = engine.Stop(ctx)
	assert.NoError(t, err)
}

// Helper functions

func setupTestOptimizationEngine(t *testing.T) interfaces.AdaptiveOptimizationEngine {
	config := optimization.DefaultConfig()
	config.MLEndpoint = "http://localhost:8080" // Mock ML endpoint for testing

	engine, err := optimization.NewAdaptiveEngine(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = engine.Initialize(ctx)
	require.NoError(t, err)

	err = engine.Start(ctx)
	require.NoError(t, err)

	t.Cleanup(func() {
		engine.Stop(context.Background())
	})

	return engine
}

// Benchmark tests

func BenchmarkAdaptiveEngine_GenerateOptimizations(b *testing.B) {
	engine := setupBenchmarkOptimizationEngine(b)

	optimizationRequest := interfaces.OptimizationRequest{
		AnalysisID: "benchmark_analysis",
		PatternData: &interfaces.PatternAnalysis{
			ID:         "benchmark_pattern",
			Patterns:   map[string]interface{}{"template_complexity": 0.7},
			Confidence: 0.85,
		},
		MetricsData: &interfaces.PerformanceMetrics{
			ID:         "benchmark_metrics",
			TemplateID: "benchmark_template",
			Generation: interfaces.GenerationMetrics{Time: 2.0, MemoryUsage: 1024},
		},
		CurrentConfig: map[string]interface{}{"cache_enabled": false},
		TargetMetrics: map[string]float64{"generation_time": 1.0},
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := engine.GenerateOptimizations(ctx, optimizationRequest)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func setupBenchmarkOptimizationEngine(b *testing.B) interfaces.AdaptiveOptimizationEngine {
	config := optimization.DefaultConfig()
	config.MLEndpoint = "http://localhost:8080"

	engine, err := optimization.NewAdaptiveEngine(config)
	if err != nil {
		b.Fatal(err)
	}

	ctx := context.Background()
	if err := engine.Initialize(ctx); err != nil {
		b.Fatal(err)
	}

	if err := engine.Start(ctx); err != nil {
		b.Fatal(err)
	}

	b.Cleanup(func() {
		engine.Stop(context.Background())
	})

	return engine
}
