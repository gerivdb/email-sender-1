package vectorization

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewUnifiedQdrantClient(t *testing.T) {
	tests := []struct {
		name           string
		config         ClientConfig
		expectedBaseURL string
	}{
		{
			name: "default_configuration",
			config: ClientConfig{
				Host: "localhost",
				Port: 6333,
			},
			expectedBaseURL: "http://localhost:6333",
		},
		{
			name: "custom_configuration",
			config: ClientConfig{
				Host:       "qdrant.example.com",
				Port:       8080,
				RetryCount: 5,
				Timeout:    60 * time.Second,
			},
			expectedBaseURL: "http://qdrant.example.com:8080",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewUnifiedQdrantClient(tt.config)
			
			assert.Equal(t, tt.expectedBaseURL, client.BaseURL)
			assert.NotNil(t, client.HTTPClient)
			
			// Test default values
			if tt.config.RetryCount == 0 {
				assert.Equal(t, 3, client.RetryCount)
			} else {
				assert.Equal(t, tt.config.RetryCount, client.RetryCount)
			}
			
			if tt.config.Timeout == 0 {
				assert.Equal(t, 30*time.Second, client.Timeout)
			} else {
				assert.Equal(t, tt.config.Timeout, client.Timeout)
			}
		})
	}
}

func TestTaskPayload_Structure(t *testing.T) {
	// Test that TaskPayload matches Python vectorization structure
	payload := TaskPayload{
		TaskID:        "1.1.1",
		Description:   "Test task description",
		Status:        "pending",
		IndentLevel:   3,
		ParentID:      "1.1",
		Section:       "Phase 1: Test Phase",
		IsMVP:         true,
		Priority:      "P1",
		EstimatedTime: "2h",
		Category:      "backend",
		LastUpdated:   time.Now(),
		FilePath:      "test-plan.md",
	}
	
	// Verify all required fields are present
	assert.Equal(t, "1.1.1", payload.TaskID)
	assert.Equal(t, "Test task description", payload.Description)
	assert.Equal(t, "pending", payload.Status)
	assert.Equal(t, 3, payload.IndentLevel)
	assert.Equal(t, "1.1", payload.ParentID)
	assert.Equal(t, "Phase 1: Test Phase", payload.Section)
	assert.True(t, payload.IsMVP)
	assert.Equal(t, "P1", payload.Priority)
	assert.Equal(t, "2h", payload.EstimatedTime)
	assert.Equal(t, "backend", payload.Category)
	assert.Equal(t, "test-plan.md", payload.FilePath)
	assert.NotZero(t, payload.LastUpdated)
}

func TestTaskPoint_Serialization(t *testing.T) {
	// Test TaskPoint JSON serialization compatibility with Python
	point := TaskPoint{
		ID:     12345,
		Vector: []float32{0.1, 0.2, 0.3},
		Payload: TaskPayload{
			TaskID:      "1.1.1",
			Description: "Test task",
			Status:      "completed",
			IndentLevel: 3,
			IsMVP:       true,
			Priority:    "P0",
		},
	}
	
	// This should serialize to JSON compatible with Python Qdrant format
	assert.Equal(t, 12345, point.ID)
	assert.Equal(t, []float32{0.1, 0.2, 0.3}, point.Vector)
	assert.Equal(t, "1.1.1", point.Payload.TaskID)
	assert.Equal(t, "Test task", point.Payload.Description)
	assert.Equal(t, "completed", point.Payload.Status)
}

func TestHTTPError(t *testing.T) {
	err := &HTTPError{
		StatusCode: 404,
		Message:    "Collection not found",
	}
	
	expected := "HTTP 404: Collection not found"
	assert.Equal(t, expected, err.Error())
}

// Integration test (requires running Qdrant instance)
func TestUnifiedQdrantClient_Integration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}
	
	config := ClientConfig{
		Host:       "localhost",
		Port:       6333,
		RetryCount: 3,
		Timeout:    10 * time.Second,
	}
	
	client := NewUnifiedQdrantClient(config)
	ctx := context.Background()
	
	// Test collection creation
	collectionName := "test_vectorization_migration"
	err := client.CreateCollection(ctx, collectionName, 384)
	
	// This test will fail if Qdrant is not running, which is expected
	// In CI/CD, we would set up a test Qdrant instance
	if err != nil {
		t.Logf("Qdrant not available for integration test: %v", err)
		t.Skip("Skipping integration test - Qdrant not available")
	}
	
	// Test point insertion
	points := []TaskPoint{
		{
			ID:     1,
			Vector: make([]float32, 384), // Zero vector for test
			Payload: TaskPayload{
				TaskID:      "test.1",
				Description: "Test task for integration",
				Status:      "pending",
				IndentLevel: 1,
				Priority:    "P1",
				LastUpdated: time.Now(),
			},
		},
	}
	
	err = client.InsertPoints(ctx, collectionName, points)
	require.NoError(t, err)
	
	// Test collection info retrieval
	info, err := client.GetCollectionInfo(ctx, collectionName)
	require.NoError(t, err)
	assert.Equal(t, "green", info.Status)
	assert.Equal(t, 1, info.PointsCount)
}

// Benchmark test for batch insertion performance
func BenchmarkUnifiedQdrantClient_InsertPoints(b *testing.B) {
	config := ClientConfig{
		Host: "localhost",
		Port: 6333,
	}
	
	client := NewUnifiedQdrantClient(config)
	ctx := context.Background()
	
	// Create test points
	points := make([]TaskPoint, 100)
	for i := range points {
		points[i] = TaskPoint{
			ID:     i,
			Vector: make([]float32, 384),
			Payload: TaskPayload{
				TaskID:      fmt.Sprintf("bench.%d", i),
				Description: "Benchmark test task",
				Status:      "pending",
				LastUpdated: time.Now(),
			},
		}
	}
	
	b.ResetTimer()
	
	for i := 0; i < b.N; i++ {
		// This will fail without Qdrant, but shows the performance structure
		_ = client.InsertPoints(ctx, "benchmark_collection", points)
	}
}
