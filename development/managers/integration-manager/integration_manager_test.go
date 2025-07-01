package integration_manager

import (
	"EMAIL_SENDER_1/development/managers/interfaces"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegrationManagerImpl_CreateIntegration(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	integration := &interfaces.Integration{
		ID:          "test-integration-1",
		Name:        "Test Integration",
		Type:        "api",
		Description: "Test integration for unit tests",
		Config: map[string]interface{}{
			"base_url": "https://api.example.com",
			"timeout":  30,
		},
	}

	err := manager.CreateIntegration(ctx, integration)
	require.NoError(t, err)

	// Verify integration was created
	retrieved, err := manager.GetIntegration(ctx, "test-integration-1")
	require.NoError(t, err)
	assert.Equal(t, integration.ID, retrieved.ID)
	assert.Equal(t, integration.Name, retrieved.Name)
	assert.Equal(t, integration.Type, retrieved.Type)
}

func TestIntegrationManagerImpl_UpdateIntegration(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	// Create initial integration
	integration := &interfaces.Integration{
		ID:          "test-integration-2",
		Name:        "Test Integration 2",
		Type:        "webhook",
		Description: "Initial description",
		Config: map[string]interface{}{
			"url": "https://webhook.example.com",
		},
	}

	err := manager.CreateIntegration(ctx, integration)
	require.NoError(t, err)

	// Update integration
	updatedIntegration := &interfaces.Integration{
		ID:          "test-integration-2",
		Name:        "Updated Integration",
		Type:        "webhook",
		Description: "Updated description",
		Config: map[string]interface{}{
			"url":    "https://webhook-updated.example.com",
			"secret": "new-secret",
		},
	}

	err = manager.UpdateIntegration(ctx, "test-integration-2", updatedIntegration)
	require.NoError(t, err)

	// Verify update
	retrieved, err := manager.GetIntegration(ctx, "test-integration-2")
	require.NoError(t, err)
	assert.Equal(t, "Updated Integration", retrieved.Name)
	assert.Equal(t, "Updated description", retrieved.Description)
	assert.Equal(t, "https://webhook-updated.example.com", retrieved.Config["url"])
}

func TestIntegrationManagerImpl_DeleteIntegration(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	// Create integration
	integration := &interfaces.Integration{
		ID:   "test-integration-3",
		Name: "Test Integration 3",
		Type: "database",
	}

	err := manager.CreateIntegration(ctx, integration)
	require.NoError(t, err)

	// Delete integration
	err = manager.DeleteIntegration(ctx, "test-integration-3")
	require.NoError(t, err)

	// Verify deletion
	_, err = manager.GetIntegration(ctx, "test-integration-3")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "integration not found")
}

func TestIntegrationManagerImpl_ListIntegrations(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	// Create multiple integrations
	integrations := []*interfaces.Integration{
		{
			ID:   "list-test-1",
			Name: "List Test 1",
			Type: "api",
		},
		{
			ID:   "list-test-2",
			Name: "List Test 2",
			Type: "webhook",
		},
		{
			ID:   "list-test-3",
			Name: "List Test 3",
			Type: "database",
		},
	}

	for _, integration := range integrations {
		err := manager.CreateIntegration(ctx, integration)
		require.NoError(t, err)
	}

	// List all integrations
	listed, err := manager.ListIntegrations(ctx)
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(listed), 3)

	// Verify our test integrations are included
	found := make(map[string]bool)
	for _, integration := range listed {
		if strings.HasPrefix(integration.ID, "list-test-") {
			found[integration.ID] = true
		}
	}
	assert.Len(t, found, 3)
}

func TestIntegrationManagerImpl_TestIntegration(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	// Create a test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	}))
	defer server.Close()

	// Create API integration
	integration := &interfaces.Integration{
		ID:   "test-api-integration",
		Name: "Test API Integration",
		Type: "api",
		Config: map[string]interface{}{
			"base_url": server.URL,
			"timeout":  30,
		},
	}

	err := manager.CreateIntegration(ctx, integration)
	require.NoError(t, err)

	// Test integration
	err = manager.TestIntegration(ctx, "test-api-integration")
	assert.NoError(t, err)
}

func TestIntegrationManagerImpl_RegisterAPIEndpoint(t *testing.T) {
	manager := createTestIntegrationManager(t)

	endpoint := &interfaces.APIEndpoint{
		ID:           "test-endpoint-1",
		Name:         "Test Endpoint",
		URL:          "https://api.example.com/users",
		Method:       "GET",
		Headers:      map[string]string{"Content-Type": "application/json"},
		Timeout:      30 * time.Second,
		RetryCount:   3,
		RetryBackoff: 2 * time.Second,
	}

	err := manager.RegisterAPIEndpoint(endpoint)
	require.NoError(t, err)

	// Verify endpoint was registered
	manager.mutex.RLock()
	registered, exists := manager.apis[endpoint.ID]
	manager.mutex.RUnlock()

	assert.True(t, exists)
	assert.Equal(t, endpoint.ID, registered.ID)
	assert.Equal(t, endpoint.URL, registered.URL)
}

func TestIntegrationManagerImpl_CallAPI(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Create a test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		response := map[string]interface{}{
			"message": "Hello from test server",
			"method":  r.Method,
			"headers": r.Header,
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}))
	defer server.Close()

	// Register endpoint
	endpoint := &interfaces.APIEndpoint{
		ID:      "test-api-call",
		Name:    "Test API Call",
		URL:     server.URL + "/test",
		Method:  "POST",
		Headers: map[string]string{"Authorization": "Bearer test-token"},
		Timeout: 30 * time.Second,
	}

	err := manager.RegisterAPIEndpoint(endpoint)
	require.NoError(t, err)

	// Make API call
	request := &interfaces.APIRequest{
		Body: map[string]interface{}{
			"name": "test",
			"type": "unit-test",
		},
		QueryParams: map[string]string{
			"format": "json",
		},
	}

	response, err := manager.CallAPI("test-api-call", request)
	require.NoError(t, err)

	assert.Equal(t, 200, response.StatusCode)
	assert.NotEmpty(t, response.Body)

	// Parse response body
	var responseData map[string]interface{}
	err = json.Unmarshal([]byte(response.Body), &responseData)
	require.NoError(t, err)

	assert.Equal(t, "Hello from test server", responseData["message"])
	assert.Equal(t, "POST", responseData["method"])
}

func TestIntegrationManagerImpl_CreateSyncJob(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	syncJob := &interfaces.SyncJob{
		ID:               "test-sync-1",
		Name:             "Test Sync Job",
		SourceID:         "source-integration",
		DestinationID:    "dest-integration",
		SyncType:         "OneWay",
		Schedule:         "0 */5 * * * *", // Every 5 minutes
		TransformationID: "test-transform",
		Config: map[string]interface{}{
			"batch_size": 100,
			"timeout":    300,
		},
	}

	err := manager.CreateSyncJob(ctx, syncJob)
	require.NoError(t, err)

	// Verify sync job was created
	manager.syncMutex.RLock()
	created, exists := manager.syncJobs[syncJob.ID]
	manager.syncMutex.RUnlock()

	assert.True(t, exists)
	assert.Equal(t, syncJob.ID, created.ID)
	assert.Equal(t, syncJob.Name, created.Name)
	assert.Equal(t, syncJob.SyncType, created.SyncType)
}

func TestIntegrationManagerImpl_StartSync(t *testing.T) {
	manager := createTestIntegrationManager(t)
	ctx := context.Background()

	// Create sync job first
	syncJob := &interfaces.SyncJob{
		ID:            "test-sync-start",
		Name:          "Test Sync Start",
		SourceID:      "source-integration",
		DestinationID: "dest-integration",
		SyncType:      "OneWay",
		Config: map[string]interface{}{
			"batch_size": 10,
		},
	}

	err := manager.CreateSyncJob(ctx, syncJob)
	require.NoError(t, err)

	// Start sync
	err = manager.StartSync(ctx, "test-sync-start")
	require.NoError(t, err)

	// Give it a moment to start
	time.Sleep(100 * time.Millisecond)

	// Check sync status
	status, err := manager.GetSyncStatus("test-sync-start")
	require.NoError(t, err)
	assert.Contains(t, []string{"running", "completed", "failed"}, status.Status)
}

func TestIntegrationManagerImpl_RegisterWebhook(t *testing.T) {
	manager := createTestIntegrationManager(t)

	webhook := &interfaces.Webhook{
		ID:     "test-webhook-1",
		URL:    "https://example.com/webhook",
		Events: []string{"integration.created", "sync.completed"},
		Secret: "webhook-secret-123",
		Config: map[string]interface{}{
			"timeout":       30,
			"max_retries":   3,
			"retry_backoff": 5,
		},
	}

	err := manager.RegisterWebhook(webhook)
	require.NoError(t, err)

	// Verify webhook was registered
	manager.webhookMutex.RLock()
	registered, exists := manager.webhooks[webhook.ID]
	manager.webhookMutex.RUnlock()

	assert.True(t, exists)
	assert.Equal(t, webhook.ID, registered.ID)
	assert.Equal(t, webhook.URL, registered.URL)
	assert.Equal(t, webhook.Events, registered.Events)
}

func TestIntegrationManagerImpl_HandleWebhook(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Register webhook first
	webhook := &interfaces.Webhook{
		ID:     "test-webhook-handle",
		URL:    "https://example.com/webhook",
		Events: []string{"test.event"},
		Secret: "",
	}

	err := manager.RegisterWebhook(webhook)
	require.NoError(t, err)

	// Create test request
	payload := map[string]interface{}{
		"event_type": "test.event",
		"message":    "test webhook payload",
		"timestamp":  time.Now().Unix(),
	}
	payloadBytes, _ := json.Marshal(payload)

	req := httptest.NewRequest("POST", "/webhook/test-webhook-handle", strings.NewReader(string(payloadBytes)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Event-Type", "test.event")

	// Handle webhook
	err = manager.HandleWebhook("test-webhook-handle", req)
	assert.NoError(t, err)

	// Verify webhook logs were created
	logs, err := manager.GetWebhookLogs("test-webhook-handle", 10)
	require.NoError(t, err)
	assert.NotEmpty(t, logs)
}

func TestIntegrationManagerImpl_RegisterTransformation(t *testing.T) {
	manager := createTestIntegrationManager(t)

	transformation := &interfaces.DataTransformation{
		ID:          "test-transform-1",
		Name:        "Test Mapping Transformation",
		Type:        "mapping",
		Description: "Test transformation for unit tests",
		Config: map[string]interface{}{
			"mappings": map[string]interface{}{
				"name":  "full_name",
				"email": "email_address",
				"age":   "user_age",
			},
		},
	}

	err := manager.RegisterTransformation(transformation)
	require.NoError(t, err)

	// Verify transformation was registered
	manager.mutex.RLock()
	registered, exists := manager.transformations[transformation.ID]
	manager.mutex.RUnlock()

	assert.True(t, exists)
	assert.Equal(t, transformation.ID, registered.ID)
	assert.Equal(t, transformation.Type, registered.Type)
}

func TestIntegrationManagerImpl_TransformData(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Register mapping transformation
	transformation := &interfaces.DataTransformation{
		ID:   "test-mapping",
		Name: "Test Mapping",
		Type: "mapping",
		Config: map[string]interface{}{
			"mappings": map[string]interface{}{
				"output_name":  "name",
				"output_email": "email",
			},
		},
	}

	err := manager.RegisterTransformation(transformation)
	require.NoError(t, err)

	// Test data transformation
	inputData := map[string]interface{}{
		"name":  "John Doe",
		"email": "john@example.com",
		"age":   30,
	}

	result, err := manager.TransformData("test-mapping", inputData)
	require.NoError(t, err)

	resultMap, ok := result.(map[string]interface{})
	require.True(t, ok)

	assert.Equal(t, "John Doe", resultMap["output_name"])
	assert.Equal(t, "john@example.com", resultMap["output_email"])
}

func TestIntegrationManagerImpl_FilterTransformation(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Register filter transformation
	transformation := &interfaces.DataTransformation{
		ID:   "test-filter",
		Name: "Test Filter",
		Type: "filter",
		Config: map[string]interface{}{
			"filters": map[string]interface{}{
				"age": map[string]interface{}{
					"$gte": 18,
					"$lt":  65,
				},
				"active": true,
			},
		},
	}

	err := manager.RegisterTransformation(transformation)
	require.NoError(t, err)

	// Test data (array of objects)
	inputData := []interface{}{
		map[string]interface{}{"name": "John", "age": 25, "active": true},
		map[string]interface{}{"name": "Jane", "age": 17, "active": true},
		map[string]interface{}{"name": "Bob", "age": 35, "active": false},
		map[string]interface{}{"name": "Alice", "age": 28, "active": true},
	}

	result, err := manager.TransformData("test-filter", inputData)
	require.NoError(t, err)

	resultArray, ok := result.([]interface{})
	require.True(t, ok)

	// Should filter to only John and Alice (age >= 18 and active = true)
	assert.Len(t, resultArray, 2)
}

func TestIntegrationManagerImpl_AggregationTransformation(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Register aggregation transformation
	transformation := &interfaces.DataTransformation{
		ID:   "test-aggregation",
		Name: "Test Aggregation",
		Type: "aggregation",
		Config: map[string]interface{}{
			"aggregations": map[string]interface{}{
				"total_count": map[string]interface{}{
					"type": "count",
				},
				"average_age": map[string]interface{}{
					"type":  "avg",
					"field": "age",
				},
				"total_salary": map[string]interface{}{
					"type":  "sum",
					"field": "salary",
				},
			},
		},
	}

	err := manager.RegisterTransformation(transformation)
	require.NoError(t, err)

	// Test data
	inputData := []interface{}{
		map[string]interface{}{"name": "John", "age": 25, "salary": 50000},
		map[string]interface{}{"name": "Jane", "age": 30, "salary": 60000},
		map[string]interface{}{"name": "Bob", "age": 35, "salary": 70000},
	}

	result, err := manager.TransformData("test-aggregation", inputData)
	require.NoError(t, err)

	resultMap, ok := result.(map[string]interface{})
	require.True(t, ok)

	assert.Equal(t, 3, resultMap["total_count"])
	assert.Equal(t, 30.0, resultMap["average_age"])
	assert.Equal(t, 180000.0, resultMap["total_salary"])
}

func TestIntegrationManagerImpl_CustomTransformation(t *testing.T) {
	manager := createTestIntegrationManager(t)

	// Register custom flatten transformation
	transformation := &interfaces.DataTransformation{
		ID:   "test-flatten",
		Name: "Test Flatten",
		Type: "custom",
		Config: map[string]interface{}{
			"custom_type": "flatten",
		},
	}

	err := manager.RegisterTransformation(transformation)
	require.NoError(t, err)

	// Test nested data
	inputData := map[string]interface{}{
		"user": map[string]interface{}{
			"name": "John Doe",
			"contact": map[string]interface{}{
				"email": "john@example.com",
				"phone": "123-456-7890",
			},
		},
		"metadata": map[string]interface{}{
			"created": "2023-01-01",
			"version": 1,
		},
	}

	result, err := manager.TransformData("test-flatten", inputData)
	require.NoError(t, err)

	resultMap, ok := result.(map[string]interface{})
	require.True(t, ok)

	// Should flatten nested structure
	assert.Equal(t, "John Doe", resultMap["user.name"])
	assert.Equal(t, "john@example.com", resultMap["user.contact.email"])
	assert.Equal(t, "123-456-7890", resultMap["user.contact.phone"])
	assert.Equal(t, "2023-01-01", resultMap["metadata.created"])
}

// Helper function to create a test integration manager
func createTestIntegrationManager(t *testing.T) *IntegrationManagerImpl {
	logger := logrus.New()
	logger.SetLevel(logrus.WarnLevel) // Reduce log noise in tests

	im := NewIntegrationManager(logger)

	// Start the manager
	err := im.Start(context.Background())
	require.NoError(t, err)

	// Cleanup function
	t.Cleanup(func() {
		im.Stop(context.Background())
	})

	return im
}

// Benchmark tests

func BenchmarkIntegrationManagerImpl_CreateIntegration(b *testing.B) {
	manager := &IntegrationManagerImpl{
		integrations: make(map[string]*interfaces.Integration),
		logger:       logrus.New(),
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		integration := &interfaces.Integration{
			ID:   fmt.Sprintf("bench-integration-%d", i),
			Name: fmt.Sprintf("Benchmark Integration %d", i),
			Type: "api",
		}
		manager.CreateIntegration(ctx, integration)
	}
}

func BenchmarkIntegrationManagerImpl_TransformData(b *testing.B) {
	manager := &IntegrationManagerImpl{
		transformations: make(map[string]*interfaces.DataTransformation),
		logger:          logrus.New(),
	}

	// Register transformation
	transformation := &interfaces.DataTransformation{
		ID:   "bench-transform",
		Type: "mapping",
		Config: map[string]interface{}{
			"mappings": map[string]interface{}{
				"output_name": "name",
				"output_age":  "age",
			},
		},
	}
	manager.RegisterTransformation(transformation)

	inputData := map[string]interface{}{
		"name": "Test User",
		"age":  25,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		manager.TransformData("bench-transform", inputData)
	}
}
