package bridge

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// MockN8NServer crée un serveur N8N mock pour les tests
func createMockN8NServer() *httptest.Server {
	mux := http.NewServeMux()

	// Endpoint pour déclencher un workflow
	mux.HandleFunc("/api/v1/workflows/trigger", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var request WorkflowTriggerRequest
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		// Simulation d'une réponse réussie
		response := WorkflowResponse{
			Success:     true,
			ExecutionID: "exec-123456",
			Data: map[string]interface{}{
				"status":      "triggered",
				"workflow_id": request.WorkflowID,
			},
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	// Endpoint de health check
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Endpoint qui simule des erreurs pour tester les retries
	mux.HandleFunc("/api/v1/workflows/trigger-error", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	})

	return httptest.NewServer(mux)
}

func TestNewN8NClient(t *testing.T) {
	tests := []struct {
		name    string
		config  N8NClientConfig
		wantErr bool
	}{
		{
			name: "valid config",
			config: N8NClientConfig{
				BaseURL:    "http://localhost:5678",
				APIKey:     "test-key",
				Timeout:    30 * time.Second,
				MaxRetries: 3,
			},
			wantErr: false,
		},
		{
			name: "empty base URL",
			config: N8NClientConfig{
				APIKey: "test-key",
			},
			wantErr: true,
		},
		{
			name: "invalid URL",
			config: N8NClientConfig{
				BaseURL: "invalid-url",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client, err := NewN8NClient(tt.config)
			if tt.wantErr {
				assert.Error(t, err)
				assert.Nil(t, client)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, client)
				assert.Equal(t, tt.config.BaseURL, client.config.BaseURL)
			}
		})
	}
}

func TestN8NClient_TriggerWorkflow(t *testing.T) {
	server := createMockN8NServer()
	defer server.Close()

	config := N8NClientConfig{
		BaseURL:    server.URL,
		APIKey:     "test-key",
		Timeout:    10 * time.Second,
		MaxRetries: 2,
		RetryDelay: 100 * time.Millisecond,
	}

	client, err := NewN8NClient(config)
	require.NoError(t, err)

	tests := []struct {
		name       string
		workflowID string
		data       map[string]interface{}
		wantErr    bool
	}{
		{
			name:       "successful trigger",
			workflowID: "workflow-123",
			data: map[string]interface{}{
				"email": "test@example.com",
				"name":  "Test User",
			},
			wantErr: false,
		},
		{
			name:       "empty workflow ID",
			workflowID: "",
			data:       map[string]interface{}{},
			wantErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := client.TriggerWorkflow(tt.workflowID, tt.data)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestN8NClient_TriggerWorkflowWithContext(t *testing.T) {
	server := createMockN8NServer()
	defer server.Close()

	config := N8NClientConfig{
		BaseURL:    server.URL,
		APIKey:     "test-key",
		Timeout:    10 * time.Second,
		MaxRetries: 2,
		RetryDelay: 100 * time.Millisecond,
	}

	client, err := NewN8NClient(config)
	require.NoError(t, err)

	t.Run("successful trigger with context", func(t *testing.T) {
		ctx := context.Background()
		workflowID := "workflow-123"
		data := map[string]interface{}{
			"email": "test@example.com",
			"name":  "Test User",
		}

		response, err := client.TriggerWorkflowWithContext(ctx, workflowID, data)
		assert.NoError(t, err)
		assert.NotNil(t, response)
		assert.True(t, response.Success)
		assert.Equal(t, "exec-123456", response.ExecutionID)
	})

	t.Run("context timeout", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Microsecond)
		defer cancel()

		workflowID := "workflow-123"
		data := map[string]interface{}{}

		response, err := client.TriggerWorkflowWithContext(ctx, workflowID, data)
		assert.Error(t, err)
		assert.Nil(t, response)
	})
}

func TestN8NClient_Health(t *testing.T) {
	server := createMockN8NServer()
	defer server.Close()

	config := N8NClientConfig{
		BaseURL: server.URL,
		Timeout: 5 * time.Second,
	}

	client, err := NewN8NClient(config)
	require.NoError(t, err)

	t.Run("successful health check", func(t *testing.T) {
		err := client.Health()
		assert.NoError(t, err)
	})

	t.Run("failed health check", func(t *testing.T) {
		// Fermer le serveur pour simuler un échec
		server.Close()
		err := client.Health()
		assert.Error(t, err)
	})
}

func TestN8NClient_SetConfig(t *testing.T) {
	initialConfig := N8NClientConfig{
		BaseURL: "http://localhost:5678",
		Timeout: 30 * time.Second,
	}

	client, err := NewN8NClient(initialConfig)
	require.NoError(t, err)

	newConfig := N8NClientConfig{
		BaseURL:    "http://localhost:9999",
		APIKey:     "new-key",
		Timeout:    60 * time.Second,
		MaxRetries: 5,
	}

	client.SetConfig(newConfig)

	updatedConfig := client.GetConfig()
	assert.Equal(t, newConfig.BaseURL, updatedConfig.BaseURL)
	assert.Equal(t, newConfig.APIKey, updatedConfig.APIKey)
	assert.Equal(t, newConfig.Timeout, updatedConfig.Timeout)
	assert.Equal(t, newConfig.MaxRetries, updatedConfig.MaxRetries)
}

func TestN8NClient_RetryLogic(t *testing.T) {
	// Ce test nécessiterait un serveur mock plus sophistiqué
	// qui simule des échecs temporaires puis réussit
	t.Skip("Retry logic test would need more sophisticated mock server")
}

// BenchmarkN8NClient_TriggerWorkflow benchmark pour les performances
func BenchmarkN8NClient_TriggerWorkflow(b *testing.B) {
	server := createMockN8NServer()
	defer server.Close()

	config := N8NClientConfig{
		BaseURL:    server.URL,
		Timeout:    10 * time.Second,
		MaxRetries: 1,
	}

	client, err := NewN8NClient(config)
	require.NoError(b, err)

	data := map[string]interface{}{
		"email": "test@example.com",
		"name":  "Test User",
	}

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			err := client.TriggerWorkflow("workflow-123", data)
			if err != nil {
				b.Errorf("TriggerWorkflow failed: %v", err)
			}
		}
	})
}

// Test d'intégration avec circuit breaker (conceptuel)
func TestN8NClient_CircuitBreaker(t *testing.T) {
	t.Skip("Circuit breaker test - would need additional implementation")
	// Ce test vérifierait que le circuit breaker s'ouvre après plusieurs échecs
	// et se ferme après un délai configuré
}
