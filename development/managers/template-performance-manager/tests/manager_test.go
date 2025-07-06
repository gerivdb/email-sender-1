package template_performance_manager

import (
	"EMAIL_SENDER_1/development/managers/template-performance-manager/interfaces"
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
<<<<<<< HEAD
=======

	"github.com/gerivdb/email-sender-1/development/managers/template-performance-manager/interfaces"
>>>>>>> migration/gateway-manager-v77
)

func TestManager_Initialize(t *testing.T) {
	tests := []struct {
		name        string
		config      *Config
		expectError bool
	}{
		{
			name:        "Valid configuration",
			config:      DefaultConfig(),
			expectError: false,
		},
		{
			name:        "Nil configuration (should use default)",
			config:      nil,
			expectError: false,
		},
		{
			name: "Invalid configuration",
			config: &Config{
				MaxConcurrentAnalyses: -1,
				AnalysisTimeout:       0,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			manager, err := New(tt.config)
			require.NoError(t, err)

			ctx := context.Background()
			err = manager.Initialize(ctx)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)

				status := manager.GetManagerStatus()
				assert.True(t, status.IsInitialized)
				assert.False(t, status.IsRunning)
			}
		})
	}
}

func TestManager_StartStop(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()

	// Test start
	err := manager.Start(ctx)
	assert.NoError(t, err)

	status := manager.GetManagerStatus()
	assert.True(t, status.IsInitialized)
	assert.True(t, status.IsRunning)

	// Test double start (should error)
	err = manager.Start(ctx)
	assert.Error(t, err)

	// Test stop
	err = manager.Stop(ctx)
	assert.NoError(t, err)

	status = manager.GetManagerStatus()
	assert.True(t, status.IsInitialized)
	assert.False(t, status.IsRunning)

	// Test double stop (should not error)
	err = manager.Stop(ctx)
	assert.NoError(t, err)
}

func TestManager_AnalyzeTemplatePerformance(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	tests := []struct {
		name         string
		request      interfaces.AnalysisRequest
		expectError  bool
		validateFunc func(*testing.T, *interfaces.PerformanceAnalysis)
	}{
		{
			name: "Complete analysis request",
			request: interfaces.AnalysisRequest{
				ID: "analysis_complete_001",
				TemplateData: interfaces.TemplateData{
					TemplateID:  "template_001",
					Content:     "Hello {{.Name}}, your order {{.OrderID}} is ready!",
					Variables:   map[string]interface{}{"Name": "John", "OrderID": "12345"},
					Metadata:    map[string]interface{}{"category": "order_notification"},
					GeneratedAt: time.Now(),
				},
				SessionData: interfaces.SessionData{
					SessionID:   "session_001",
					UserID:      "user_001",
					TemplateID:  "template_001",
					StartTime:   time.Now().Add(-5 * time.Minute),
					EndTime:     time.Now(),
					Actions:     []string{"view", "edit", "generate"},
					Performance: map[string]float64{"generation_time": 1.5, "load_time": 0.3},
				},
				CurrentConfig: map[string]interface{}{
					"cache_enabled": false,
					"compression":   false,
				},
				TargetMetrics: map[string]float64{
					"generation_time": 1.0,
					"response_time":   0.8,
					"throughput":      100,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, analysis *interfaces.PerformanceAnalysis) {
				assert.NotEmpty(t, analysis.ID)
				assert.Equal(t, "completed", analysis.Status)
				assert.NotNil(t, analysis.PatternAnalysis)
				assert.NotNil(t, analysis.Metrics)
				assert.NotNil(t, analysis.Optimizations)
				assert.True(t, analysis.Duration > 0)
				assert.True(t, analysis.Duration < 30*time.Second) // Should complete within timeout
			},
		},
		{
			name: "Simple template analysis",
			request: interfaces.AnalysisRequest{
				ID: "analysis_simple_001",
				TemplateData: interfaces.TemplateData{
					TemplateID:  "simple_template",
					Content:     "Hello World!",
					Variables:   map[string]interface{}{},
					GeneratedAt: time.Now(),
				},
				SessionData: interfaces.SessionData{
					SessionID:  "simple_session",
					UserID:     "simple_user",
					TemplateID: "simple_template",
					StartTime:  time.Now().Add(-1 * time.Minute),
					EndTime:    time.Now(),
					Actions:    []string{"view"},
				},
				CurrentConfig: map[string]interface{}{},
				TargetMetrics: map[string]float64{"generation_time": 0.5},
			},
			expectError: false,
			validateFunc: func(t *testing.T, analysis *interfaces.PerformanceAnalysis) {
				assert.Equal(t, "completed", analysis.Status)
				assert.NotNil(t, analysis.PatternAnalysis)
				// Simple templates should have low complexity
				assert.True(t, analysis.PatternAnalysis.Complexity < 0.5)
			},
		},
		{
			name: "Complex template analysis",
			request: interfaces.AnalysisRequest{
				ID: "analysis_complex_001",
				TemplateData: interfaces.TemplateData{
					TemplateID: "complex_template",
					Content:    "{{range .Items}}{{if .IsActive}}Item: {{.Name}} - Price: {{.Price | printf \"%.2f\"}}{{end}}{{end}}",
					Variables: map[string]interface{}{
						"Items": []map[string]interface{}{
							{"Name": "Product A", "Price": 29.99, "IsActive": true},
							{"Name": "Product B", "Price": 49.99, "IsActive": false},
							{"Name": "Product C", "Price": 19.99, "IsActive": true},
						},
					},
					GeneratedAt: time.Now(),
				},
				SessionData: interfaces.SessionData{
					SessionID:   "complex_session",
					UserID:      "complex_user",
					TemplateID:  "complex_template",
					StartTime:   time.Now().Add(-10 * time.Minute),
					EndTime:     time.Now(),
					Actions:     []string{"view", "edit", "preview", "generate"},
					Performance: map[string]float64{"generation_time": 3.5, "load_time": 0.8},
				},
				CurrentConfig: map[string]interface{}{
					"cache_enabled":      false,
					"optimization_level": 0,
				},
				TargetMetrics: map[string]float64{
					"generation_time": 1.5,
					"response_time":   1.0,
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, analysis *interfaces.PerformanceAnalysis) {
				assert.Equal(t, "completed", analysis.Status)
				assert.NotNil(t, analysis.PatternAnalysis)
				// Complex templates should have higher complexity
				assert.True(t, analysis.PatternAnalysis.Complexity > 0.5)
				// Should have optimization recommendations
				assert.True(t, len(analysis.Optimizations) > 0)
			},
		},
		{
			name: "Invalid template data",
			request: interfaces.AnalysisRequest{
				ID: "analysis_invalid_001",
				TemplateData: interfaces.TemplateData{
					TemplateID:  "",
					Content:     "",
					Variables:   nil,
					GeneratedAt: time.Time{},
				},
				SessionData: interfaces.SessionData{},
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			analysis, err := manager.AnalyzeTemplatePerformance(ctx, tt.request)

			if tt.expectError {
				assert.Error(t, err)
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

func TestManager_GetPerformanceMetrics(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// First perform an analysis to generate some metrics
	analysisRequest := interfaces.AnalysisRequest{
		ID: "metrics_test_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID:  "metrics_template",
			Content:     "Test template for metrics",
			Variables:   map[string]interface{}{},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:  "metrics_session",
			UserID:     "metrics_user",
			TemplateID: "metrics_template",
			StartTime:  time.Now().Add(-5 * time.Minute),
			EndTime:    time.Now(),
			Actions:    []string{"view", "generate"},
		},
	}

	_, err = manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
	require.NoError(t, err)

	// Now test getting metrics
	filter := interfaces.MetricsFilter{
		TemplateID: "metrics_template",
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-1 * time.Hour),
			End:   time.Now(),
		},
	}

	metrics, err := manager.GetPerformanceMetrics(ctx, filter)
	assert.NoError(t, err)
	assert.NotNil(t, metrics)
}

func TestManager_ApplyOptimizations(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// First perform an analysis to get optimizations
	analysisRequest := interfaces.AnalysisRequest{
		ID: "optimization_test_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID:  "optimization_template",
			Content:     "{{range .Items}}Item: {{.Name}}{{end}}",
			Variables:   map[string]interface{}{"Items": []map[string]string{{"Name": "Test"}}},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:   "optimization_session",
			UserID:      "optimization_user",
			TemplateID:  "optimization_template",
			StartTime:   time.Now().Add(-5 * time.Minute),
			EndTime:     time.Now(),
			Actions:     []string{"view", "generate"},
			Performance: map[string]float64{"generation_time": 2.0},
		},
		CurrentConfig: map[string]interface{}{"cache_enabled": false},
		TargetMetrics: map[string]float64{"generation_time": 1.0},
	}

	analysis, err := manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
	require.NoError(t, err)
	require.True(t, len(analysis.Optimizations) > 0)

	// Apply optimizations
	applicationRequest := interfaces.OptimizationApplicationRequest{
		ID:              "apply_test_001",
		TemplateID:      "optimization_template",
		Recommendations: analysis.Optimizations,
		Configuration: map[string]interface{}{
			"apply_immediately": true,
			"rollback_enabled":  true,
		},
	}

	result, err := manager.ApplyOptimizations(ctx, applicationRequest)
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.NotEmpty(t, result.ID)
	assert.Equal(t, "optimization_template", result.TemplateID)
}

func TestManager_GenerateAnalyticsReport(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// Generate some activity first
	for i := 0; i < 3; i++ {
		analysisRequest := interfaces.AnalysisRequest{
			ID: fmt.Sprintf("report_analysis_%d", i),
			TemplateData: interfaces.TemplateData{
				TemplateID:  fmt.Sprintf("report_template_%d", i),
				Content:     fmt.Sprintf("Report template %d: {{.Data}}", i),
				Variables:   map[string]interface{}{"Data": fmt.Sprintf("data_%d", i)},
				GeneratedAt: time.Now(),
			},
			SessionData: interfaces.SessionData{
				SessionID:  fmt.Sprintf("report_session_%d", i),
				UserID:     fmt.Sprintf("report_user_%d", i),
				TemplateID: fmt.Sprintf("report_template_%d", i),
				StartTime:  time.Now().Add(-time.Duration(i+1) * 10 * time.Minute),
				EndTime:    time.Now().Add(-time.Duration(i) * 10 * time.Minute),
				Actions:    []string{"view", "generate"},
			},
		}

		_, err = manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
		require.NoError(t, err)
	}

	// Generate report
	reportRequest := interfaces.ReportRequest{
		ID: "test_report_001",
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-1 * time.Hour),
			End:   time.Now(),
		},
		Format:  "json",
		Options: map[string]interface{}{"include_raw_data": true},
	}

	report, err := manager.GenerateAnalyticsReport(ctx, reportRequest)
	assert.NoError(t, err)
	assert.NotNil(t, report)
	assert.NotEmpty(t, report.ID)
	assert.True(t, report.GeneratedAt.After(time.Now().Add(-1*time.Minute)))
	assert.NotNil(t, report.Summary)
}

func TestManager_ConcurrentAnalyses(t *testing.T) {
	manager := setupTestManager(t)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	const numConcurrent = 5
	results := make(chan error, numConcurrent)

	for i := 0; i < numConcurrent; i++ {
		go func(id int) {
			analysisRequest := interfaces.AnalysisRequest{
				ID: fmt.Sprintf("concurrent_analysis_%d", id),
				TemplateData: interfaces.TemplateData{
					TemplateID:  fmt.Sprintf("concurrent_template_%d", id),
					Content:     fmt.Sprintf("Concurrent template %d: {{.Data}}", id),
					Variables:   map[string]interface{}{"Data": fmt.Sprintf("data_%d", id)},
					GeneratedAt: time.Now(),
				},
				SessionData: interfaces.SessionData{
					SessionID:  fmt.Sprintf("concurrent_session_%d", id),
					UserID:     fmt.Sprintf("concurrent_user_%d", id),
					TemplateID: fmt.Sprintf("concurrent_template_%d", id),
					StartTime:  time.Now().Add(-5 * time.Minute),
					EndTime:    time.Now(),
					Actions:    []string{"view", "generate"},
				},
			}

			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			_, err := manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
			results <- err
		}(i)
	}

	for i := 0; i < numConcurrent; i++ {
		err := <-results
		assert.NoError(t, err, "Concurrent analyses should not cause errors")
	}
}

func TestManager_CallbackFunctionality(t *testing.T) {
	manager := setupTestManager(t)

	analysisCompleted := false
	optimizationApplied := false
	errorOccurred := false

	// Set callbacks
	manager.SetCallbacks(
		func(analysis *interfaces.PerformanceAnalysis) {
			analysisCompleted = true
			assert.NotNil(t, analysis)
		},
		func(result *interfaces.OptimizationResult) {
			optimizationApplied = true
			assert.NotNil(t, result)
		},
		func(err error) {
			errorOccurred = true
			assert.NotNil(t, err)
		},
	)

	ctx := context.Background()
	err := manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// Perform analysis to trigger callback
	analysisRequest := interfaces.AnalysisRequest{
		ID: "callback_test_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID:  "callback_template",
			Content:     "Callback test template",
			Variables:   map[string]interface{}{},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:  "callback_session",
			UserID:     "callback_user",
			TemplateID: "callback_template",
			StartTime:  time.Now().Add(-1 * time.Minute),
			EndTime:    time.Now(),
			Actions:    []string{"view"},
		},
	}

	_, err = manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
	assert.NoError(t, err)

	// Give time for callback to be called
	time.Sleep(100 * time.Millisecond)

	assert.True(t, analysisCompleted, "Analysis completion callback should be called")
}

func TestManager_MaxConcurrentAnalysesLimit(t *testing.T) {
	config := DefaultConfig()
	config.MaxConcurrentAnalyses = 2 // Set low limit for testing

	manager, err := New(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	err = manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// Start more analyses than the limit allows
	const numAnalyses = 5
	results := make(chan error, numAnalyses)

	for i := 0; i < numAnalyses; i++ {
		go func(id int) {
			analysisRequest := interfaces.AnalysisRequest{
				ID: fmt.Sprintf("limit_test_analysis_%d", id),
				TemplateData: interfaces.TemplateData{
					TemplateID:  fmt.Sprintf("limit_template_%d", id),
					Content:     "Limit test template",
					Variables:   map[string]interface{}{},
					GeneratedAt: time.Now(),
				},
				SessionData: interfaces.SessionData{
					SessionID:  fmt.Sprintf("limit_session_%d", id),
					UserID:     "limit_user",
					TemplateID: fmt.Sprintf("limit_template_%d", id),
					StartTime:  time.Now().Add(-1 * time.Minute),
					EndTime:    time.Now(),
					Actions:    []string{"view"},
				},
			}

			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			_, err := manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
			results <- err
		}(i)
	}

	// Check results - some should succeed, some should fail due to limit
	successCount := 0
	errorCount := 0

	for i := 0; i < numAnalyses; i++ {
		err := <-results
		if err != nil {
			errorCount++
		} else {
			successCount++
		}
	}

	// At least some should succeed and some should fail due to concurrent limit
	assert.True(t, successCount > 0, "Some analyses should succeed")
	assert.True(t, errorCount > 0, "Some analyses should fail due to concurrent limit")
}

func TestManager_RealTimeMode(t *testing.T) {
	config := DefaultConfig()
	config.EnableRealTimeMode = true

	manager, err := New(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	err = manager.Start(ctx)
	require.NoError(t, err)
	defer manager.Stop(ctx)

	// In real-time mode, the manager should start background monitoring
	status := manager.GetManagerStatus()
	assert.True(t, status.IsRunning)

	// Wait a bit to let real-time monitoring run
	time.Sleep(100 * time.Millisecond)

	// Status should be updated
	newStatus := manager.GetManagerStatus()
	assert.True(t, newStatus.LastUpdate.After(status.LastUpdate) || newStatus.LastUpdate.Equal(status.LastUpdate))
}

// Helper functions

func setupTestManager(t *testing.T) *Manager {
	config := DefaultConfig()
	// Use mock endpoints for testing
	config.AIEngineEndpoint = "http://localhost:8080"
	config.MetricsDBConnection = "postgres://localhost:5432/testdb"

	manager, err := New(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	t.Cleanup(func() {
		manager.Stop(context.Background())
	})

	return manager
}

// Benchmark tests

func BenchmarkManager_AnalyzeTemplatePerformance(b *testing.B) {
	manager := setupBenchmarkManager(b)

	ctx := context.Background()
	err := manager.Start(ctx)
	if err != nil {
		b.Fatal(err)
	}
	defer manager.Stop(ctx)

	analysisRequest := interfaces.AnalysisRequest{
		ID: "benchmark_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID:  "benchmark_template",
			Content:     "Benchmark template: {{.Name}} - {{.Value}}",
			Variables:   map[string]interface{}{"Name": "Test", "Value": 12345},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:  "benchmark_session",
			UserID:     "benchmark_user",
			TemplateID: "benchmark_template",
			StartTime:  time.Now().Add(-1 * time.Minute),
			EndTime:    time.Now(),
			Actions:    []string{"view", "generate"},
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		analysisRequest.ID = fmt.Sprintf("benchmark_analysis_%d", i)
		_, err := manager.AnalyzeTemplatePerformance(ctx, analysisRequest)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func setupBenchmarkManager(b *testing.B) *Manager {
	config := DefaultConfig()
	config.AIEngineEndpoint = "http://localhost:8080"
	config.MetricsDBConnection = "postgres://localhost:5432/benchmarkdb"

	manager, err := New(config)
	if err != nil {
		b.Fatal(err)
	}

	ctx := context.Background()
	if err := manager.Initialize(ctx); err != nil {
		b.Fatal(err)
	}

	b.Cleanup(func() {
		manager.Stop(context.Background())
	})

	return manager
}
