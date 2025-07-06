package neural

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/gerivdb/email-sender-1/development/managers/template-performance-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/template-performance-manager/internal/neural"
)

func TestNeuralProcessor_Initialize(t *testing.T) {
	tests := []struct {
		name        string
		config      neural.Config
		expectError bool
	}{
		{
			name:        "Valid configuration",
			config:      neural.DefaultConfig(),
			expectError: false,
		},
		{
			name: "Invalid AI endpoint",
			config: neural.Config{
				AIEndpoint:           "",
				MaxPatternComplexity: 100,
				AnalysisTimeout:      time.Minute,
				CacheSize:            1000,
			},
			expectError: true,
		},
		{
			name: "Zero cache size",
			config: neural.Config{
				AIEndpoint:           "http://localhost:8080",
				MaxPatternComplexity: 100,
				AnalysisTimeout:      time.Minute,
				CacheSize:            0,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			processor, err := neural.NewProcessor(tt.config)
			require.NoError(t, err)

			ctx := context.Background()
			err = processor.Initialize(ctx)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestNeuralProcessor_AnalyzeTemplatePatterns(t *testing.T) {
	processor := setupTestProcessor(t)

	tests := []struct {
		name         string
		templateData interfaces.TemplateData
		expectError  bool
		validateFunc func(*testing.T, *interfaces.PatternAnalysis)
	}{
		{
			name: "Valid template data",
			templateData: interfaces.TemplateData{
				TemplateID:  "template_001",
				Content:     "Hello {{.Name}}, your order {{.OrderID}} is ready!",
				Variables:   map[string]interface{}{"Name": "John", "OrderID": "12345"},
				Metadata:    map[string]interface{}{"category": "order_notification"},
				GeneratedAt: time.Now(),
			},
			expectError: false,
			validateFunc: func(t *testing.T, analysis *interfaces.PatternAnalysis) {
				assert.NotEmpty(t, analysis.ID)
				assert.NotEmpty(t, analysis.Patterns)
				assert.True(t, analysis.Confidence > 0)
				assert.True(t, analysis.ProcessingTime < 100*time.Millisecond)
			},
		},
		{
			name: "Empty template content",
			templateData: interfaces.TemplateData{
				TemplateID:  "template_002",
				Content:     "",
				Variables:   map[string]interface{}{},
				GeneratedAt: time.Now(),
			},
			expectError: true,
		},
		{
			name: "Complex template with loops",
			templateData: interfaces.TemplateData{
				TemplateID: "template_003",
				Content:    "{{range .Items}}Item: {{.Name}} - Price: {{.Price}}{{end}}",
				Variables: map[string]interface{}{
					"Items": []map[string]interface{}{
						{"Name": "Product A", "Price": 29.99},
						{"Name": "Product B", "Price": 49.99},
					},
				},
				GeneratedAt: time.Now(),
			},
			expectError: false,
			validateFunc: func(t *testing.T, analysis *interfaces.PatternAnalysis) {
				assert.Contains(t, analysis.Patterns, "loop_pattern")
				assert.True(t, analysis.Complexity > 0.5)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			analysis, err := processor.AnalyzeTemplatePatterns(ctx, tt.templateData)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, analysis)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, analysis)
				if tt.validateFunc != nil {
					tt.validateFunc(t, analysis)
				}
			}
		})
	}
}

func TestNeuralProcessor_ExtractUsagePatterns(t *testing.T) {
	processor := setupTestProcessor(t)

	sessionData := []interfaces.SessionData{
		{
			SessionID:   "session_001",
			UserID:      "user_001",
			TemplateID:  "template_001",
			StartTime:   time.Now().Add(-10 * time.Minute),
			EndTime:     time.Now().Add(-5 * time.Minute),
			Actions:     []string{"view", "edit", "generate"},
			Performance: map[string]float64{"generation_time": 1.5, "load_time": 0.3},
		},
		{
			SessionID:   "session_002",
			UserID:      "user_002",
			TemplateID:  "template_001",
			StartTime:   time.Now().Add(-8 * time.Minute),
			EndTime:     time.Now().Add(-3 * time.Minute),
			Actions:     []string{"view", "generate"},
			Performance: map[string]float64{"generation_time": 2.1, "load_time": 0.4},
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	patterns, err := processor.ExtractUsagePatterns(ctx, sessionData)

	assert.NoError(t, err)
	assert.NotNil(t, patterns)
	assert.NotEmpty(t, patterns.ID)
	assert.True(t, len(patterns.UsagePatterns) > 0)
	assert.True(t, patterns.UserBehaviorInsights != nil)
	assert.True(t, patterns.Confidence > 0)
}

func TestNeuralProcessor_CorrelatePerformanceMetrics(t *testing.T) {
	processor := setupTestProcessor(t)

	templateData := []interfaces.TemplateData{
		{
			TemplateID:  "template_001",
			Content:     "Simple template: {{.Message}}",
			Variables:   map[string]interface{}{"Message": "Hello"},
			GeneratedAt: time.Now(),
		},
	}

	metricsData := []interfaces.PerformanceMetrics{
		{
			ID:          "metrics_001",
			TemplateID:  "template_001",
			Timestamp:   time.Now(),
			Generation:  interfaces.GenerationMetrics{Time: 1.5, MemoryUsage: 1024},
			Performance: interfaces.PerformanceData{ResponseTime: 0.8, Throughput: 100},
			Quality:     interfaces.QualityMetrics{AccuracyScore: 0.95, ErrorRate: 0.02},
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	correlations, err := processor.CorrelatePerformanceMetrics(ctx, templateData, metricsData)

	assert.NoError(t, err)
	assert.NotNil(t, correlations)
	assert.NotEmpty(t, correlations.ID)
	assert.True(t, len(correlations.Correlations) > 0)
	assert.True(t, correlations.ConfidenceScore > 0)
}

func TestNeuralProcessor_GetInsights(t *testing.T) {
	processor := setupTestProcessor(t)

	timeRange := interfaces.TimeRange{
		Start: time.Now().Add(-24 * time.Hour),
		End:   time.Now(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	insights, err := processor.GetInsights(ctx, timeRange)

	assert.NoError(t, err)
	assert.NotNil(t, insights)
	assert.True(t, len(insights) >= 0) // May be empty for new systems
}

func TestNeuralProcessor_PredictPerformance(t *testing.T) {
	processor := setupTestProcessor(t)

	templateConfig := interfaces.TemplateConfig{
		ID:           "config_001",
		Type:         "email_notification",
		Complexity:   0.7,
		Variables:    []string{"name", "order_id", "items"},
		CacheEnabled: true,
		Optimizations: map[string]interface{}{
			"compression":  true,
			"minification": true,
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	prediction, err := processor.PredictPerformance(ctx, templateConfig)

	assert.NoError(t, err)
	assert.NotNil(t, prediction)
	assert.NotEmpty(t, prediction.ID)
	assert.True(t, prediction.PredictedMetrics.Generation.Time > 0)
	assert.True(t, prediction.ConfidenceLevel > 0 && prediction.ConfidenceLevel <= 1)
}

func TestNeuralProcessor_LearnFromFeedback(t *testing.T) {
	processor := setupTestProcessor(t)

	feedback := interfaces.FeedbackData{
		ID:           "feedback_001",
		AnalysisID:   "analysis_001",
		UserRating:   4.5,
		Accuracy:     0.92,
		Usefulness:   0.88,
		Comments:     "Very helpful analysis",
		Timestamp:    time.Now(),
		Improvements: []string{"faster_processing", "better_recommendations"},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := processor.LearnFromFeedback(ctx, feedback)

	assert.NoError(t, err)
}

func TestNeuralProcessor_PerformanceConstraints(t *testing.T) {
	processor := setupTestProcessor(t)

	templateData := interfaces.TemplateData{
		TemplateID:  "perf_test_001",
		Content:     "Performance test template: {{.Data}}",
		Variables:   map[string]interface{}{"Data": "test_data"},
		GeneratedAt: time.Now(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	start := time.Now()
	analysis, err := processor.AnalyzeTemplatePatterns(ctx, templateData)
	duration := time.Since(start)

	assert.NoError(t, err)
	assert.NotNil(t, analysis)
	assert.True(t, duration < 100*time.Millisecond, "Analysis should complete within 100ms constraint")
}

func TestNeuralProcessor_ConcurrentAccess(t *testing.T) {
	processor := setupTestProcessor(t)

	const numGoroutines = 10
	results := make(chan error, numGoroutines)

	templateData := interfaces.TemplateData{
		TemplateID:  "concurrent_test",
		Content:     "Concurrent access test: {{.ID}}",
		Variables:   map[string]interface{}{"ID": "test"},
		GeneratedAt: time.Now(),
	}

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			_, err := processor.AnalyzeTemplatePatterns(ctx, templateData)
			results <- err
		}(i)
	}

	for i := 0; i < numGoroutines; i++ {
		err := <-results
		assert.NoError(t, err, "Concurrent access should not cause errors")
	}
}

func TestNeuralProcessor_Start_Stop(t *testing.T) {
	processor := setupTestProcessor(t)

	ctx := context.Background()

	// Test start
	err := processor.Start(ctx)
	assert.NoError(t, err)

	// Test stop
	err = processor.Stop(ctx)
	assert.NoError(t, err)

	// Test double stop (should not error)
	err = processor.Stop(ctx)
	assert.NoError(t, err)
}

func TestNeuralProcessor_ContextCancellation(t *testing.T) {
	processor := setupTestProcessor(t)

	templateData := interfaces.TemplateData{
		TemplateID:  "cancel_test",
		Content:     "Context cancellation test: {{.Data}}",
		Variables:   map[string]interface{}{"Data": "test"},
		GeneratedAt: time.Now(),
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel() // Cancel immediately

	_, err := processor.AnalyzeTemplatePatterns(ctx, templateData)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "context canceled")
}

// Helper functions

func setupTestProcessor(t *testing.T) interfaces.NeuralPatternProcessor {
	config := neural.DefaultConfig()
	config.AIEndpoint = "http://localhost:8080" // Mock endpoint for testing

	processor, err := neural.NewProcessor(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = processor.Initialize(ctx)
	require.NoError(t, err)

	err = processor.Start(ctx)
	require.NoError(t, err)

	t.Cleanup(func() {
		processor.Stop(context.Background())
	})

	return processor
}

// Benchmark tests

func BenchmarkNeuralProcessor_AnalyzeTemplatePatterns(b *testing.B) {
	processor := setupBenchmarkProcessor(b)

	templateData := interfaces.TemplateData{
		TemplateID:  "benchmark_template",
		Content:     "Benchmark template: {{.Name}} - {{.Value}}",
		Variables:   map[string]interface{}{"Name": "Test", "Value": 12345},
		GeneratedAt: time.Now(),
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := processor.AnalyzeTemplatePatterns(ctx, templateData)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func setupBenchmarkProcessor(b *testing.B) interfaces.NeuralPatternProcessor {
	config := neural.DefaultConfig()
	config.AIEndpoint = "http://localhost:8080"

	processor, err := neural.NewProcessor(config)
	if err != nil {
		b.Fatal(err)
	}

	ctx := context.Background()
	if err := processor.Initialize(ctx); err != nil {
		b.Fatal(err)
	}

	if err := processor.Start(ctx); err != nil {
		b.Fatal(err)
	}

	b.Cleanup(func() {
		processor.Stop(context.Background())
	})

	return processor
}
