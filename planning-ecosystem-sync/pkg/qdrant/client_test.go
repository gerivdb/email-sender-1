package qdrant

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap/zaptest"
)

// TestUnifiedClient_Implementation verifies the unified client implements QdrantInterface
// Phase 2.1.1.1.1: Définir l'interface unifiée QdrantInterface
func TestUnifiedClient_Implementation(t *testing.T) {
	logger := zaptest.NewLogger(t)
	client, err := NewUnifiedClient("http://localhost:6333", logger)
	require.NoError(t, err)

	// Verify client implements QdrantInterface
	var _ QdrantInterface = client
	assert.NotNil(t, client)
}

// TestUnifiedClient_NewClient tests client creation
func TestUnifiedClient_NewClient(t *testing.T) {
	logger := zaptest.NewLogger(t)

	t.Run("ValidCreation", func(t *testing.T) {
		client, err := NewUnifiedClient("http://localhost:6333", logger)
		require.NoError(t, err)
		assert.NotNil(t, client)
		assert.Equal(t, "http://localhost:6333", client.baseURL)
		assert.Equal(t, 3, client.maxRetries)
		assert.Equal(t, time.Second, client.retryDelay)
	})

	t.Run("NilLogger", func(t *testing.T) {
		client, err := NewUnifiedClient("http://localhost:6333", nil)
		require.NoError(t, err)
		assert.NotNil(t, client.logger)
	})
}

// TestUnifiedClient_HealthCheck tests health check functionality
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func TestUnifiedClient_HealthCheck(t *testing.T) {
	t.Run("SuccessfulHealthCheck", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/health" && r.Method == "GET" {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"status": "ok"}`))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		err = client.HealthCheck(ctx)
		assert.NoError(t, err)

		// Check metrics were updated
		metrics := client.GetMetrics()
		assert.Equal(t, int64(1), metrics.RequestCount)
		assert.Equal(t, int64(0), metrics.ErrorCount)
	})

	t.Run("FailedHealthCheck", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		err = client.HealthCheck(ctx)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "health check failed with status: 500")
	})
}

// TestUnifiedClient_CreateCollection tests collection creation
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func TestUnifiedClient_CreateCollection(t *testing.T) {
	t.Run("SuccessfulCreation", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/collections/test_collection" && r.Method == "PUT" {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"result": true}`))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		config := CollectionConfig{
			VectorSize:    384,
			Distance:      "cosine",
			OnDiskPayload: false,
			ReplicaCount:  1,
			ShardNumber:   1,
		}

		err = client.CreateCollection(ctx, "test_collection", config)
		assert.NoError(t, err)
	})
}

// TestUnifiedClient_UpsertPoints tests point upsertion
// Phase 2.1.2.1.3: Optimiser les opérations batch (upsert massif)
func TestUnifiedClient_UpsertPoints(t *testing.T) {
	t.Run("EmptyPoints", func(t *testing.T) {
		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient("http://localhost:6333", logger)
		require.NoError(t, err)

		ctx := context.Background()
		err = client.UpsertPoints(ctx, "test_collection", []Point{})
		assert.NoError(t, err)
	})

	t.Run("BatchProcessing", func(t *testing.T) {
		requestCount := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/collections/test_collection/points" && r.Method == "PUT" {
				requestCount++
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"result": "ok"}`))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		// Create 150 points to test batching (should create 2 batches of 100 and 50)
		points := make([]Point, 150)
		for i := 0; i < 150; i++ {
			points[i] = Point{
				ID:     i,
				Vector: []float32{float32(i), float32(i + 1)},
				Payload: map[string]interface{}{
					"index": i,
				},
			}
		}

		ctx := context.Background()
		err = client.UpsertPoints(ctx, "test_collection", points)
		assert.NoError(t, err)
		assert.Equal(t, 2, requestCount) // Should have made 2 batch requests
	})
}

// TestUnifiedClient_SearchPoints tests vector search functionality
func TestUnifiedClient_SearchPoints(t *testing.T) {
	t.Run("SuccessfulSearch", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/collections/test_collection/points/search" && r.Method == "POST" {
				response := SearchResponse{
					Result: []ScoredPoint{
						{
							ID:     1,
							Score:  0.95,
							Vector: []float32{0.1, 0.2, 0.3},
							Payload: map[string]interface{}{
								"text": "test document",
							},
						},
					},
				}
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusOK)
				json.NewEncoder(w).Encode(response)
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		searchReq := SearchRequest{
			Vector:      []float32{0.1, 0.2, 0.3},
			Limit:       10,
			WithPayload: true,
			WithVector:  true,
		}

		response, err := client.SearchPoints(ctx, "test_collection", searchReq)
		require.NoError(t, err)
		assert.NotNil(t, response)
		assert.Len(t, response.Result, 1)
		assert.Equal(t, float32(0.95), response.Result[0].Score)
	})
}

// TestUnifiedClient_RetryLogic tests retry functionality with exponential backoff
// Phase 2.1.2.1.2: Ajouter retry logic avec backoff exponentiel
func TestUnifiedClient_RetryLogic(t *testing.T) {
	t.Run("RetryOnFailure", func(t *testing.T) {
		attemptCount := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			attemptCount++
			if attemptCount < 3 {
				w.WriteHeader(http.StatusInternalServerError)
			} else {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"status": "ok"}`))
			}
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		err = client.HealthCheck(ctx)
		assert.NoError(t, err)
		assert.Equal(t, 3, attemptCount) // Should have retried 2 times before success
	})

	t.Run("MaxRetriesExceeded", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
		}))
		defer server.Close()

		logger := zaptest.NewLogger(t)
		client, err := NewUnifiedClient(server.URL, logger)
		require.NoError(t, err)

		ctx := context.Background()
		err = client.HealthCheck(ctx)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "request failed after 3 retries")
	})
}

// TestUnifiedClient_Metrics tests metrics tracking
// Phase 2.1.2.2.1: Intégrer avec le système de métriques existant
func TestUnifiedClient_Metrics(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			w.WriteHeader(http.StatusOK)
		} else {
			w.WriteHeader(http.StatusInternalServerError)
		}
	}))
	defer server.Close()

	logger := zaptest.NewLogger(t)
	client, err := NewUnifiedClient(server.URL, logger)
	require.NoError(t, err)

	ctx := context.Background()

	// Make successful request
	err = client.HealthCheck(ctx)
	assert.NoError(t, err)

	// Make failing request
	err = client.executeWithRetry(ctx, "GET", server.URL+"/invalid", nil, nil)
	assert.Error(t, err)

	metrics := client.GetMetrics()
	assert.Greater(t, metrics.RequestCount, int64(0))
	assert.Greater(t, metrics.ErrorCount, int64(0))
	assert.Greater(t, metrics.AverageLatency, time.Duration(0))
	assert.False(t, metrics.LastRequest.IsZero())
}

// TestUnifiedClient_ConnectionPooling tests connection pooling functionality
// Phase 2.1.2.1.1: Implémenter connection pooling
func TestUnifiedClient_ConnectionPooling(t *testing.T) {
	logger := zaptest.NewLogger(t)
	client, err := NewUnifiedClient("http://localhost:6333", logger)
	require.NoError(t, err)

	// Verify connection pool is configured
	assert.NotNil(t, client.connPool)
	assert.Equal(t, 10, client.connPool.maxConns)
	assert.Equal(t, 30*time.Second, client.connPool.timeout)

	// Verify HTTP client uses the pooled transport
	transport, ok := client.httpClient.Transport.(*http.Transport)
	require.True(t, ok)
	assert.Equal(t, 10, transport.MaxIdleConns)
	assert.Equal(t, 10, transport.MaxIdleConnsPerHost)
	assert.Equal(t, 90*time.Second, transport.IdleConnTimeout)
}

// TestUnifiedClient_Close tests clean shutdown
func TestUnifiedClient_Close(t *testing.T) {
	logger := zaptest.NewLogger(t)
	client, err := NewUnifiedClient("http://localhost:6333", logger)
	require.NoError(t, err)

	err = client.Close()
	assert.NoError(t, err)
}

// BenchmarkUnifiedClient_UpsertPoints benchmarks batch upsert performance
// Phase 2.1.2.1.3: Optimiser les opérations batch
func BenchmarkUnifiedClient_UpsertPoints(b *testing.B) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"result": "ok"}`))
	}))
	defer server.Close()

	logger := zaptest.NewLogger(b)
	client, err := NewUnifiedClient(server.URL, logger)
	require.NoError(b, err)

	points := make([]Point, 1000)
	for i := 0; i < 1000; i++ {
		points[i] = Point{
			ID:     i,
			Vector: []float32{float32(i), float32(i + 1), float32(i + 2)},
			Payload: map[string]interface{}{
				"index": i,
				"text":  "test document",
			},
		}
	}

	ctx := context.Background()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		err := client.UpsertPoints(ctx, "benchmark_collection", points)
		require.NoError(b, err)
	}
}

// BenchmarkUnifiedClient_SearchPoints benchmarks search performance
func BenchmarkUnifiedClient_SearchPoints(b *testing.B) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		response := SearchResponse{
			Result: []ScoredPoint{
				{ID: 1, Score: 0.95, Vector: []float32{0.1, 0.2, 0.3}},
				{ID: 2, Score: 0.90, Vector: []float32{0.2, 0.3, 0.4}},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(response)
	}))
	defer server.Close()

	logger := zaptest.NewLogger(b)
	client, err := NewUnifiedClient(server.URL, logger)
	require.NoError(b, err)

	searchReq := SearchRequest{
		Vector:      []float32{0.1, 0.2, 0.3},
		Limit:       10,
		WithPayload: true,
		WithVector:  true,
	}

	ctx := context.Background()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, err := client.SearchPoints(ctx, "benchmark_collection", searchReq)
		require.NoError(b, err)
	}
}
