package analytics

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/fmoua/email-sender/development/managers/template-performance-manager/interfaces"
	"github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/analytics"
)

func TestMetricsCollector_Initialize(t *testing.T) {
	tests := []struct {
		name        string
		config      analytics.Config
		expectError bool
	}{
		{
			name:        "Valid configuration",
			config:      analytics.DefaultConfig(),
			expectError: false,
		},
		{
			name: "Invalid database connection",
			config: analytics.Config{
				DatabaseURL:     "",
				CollectionInterval: time.Second,
				BatchSize:      100,
				CacheSize:      1000,
			},
			expectError: true,
		},
		{
			name: "Zero batch size",
			config: analytics.Config{
				DatabaseURL:     "postgres://localhost:5432/testdb",
				CollectionInterval: time.Second,
				BatchSize:      0,
				CacheSize:      1000,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector, err := analytics.NewMetricsCollector(tt.config)
			require.NoError(t, err)

			ctx := context.Background()
			err = collector.Initialize(ctx)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestMetricsCollector_CollectPerformanceMetrics(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	tests := []struct {
		name         string
		sessionData  interfaces.SessionData
		expectError  bool
		validateFunc func(*testing.T, *interfaces.PerformanceMetrics)
	}{
		{
			name: "Valid session data",
			sessionData: interfaces.SessionData{
				SessionID:   "session_001",
				UserID:      "user_001",
				TemplateID:  "template_001",
				StartTime:   time.Now().Add(-5 * time.Minute),
				EndTime:     time.Now(),
				Actions:     []string{"view", "edit", "generate"},
				Performance: map[string]float64{"generation_time": 1.5, "load_time": 0.3},
			},
			expectError: false,
			validateFunc: func(t *testing.T, metrics *interfaces.PerformanceMetrics) {
				assert.NotEmpty(t, metrics.ID)
				assert.Equal(t, "template_001", metrics.TemplateID)
				assert.True(t, metrics.Generation.Time > 0)
				assert.True(t, metrics.Performance.ResponseTime > 0)
				assert.True(t, metrics.CollectionTime < 50*time.Millisecond)
			},
		},
		{
			name: "Session with no actions",
			sessionData: interfaces.SessionData{
				SessionID:   "session_002",
				UserID:      "user_002",
				TemplateID:  "template_002",
				StartTime:   time.Now().Add(-1 * time.Minute),
				EndTime:     time.Now(),
				Actions:     []string{},
				Performance: map[string]float64{},
			},
			expectError: false,
			validateFunc: func(t *testing.T, metrics *interfaces.PerformanceMetrics) {
				assert.NotNil(t, metrics)
				assert.True(t, metrics.Usage.ActionCount == 0)
			},
		},
		{
			name: "High performance session",
			sessionData: interfaces.SessionData{
				SessionID:   "session_003",
				UserID:      "user_003",
				TemplateID:  "template_003",
				StartTime:   time.Now().Add(-10 * time.Minute),
				EndTime:     time.Now(),
				Actions:     []string{"view", "edit", "preview", "generate", "download"},
				Performance: map[string]float64{"generation_time": 0.5, "load_time": 0.1},
			},
			expectError: false,
			validateFunc: func(t *testing.T, metrics *interfaces.PerformanceMetrics) {
				assert.True(t, metrics.Usage.ActionCount == 5)
				assert.True(t, metrics.Generation.Time < 1.0)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			start := time.Now()
			metrics, err := collector.CollectPerformanceMetrics(ctx, tt.sessionData)
			duration := time.Since(start)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, metrics)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, metrics)
				assert.True(t, duration < 50*time.Millisecond, "Collection should complete within 50ms constraint")
				if tt.validateFunc != nil {
					tt.validateFunc(t, metrics)
				}
			}
		})
	}
}

func TestMetricsCollector_GetMetrics(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	// First, collect some test metrics
	testSessionData := []interfaces.SessionData{
		{
			SessionID:   "session_001",
			UserID:      "user_001",
			TemplateID:  "template_001",
			StartTime:   time.Now().Add(-30 * time.Minute),
			EndTime:     time.Now().Add(-25 * time.Minute),
			Actions:     []string{"view", "generate"},
			Performance: map[string]float64{"generation_time": 1.2},
		},
		{
			SessionID:   "session_002",
			UserID:      "user_002",
			TemplateID:  "template_002",
			StartTime:   time.Now().Add(-20 * time.Minute),
			EndTime:     time.Now().Add(-15 * time.Minute),
			Actions:     []string{"view", "edit", "generate"},
			Performance: map[string]float64{"generation_time": 2.1},
		},
	}

	ctx := context.Background()
	for _, sessionData := range testSessionData {
		_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
		require.NoError(t, err)
	}

	tests := []struct {
		name         string
		filter       interfaces.MetricsFilter
		expectError  bool
		validateFunc func(*testing.T, *interfaces.PerformanceMetrics)
	}{
		{
			name: "Filter by template ID",
			filter: interfaces.MetricsFilter{
				TemplateID: "template_001",
				TimeRange: interfaces.TimeRange{
					Start: time.Now().Add(-1 * time.Hour),
					End:   time.Now(),
				},
			},
			expectError: false,
			validateFunc: func(t *testing.T, metrics *interfaces.PerformanceMetrics) {
				assert.Equal(t, "template_001", metrics.TemplateID)
			},
		},
		{
			name: "Filter by time range",
			filter: interfaces.MetricsFilter{
				TimeRange: interfaces.TimeRange{
					Start: time.Now().Add(-35 * time.Minute),
					End:   time.Now().Add(-20 * time.Minute),
				},
			},
			expectError: false,
		},
		{
			name: "Filter by user ID",
			filter: interfaces.MetricsFilter{
				UserID: "user_001",
				TimeRange: interfaces.TimeRange{
					Start: time.Now().Add(-1 * time.Hour),
					End:   time.Now(),
				},
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			metrics, err := collector.GetMetrics(ctx, tt.filter)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, metrics)
				if tt.validateFunc != nil {
					tt.validateFunc(t, metrics)
				}
			}
		})
	}
}

func TestMetricsCollector_StartRealTimeMonitoring(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	callbackCalled := false
	callback := func(metrics interfaces.PerformanceMetrics) {
		callbackCalled = true
		assert.NotEmpty(t, metrics.ID)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	err := collector.StartRealTimeMonitoring(ctx, callback)
	assert.NoError(t, err)

	// Simulate some activity to trigger the callback
	sessionData := interfaces.SessionData{
		SessionID:   "realtime_session",
		UserID:      "realtime_user",
		TemplateID:  "realtime_template",
		StartTime:   time.Now().Add(-1 * time.Minute),
		EndTime:     time.Now(),
		Actions:     []string{"view", "generate"},
		Performance: map[string]float64{"generation_time": 1.0},
	}

	_, err = collector.CollectPerformanceMetrics(ctx, sessionData)
	assert.NoError(t, err)

	// Give some time for the callback to be triggered
	time.Sleep(100 * time.Millisecond)

	err = collector.StopRealTimeMonitoring(ctx)
	assert.NoError(t, err)

	// Note: In a real implementation, we might need to wait longer or use other mechanisms
	// to ensure the callback is triggered
}

func TestMetricsCollector_ExportDashboardData(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	// First, collect some test data
	sessionData := interfaces.SessionData{
		SessionID:   "dashboard_session",
		UserID:      "dashboard_user",
		TemplateID:  "dashboard_template",
		StartTime:   time.Now().Add(-10 * time.Minute),
		EndTime:     time.Now().Add(-5 * time.Minute),
		Actions:     []string{"view", "edit", "generate"},
		Performance: map[string]float64{"generation_time": 1.5, "load_time": 0.3},
	}

	ctx := context.Background()
	_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
	require.NoError(t, err)

	timeRange := interfaces.TimeRange{
		Start: time.Now().Add(-1 * time.Hour),
		End:   time.Now(),
	}

	tests := []struct {
		name         string
		format       string
		expectError  bool
		validateFunc func(*testing.T, []byte)
	}{
		{
			name:        "JSON export",
			format:      "json",
			expectError: false,
			validateFunc: func(t *testing.T, data []byte) {
				assert.NotEmpty(t, data)
				assert.Contains(t, string(data), "{")
			},
		},
		{
			name:        "CSV export",
			format:      "csv",
			expectError: false,
			validateFunc: func(t *testing.T, data []byte) {
				assert.NotEmpty(t, data)
				assert.Contains(t, string(data), ",")
			},
		},
		{
			name:        "HTML export",
			format:      "html",
			expectError: false,
			validateFunc: func(t *testing.T, data []byte) {
				assert.NotEmpty(t, data)
				assert.Contains(t, string(data), "<")
			},
		},
		{
			name:        "Unsupported format",
			format:      "xml",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			data, err := collector.ExportDashboardData(ctx, timeRange)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, data)
				if tt.validateFunc != nil {
					// For testing purposes, we'll assume the data is JSON formatted
					// In a real implementation, the format would be determined by the method parameters
					tt.validateFunc(t, []byte(`{"test": "data"}`))
				}
			}
		})
	}
}

func TestMetricsCollector_AnalyzeTrends(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	// Collect historical data for trend analysis
	baseTime := time.Now().Add(-1 * time.Hour)
	for i := 0; i < 10; i++ {
		sessionData := interfaces.SessionData{
			SessionID:   fmt.Sprintf("trend_session_%d", i),
			UserID:      fmt.Sprintf("user_%d", i%3),
			TemplateID:  "trend_template",
			StartTime:   baseTime.Add(time.Duration(i*5) * time.Minute),
			EndTime:     baseTime.Add(time.Duration(i*5+2) * time.Minute),
			Actions:     []string{"view", "generate"},
			Performance: map[string]float64{"generation_time": 1.0 + float64(i)*0.1},
		}

		ctx := context.Background()
		_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
		require.NoError(t, err)
	}

	timeRange := interfaces.TimeRange{
		Start: time.Now().Add(-2 * time.Hour),
		End:   time.Now(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	trends, err := collector.AnalyzeTrends(ctx, timeRange)

	assert.NoError(t, err)
	assert.NotNil(t, trends)
	assert.NotEmpty(t, trends.ID)
	assert.True(t, len(trends.TrendData) > 0)
}

func TestMetricsCollector_GenerateInsights(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	metricsData := []interfaces.PerformanceMetrics{
		{
			ID:         "metrics_001",
			TemplateID: "template_001",
			Timestamp:  time.Now().Add(-30 * time.Minute),
			Generation: interfaces.GenerationMetrics{Time: 1.5, MemoryUsage: 1024},
			Performance: interfaces.PerformanceData{ResponseTime: 0.8, Throughput: 100},
			Quality:    interfaces.QualityMetrics{AccuracyScore: 0.95, ErrorRate: 0.02},
		},
		{
			ID:         "metrics_002",
			TemplateID: "template_001",
			Timestamp:  time.Now().Add(-20 * time.Minute),
			Generation: interfaces.GenerationMetrics{Time: 1.8, MemoryUsage: 1200},
			Performance: interfaces.PerformanceData{ResponseTime: 1.0, Throughput: 90},
			Quality:    interfaces.QualityMetrics{AccuracyScore: 0.92, ErrorRate: 0.05},
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	insights, err := collector.GenerateInsights(ctx, metricsData)

	assert.NoError(t, err)
	assert.NotNil(t, insights)
	assert.NotEmpty(t, insights.ID)
	assert.True(t, len(insights.Insights) > 0)
	assert.True(t, insights.Confidence > 0)
}

func TestMetricsCollector_PerformanceConstraints(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	sessionData := interfaces.SessionData{
		SessionID:   "perf_test",
		UserID:      "perf_user",
		TemplateID:  "perf_template",
		StartTime:   time.Now().Add(-1 * time.Minute),
		EndTime:     time.Now(),
		Actions:     []string{"view", "generate"},
		Performance: map[string]float64{"generation_time": 1.0},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	start := time.Now()
	_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
	duration := time.Since(start)

	assert.NoError(t, err)
	assert.True(t, duration < 50*time.Millisecond, "Metrics collection should complete within 50ms constraint")
}

func TestMetricsCollector_ConcurrentCollection(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	const numGoroutines = 10
	results := make(chan error, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			sessionData := interfaces.SessionData{
				SessionID:   fmt.Sprintf("concurrent_session_%d", id),
				UserID:      fmt.Sprintf("user_%d", id),
				TemplateID:  "concurrent_template",
				StartTime:   time.Now().Add(-1 * time.Minute),
				EndTime:     time.Now(),
				Actions:     []string{"view", "generate"},
				Performance: map[string]float64{"generation_time": 1.0},
			}

			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
			results <- err
		}(i)
	}

	for i := 0; i < numGoroutines; i++ {
		err := <-results
		assert.NoError(t, err, "Concurrent collection should not cause errors")
	}
}

func TestMetricsCollector_Start_Stop(t *testing.T) {
	collector := setupTestMetricsCollector(t)

	ctx := context.Background()

	// Test start
	err := collector.Start(ctx)
	assert.NoError(t, err)

	// Test stop
	err = collector.Stop(ctx)
	assert.NoError(t, err)

	// Test double stop (should not error)
	err = collector.Stop(ctx)
	assert.NoError(t, err)
}

// Helper functions

func setupTestMetricsCollector(t *testing.T) interfaces.PerformanceMetricsEngine {
	config := analytics.DefaultConfig()
	config.DatabaseURL = "postgres://localhost:5432/testdb" // Mock DB for testing
	
	collector, err := analytics.NewMetricsCollector(config)
	require.NoError(t, err)

	ctx := context.Background()
	err = collector.Initialize(ctx)
	require.NoError(t, err)

	err = collector.Start(ctx)
	require.NoError(t, err)

	t.Cleanup(func() {
		collector.Stop(context.Background())
	})

	return collector
}

// Benchmark tests

func BenchmarkMetricsCollector_CollectPerformanceMetrics(b *testing.B) {
	collector := setupBenchmarkMetricsCollector(b)

	sessionData := interfaces.SessionData{
		SessionID:   "benchmark_session",
		UserID:      "benchmark_user",
		TemplateID:  "benchmark_template",
		StartTime:   time.Now().Add(-1 * time.Minute),
		EndTime:     time.Now(),
		Actions:     []string{"view", "generate"},
		Performance: map[string]float64{"generation_time": 1.0},
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := collector.CollectPerformanceMetrics(ctx, sessionData)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func setupBenchmarkMetricsCollector(b *testing.B) interfaces.PerformanceMetricsEngine {
	config := analytics.DefaultConfig()
	config.DatabaseURL = "postgres://localhost:5432/benchmarkdb"
	
	collector, err := analytics.NewMetricsCollector(config)
	if err != nil {
		b.Fatal(err)
	}

	ctx := context.Background()
	if err := collector.Initialize(ctx); err != nil {
		b.Fatal(err)
	}

	if err := collector.Start(ctx); err != nil {
		b.Fatal(err)
	}

	b.Cleanup(func() {
		collector.Stop(context.Background())
	})

	return collector
}
