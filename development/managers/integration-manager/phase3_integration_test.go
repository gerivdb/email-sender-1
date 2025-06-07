package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	integration_manager "github.com/your-org/email-sender/development/managers/integration-manager"
	"github.com/your-org/email-sender/development/managers/interfaces"
)

// Phase3IntegrationTest demonstrates comprehensive Phase 3 functionality
func Phase3IntegrationTest() error {
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)

	fmt.Println("🚀 Starting Phase 3 Integration Test...")
	fmt.Println("=" * 60)

	// 1. Initialize Integration Manager
	fmt.Println("\n1. Initializing Integration Manager...")
	im := integration_manager.NewIntegrationManager(logger)
	
	ctx := context.Background()
	if err := im.Start(ctx); err != nil {
		return fmt.Errorf("failed to start integration manager: %w", err)
	}
	defer im.Stop(ctx)

	// 2. Test Integration CRUD Operations
	fmt.Println("\n2. Testing Integration CRUD Operations...")
	if err := testIntegrationOperations(ctx, im); err != nil {
		return fmt.Errorf("integration operations test failed: %w", err)
	}
	fmt.Println("✅ Integration CRUD operations test passed")

	// 3. Test API Management
	fmt.Println("\n3. Testing API Management...")
	if err := testAPIManagement(im); err != nil {
		return fmt.Errorf("API management test failed: %w", err)
	}
	fmt.Println("✅ API management test passed")

	// 4. Test Synchronization Management
	fmt.Println("\n4. Testing Synchronization Management...")
	if err := testSynchronizationManagement(ctx, im); err != nil {
		return fmt.Errorf("synchronization management test failed: %w", err)
	}
	fmt.Println("✅ Synchronization management test passed")

	// 5. Test Webhook Management
	fmt.Println("\n5. Testing Webhook Management...")
	if err := testWebhookManagement(im); err != nil {
		return fmt.Errorf("webhook management test failed: %w", err)
	}
	fmt.Println("✅ Webhook management test passed")

	// 6. Test Data Transformation
	fmt.Println("\n6. Testing Data Transformation...")
	if err := testDataTransformation(im); err != nil {
		return fmt.Errorf("data transformation test failed: %w", err)
	}
	fmt.Println("✅ Data transformation test passed")

	// 7. Test End-to-End Integration Workflow
	fmt.Println("\n7. Testing End-to-End Integration Workflow...")
	if err := testEndToEndWorkflow(ctx, im); err != nil {
		return fmt.Errorf("end-to-end workflow test failed: %w", err)
	}
	fmt.Println("✅ End-to-end workflow test passed")

	// 8. Performance and Load Testing
	fmt.Println("\n8. Running Performance Tests...")
	if err := testPerformance(ctx, im); err != nil {
		return fmt.Errorf("performance test failed: %w", err)
	}
	fmt.Println("✅ Performance tests passed")

	fmt.Println("\n" + "=" * 60)
	fmt.Println("🎉 All Phase 3 Integration Tests Passed Successfully!")
	fmt.Println("=" * 60)

	return nil
}

func testIntegrationOperations(ctx context.Context, im *integration_manager.IntegrationManagerImpl) error {
	// Create integrations
	integrations := []*interfaces.Integration{
		{
			ID:          "test-crm-integration",
			Name:        "CRM Integration",
			Type:        "api",
			Description: "Customer relationship management system integration",
			Config: map[string]interface{}{
				"base_url": "https://api.crm.example.com",
				"version":  "v2",
				"timeout":  30,
			},
		},
		{
			ID:          "test-payment-integration",
			Name:        "Payment Gateway",
			Type:        "webhook",
			Description: "Payment processing webhook integration",
			Config: map[string]interface{}{
				"webhook_url":    "https://payment.example.com/webhook",
				"signature_key":  "payment-secret-key",
				"retry_attempts": 3,
			},
		},
		{
			ID:          "test-analytics-integration",
			Name:        "Analytics Platform",
			Type:        "database",
			Description: "Analytics data warehouse integration",
			Config: map[string]interface{}{
				"connection_string": "postgres://user:pass@localhost/analytics",
				"schema":           "public",
				"pool_size":        10,
			},
		},
	}

	// Test Create operations
	for _, integration := range integrations {
		if err := im.CreateIntegration(ctx, integration); err != nil {
			return fmt.Errorf("failed to create integration %s: %w", integration.ID, err)
		}
		fmt.Printf("  📝 Created integration: %s\n", integration.Name)
	}

	// Test Read operations
	for _, integration := range integrations {
		retrieved, err := im.GetIntegration(ctx, integration.ID)
		if err != nil {
			return fmt.Errorf("failed to get integration %s: %w", integration.ID, err)
		}
		if retrieved.Name != integration.Name {
			return fmt.Errorf("integration name mismatch: expected %s, got %s", integration.Name, retrieved.Name)
		}
		fmt.Printf("  👀 Retrieved integration: %s\n", retrieved.Name)
	}

	// Test List operations
	allIntegrations, err := im.ListIntegrations(ctx)
	if err != nil {
		return fmt.Errorf("failed to list integrations: %w", err)
	}
	if len(allIntegrations) < len(integrations) {
		return fmt.Errorf("expected at least %d integrations, got %d", len(integrations), len(allIntegrations))
	}
	fmt.Printf("  📋 Listed %d integrations\n", len(allIntegrations))

	// Test Update operations
	updateIntegration := &interfaces.Integration{
		ID:          "test-crm-integration",
		Name:        "Updated CRM Integration",
		Type:        "api",
		Description: "Updated customer relationship management system integration",
		Config: map[string]interface{}{
			"base_url":     "https://api.crm-v2.example.com",
			"version":      "v3",
			"timeout":      45,
			"api_key":      "new-api-key",
		},
	}

	if err := im.UpdateIntegration(ctx, "test-crm-integration", updateIntegration); err != nil {
		return fmt.Errorf("failed to update integration: %w", err)
	}

	updated, err := im.GetIntegration(ctx, "test-crm-integration")
	if err != nil {
		return fmt.Errorf("failed to get updated integration: %w", err)
	}
	if updated.Name != "Updated CRM Integration" {
		return fmt.Errorf("integration update failed: name not updated")
	}
	fmt.Printf("  ✏️  Updated integration: %s\n", updated.Name)

	// Test Delete operations
	if err := im.DeleteIntegration(ctx, "test-analytics-integration"); err != nil {
		return fmt.Errorf("failed to delete integration: %w", err)
	}

	_, err = im.GetIntegration(ctx, "test-analytics-integration")
	if err == nil {
		return fmt.Errorf("integration should have been deleted")
	}
	fmt.Printf("  🗑️  Deleted integration: Analytics Platform\n")

	return nil
}

func testAPIManagement(im *integration_manager.IntegrationManagerImpl) error {
	// Create test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/users":
			users := []map[string]interface{}{
				{"id": 1, "name": "John Doe", "email": "john@example.com"},
				{"id": 2, "name": "Jane Smith", "email": "jane@example.com"},
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"data":  users,
				"total": len(users),
			})
		case "/orders":
			if r.Method == "POST" {
				w.WriteHeader(http.StatusCreated)
				json.NewEncoder(w).Encode(map[string]interface{}{
					"id":     123,
					"status": "created",
				})
			}
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()

	// Register API endpoints
	endpoints := []*interfaces.APIEndpoint{
		{
			ID:           "test-users-api",
			Name:         "Users API",
			URL:          server.URL + "/users",
			Method:       "GET",
			Headers:      map[string]string{"Authorization": "Bearer test-token"},
			Timeout:      30 * time.Second,
			RetryCount:   3,
			RetryBackoff: 2 * time.Second,
		},
		{
			ID:           "test-orders-api",
			Name:         "Orders API",
			URL:          server.URL + "/orders",
			Method:       "POST",
			Headers:      map[string]string{"Content-Type": "application/json"},
			Timeout:      30 * time.Second,
			RetryCount:   2,
			RetryBackoff: 1 * time.Second,
		},
	}

	for _, endpoint := range endpoints {
		if err := im.RegisterAPIEndpoint(endpoint); err != nil {
			return fmt.Errorf("failed to register API endpoint %s: %w", endpoint.ID, err)
		}
		fmt.Printf("  🔗 Registered API endpoint: %s\n", endpoint.Name)
	}

	// Test API calls
	// GET request
	getUsersRequest := &interfaces.APIRequest{
		QueryParams: map[string]string{
			"limit":  "10",
			"offset": "0",
		},
	}

	response, err := im.CallAPI("test-users-api", getUsersRequest)
	if err != nil {
		return fmt.Errorf("failed to call users API: %w", err)
	}
	if response.StatusCode != 200 {
		return fmt.Errorf("unexpected status code: %d", response.StatusCode)
	}
	fmt.Printf("  📞 Called Users API: Status %d\n", response.StatusCode)

	// POST request
	createOrderRequest := &interfaces.APIRequest{
		Body: map[string]interface{}{
			"user_id":    1,
			"product_id": 42,
			"quantity":   2,
		},
	}

	response, err = im.CallAPI("test-orders-api", createOrderRequest)
	if err != nil {
		return fmt.Errorf("failed to call orders API: %w", err)
	}
	if response.StatusCode != 201 {
		return fmt.Errorf("unexpected status code: %d", response.StatusCode)
	}
	fmt.Printf("  📞 Called Orders API: Status %d\n", response.StatusCode)

	// Test API status
	status, err := im.GetAPIStatus("test-users-api")
	if err != nil {
		return fmt.Errorf("failed to get API status: %w", err)
	}
	if status.Status != "healthy" {
		return fmt.Errorf("expected API status to be healthy, got %s", status.Status)
	}
	fmt.Printf("  ❤️  API Status: %s\n", status.Status)

	return nil
}

func testSynchronizationManagement(ctx context.Context, im *integration_manager.IntegrationManagerImpl) error {
	// Create sync jobs
	syncJobs := []*interfaces.SyncJob{
		{
			ID:               "test-user-sync",
			Name:             "User Data Sync",
			SourceID:         "test-crm-integration",
			DestinationID:    "test-payment-integration",
			SyncType:         "OneWay",
			Schedule:         "0 */10 * * * *", // Every 10 minutes
			TransformationID: "user-transform",
			Config: map[string]interface{}{
				"batch_size":      100,
				"timeout":         300,
				"conflict_policy": "source_wins",
			},
		},
		{
			ID:               "test-order-sync",
			Name:             "Order Data Sync",
			SourceID:         "test-payment-integration",
			DestinationID:    "test-crm-integration",
			SyncType:         "TwoWay",
			Schedule:         "0 0 */4 * * *", // Every 4 hours
			TransformationID: "order-transform",
			Config: map[string]interface{}{
				"batch_size":      50,
				"timeout":         600,
				"conflict_policy": "timestamp",
			},
		},
	}

	for _, syncJob := range syncJobs {
		if err := im.CreateSyncJob(ctx, syncJob); err != nil {
			return fmt.Errorf("failed to create sync job %s: %w", syncJob.ID, err)
		}
		fmt.Printf("  🔄 Created sync job: %s\n", syncJob.Name)
	}

	// Test sync execution
	for _, syncJob := range syncJobs {
		if err := im.StartSync(ctx, syncJob.ID); err != nil {
			return fmt.Errorf("failed to start sync %s: %w", syncJob.ID, err)
		}
		fmt.Printf("  ▶️  Started sync: %s\n", syncJob.Name)

		// Wait a bit for sync to process
		time.Sleep(200 * time.Millisecond)

		// Check sync status
		status, err := im.GetSyncStatus(syncJob.ID)
		if err != nil {
			return fmt.Errorf("failed to get sync status for %s: %w", syncJob.ID, err)
		}
		fmt.Printf("  📊 Sync %s status: %s\n", syncJob.Name, status.Status)

		// Get sync history
		history, err := im.GetSyncHistory(syncJob.ID)
		if err != nil {
			return fmt.Errorf("failed to get sync history for %s: %w", syncJob.ID, err)
		}
		fmt.Printf("  📜 Sync %s history: %d events\n", syncJob.Name, len(history))

		// Stop sync
		if err := im.StopSync(ctx, syncJob.ID); err != nil {
			return fmt.Errorf("failed to stop sync %s: %w", syncJob.ID, err)
		}
		fmt.Printf("  ⏹️  Stopped sync: %s\n", syncJob.Name)
	}

	return nil
}

func testWebhookManagement(im *integration_manager.IntegrationManagerImpl) error {
	// Register webhooks
	webhooks := []*interfaces.Webhook{
		{
			ID:          "test-payment-webhook",
			URL:         "https://payment.example.com/webhook",
			Events:      []string{"payment.completed", "payment.failed", "payment.refunded"},
			Secret:      "payment-webhook-secret-123",
			ContentType: "application/json",
			Timeout:     30 * time.Second,
			MaxRetries:  3,
			RetryBackoff: 5 * time.Second,
		},
		{
			ID:          "test-integration-webhook",
			URL:         "https://integration.example.com/webhook",
			Events:      []string{"integration.*", "sync.*"},
			Secret:      "integration-webhook-secret-456",
			ContentType: "application/json",
			Timeout:     45 * time.Second,
			MaxRetries:  5,
			RetryBackoff: 3 * time.Second,
		},
	}

	for _, webhook := range webhooks {
		if err := im.RegisterWebhook(webhook); err != nil {
			return fmt.Errorf("failed to register webhook %s: %w", webhook.ID, err)
		}
		fmt.Printf("  🎣 Registered webhook: %s\n", webhook.ID)
	}

	// Test webhook handling
	testCases := []struct {
		webhookID string
		eventType string
		payload   map[string]interface{}
	}{
		{
			webhookID: "test-payment-webhook",
			eventType: "payment.completed",
			payload: map[string]interface{}{
				"payment_id": "pay_123456789",
				"amount":     99.99,
				"currency":   "USD",
				"status":     "completed",
			},
		},
		{
			webhookID: "test-integration-webhook",
			eventType: "sync.completed",
			payload: map[string]interface{}{
				"sync_job_id": "test-user-sync",
				"status":      "completed",
				"records":     150,
				"duration":    "2.5s",
			},
		},
	}

	for _, testCase := range testCases {
		// Create test request
		payloadBytes, _ := json.Marshal(testCase.payload)
		req := httptest.NewRequest("POST", "/webhook/"+testCase.webhookID, strings.NewReader(string(payloadBytes)))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Event-Type", testCase.eventType)

		if err := im.HandleWebhook(testCase.webhookID, req); err != nil {
			return fmt.Errorf("failed to handle webhook %s: %w", testCase.webhookID, err)
		}
		fmt.Printf("  📨 Handled webhook: %s -> %s\n", testCase.webhookID, testCase.eventType)
	}

	// Check webhook logs
	for _, webhook := range webhooks {
		logs, err := im.GetWebhookLogs(webhook.ID, 10)
		if err != nil {
			return fmt.Errorf("failed to get webhook logs for %s: %w", webhook.ID, err)
		}
		fmt.Printf("  📝 Webhook %s logs: %d entries\n", webhook.ID, len(logs))
	}

	return nil
}

func testDataTransformation(im *integration_manager.IntegrationManagerImpl) error {
	// Register various transformations
	transformations := []*interfaces.DataTransformation{
		{
			ID:          "user-transform",
			Name:        "User Data Transformation",
			Type:        "mapping",
			Description: "Transform user data from CRM to payment format",
			Config: map[string]interface{}{
				"mappings": map[string]interface{}{
					"customer_id":    "id",
					"customer_name":  "name",
					"customer_email": "email",
					"phone_number":   "phone",
				},
			},
		},
		{
			ID:          "order-transform",
			Name:        "Order Data Transformation",
			Type:        "filter",
			Description: "Filter and transform order data",
			Config: map[string]interface{}{
				"filters": map[string]interface{}{
					"status": "completed",
					"amount": map[string]interface{}{
						"$gte": 10.0,
					},
				},
			},
		},
		{
			ID:          "analytics-transform",
			Name:        "Analytics Aggregation",
			Type:        "aggregation",
			Description: "Aggregate order data for analytics",
			Config: map[string]interface{}{
				"aggregations": map[string]interface{}{
					"total_orders": map[string]interface{}{
						"type": "count",
					},
					"total_revenue": map[string]interface{}{
						"type":  "sum",
						"field": "amount",
					},
					"average_order": map[string]interface{}{
						"type":  "avg",
						"field": "amount",
					},
				},
			},
		},
		{
			ID:          "data-normalizer",
			Name:        "Data Normalizer",
			Type:        "custom",
			Description: "Normalize data types and format",
			Config: map[string]interface{}{
				"custom_type": "normalize",
			},
		},
	}

	for _, transformation := range transformations {
		if err := im.RegisterTransformation(transformation); err != nil {
			return fmt.Errorf("failed to register transformation %s: %w", transformation.ID, err)
		}
		fmt.Printf("  🔧 Registered transformation: %s\n", transformation.Name)
	}

	// Test transformations
	testCases := []struct {
		transformationID string
		inputData        interface{}
		description      string
	}{
		{
			transformationID: "user-transform",
			inputData: map[string]interface{}{
				"id":    123,
				"name":  "John Doe",
				"email": "john@example.com",
				"phone": "+1-555-0123",
			},
			description: "User mapping transformation",
		},
		{
			transformationID: "order-transform",
			inputData: []interface{}{
				map[string]interface{}{"id": 1, "status": "completed", "amount": 25.99},
				map[string]interface{}{"id": 2, "status": "pending", "amount": 15.50},
				map[string]interface{}{"id": 3, "status": "completed", "amount": 5.00},
				map[string]interface{}{"id": 4, "status": "completed", "amount": 45.75},
			},
			description: "Order filtering transformation",
		},
		{
			transformationID: "analytics-transform",
			inputData: []interface{}{
				map[string]interface{}{"amount": 25.99, "status": "completed"},
				map[string]interface{}{"amount": 15.50, "status": "completed"},
				map[string]interface{}{"amount": 45.75, "status": "completed"},
			},
			description: "Analytics aggregation transformation",
		},
		{
			transformationID: "data-normalizer",
			inputData: map[string]interface{}{
				"price":    "25.99",
				"quantity": "5",
				"active":   "true",
			},
			description: "Data normalization transformation",
		},
	}

	for _, testCase := range testCases {
		result, err := im.TransformData(testCase.transformationID, testCase.inputData)
		if err != nil {
			return fmt.Errorf("failed to transform data with %s: %w", testCase.transformationID, err)
		}
		fmt.Printf("  🔄 Transformed data: %s\n", testCase.description)
		
		// Basic result validation
		if result == nil {
			return fmt.Errorf("transformation %s returned nil result", testCase.transformationID)
		}
	}

	return nil
}

func testEndToEndWorkflow(ctx context.Context, im *integration_manager.IntegrationManagerImpl) error {
	fmt.Println("  🌊 Starting end-to-end workflow simulation...")

	// Simulate a complete integration workflow:
	// 1. Data comes in via webhook
	// 2. Data is transformed
	// 3. API call is made to external system
	// 4. Sync job processes the result
	// 5. Analytics transformation aggregates the data

	// Step 1: Handle incoming webhook with user data
	userPayload := map[string]interface{}{
		"event_type": "user.created",
		"user": map[string]interface{}{
			"id":    456,
			"name":  "Alice Johnson",
			"email": "alice@example.com",
			"phone": "+1-555-0456",
		},
	}

	payloadBytes, _ := json.Marshal(userPayload)
	req := httptest.NewRequest("POST", "/webhook/test-integration-webhook", strings.NewReader(string(payloadBytes)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Event-Type", "user.created")

	if err := im.HandleWebhook("test-integration-webhook", req); err != nil {
		return fmt.Errorf("failed to handle user creation webhook: %w", err)
	}
	fmt.Println("    ✅ Step 1: User creation webhook handled")

	// Step 2: Transform user data
	userData := userPayload["user"]
	transformedUser, err := im.TransformData("user-transform", userData)
	if err != nil {
		return fmt.Errorf("failed to transform user data: %w", err)
	}
	fmt.Println("    ✅ Step 2: User data transformed")

	// Step 3: Simulate API call (we'll use our test endpoints)
	apiRequest := &interfaces.APIRequest{
		Body: transformedUser,
	}

	// This would normally call an external API, but we'll validate the structure
	if transformedMap, ok := transformedUser.(map[string]interface{}); ok {
		if _, hasCustomerID := transformedMap["customer_id"]; !hasCustomerID {
			return fmt.Errorf("transformed data missing customer_id field")
		}
		if _, hasCustomerEmail := transformedMap["customer_email"]; !hasCustomerEmail {
			return fmt.Errorf("transformed data missing customer_email field")
		}
	}
	fmt.Println("    ✅ Step 3: API call structure validated")

	// Step 4: Simulate sync job execution
	if err := im.StartSync(ctx, "test-user-sync"); err != nil {
		return fmt.Errorf("failed to start user sync: %w", err)
	}
	
	// Wait for sync to process
	time.Sleep(300 * time.Millisecond)
	
	syncStatus, err := im.GetSyncStatus("test-user-sync")
	if err != nil {
		return fmt.Errorf("failed to get sync status: %w", err)
	}
	fmt.Printf("    ✅ Step 4: Sync job executed (status: %s)\n", syncStatus.Status)

	// Step 5: Aggregate analytics data
	analyticsData := []interface{}{
		map[string]interface{}{"amount": 25.99, "status": "completed", "user_id": 456},
		map[string]interface{}{"amount": 15.50, "status": "completed", "user_id": 456},
	}

	aggregatedResult, err := im.TransformData("analytics-transform", analyticsData)
	if err != nil {
		return fmt.Errorf("failed to aggregate analytics data: %w", err)
	}
	
	if analyticsMap, ok := aggregatedResult.(map[string]interface{}); ok {
		totalOrders, _ := analyticsMap["total_orders"].(int)
		totalRevenue, _ := analyticsMap["total_revenue"].(float64)
		fmt.Printf("    ✅ Step 5: Analytics aggregated (Orders: %d, Revenue: %.2f)\n", totalOrders, totalRevenue)
	}

	fmt.Println("  🎯 End-to-end workflow completed successfully!")
	return nil
}

func testPerformance(ctx context.Context, im *integration_manager.IntegrationManagerImpl) error {
	fmt.Println("  ⚡ Running performance benchmarks...")

	// Test 1: Bulk integration creation
	start := time.Now()
	for i := 0; i < 100; i++ {
		integration := &interfaces.Integration{
			ID:   fmt.Sprintf("perf-integration-%d", i),
			Name: fmt.Sprintf("Performance Test Integration %d", i),
			Type: "api",
			Config: map[string]interface{}{
				"url":     fmt.Sprintf("https://api%d.example.com", i),
				"timeout": 30,
			},
		}
		if err := im.CreateIntegration(ctx, integration); err != nil {
			return fmt.Errorf("failed to create performance integration %d: %w", i, err)
		}
	}
	duration1 := time.Since(start)
	fmt.Printf("    📊 Created 100 integrations in %v (%.2f integrations/sec)\n", 
		duration1, 100.0/duration1.Seconds())

	// Test 2: Bulk data transformation
	start = time.Now()
	testData := map[string]interface{}{
		"name":  "Performance Test",
		"value": 42,
		"tags":  []string{"performance", "test"},
	}

	for i := 0; i < 1000; i++ {
		_, err := im.TransformData("data-normalizer", testData)
		if err != nil {
			return fmt.Errorf("failed to transform data in performance test %d: %w", i, err)
		}
	}
	duration2 := time.Since(start)
	fmt.Printf("    📊 Performed 1000 transformations in %v (%.2f transformations/sec)\n", 
		duration2, 1000.0/duration2.Seconds())

	// Test 3: Concurrent sync operations
	start = time.Now()
	var syncWg sync.WaitGroup
	concurrentSyncs := 10

	for i := 0; i < concurrentSyncs; i++ {
		syncWg.Add(1)
		go func(index int) {
			defer syncWg.Done()
			syncID := fmt.Sprintf("perf-sync-%d", index)
			
			syncJob := &interfaces.SyncJob{
				ID:            syncID,
				Name:          fmt.Sprintf("Performance Sync %d", index),
				SourceID:      "perf-source",
				DestinationID: "perf-dest",
				SyncType:      "OneWay",
				Config: map[string]interface{}{
					"batch_size": 10,
				},
			}
			
			if err := im.CreateSyncJob(ctx, syncJob); err != nil {
				log.Printf("Failed to create sync job %d: %v", index, err)
				return
			}
			
			if err := im.StartSync(ctx, syncID); err != nil {
				log.Printf("Failed to start sync %d: %v", index, err)
				return
			}
		}(i)
	}
	
	syncWg.Wait()
	duration3 := time.Since(start)
	fmt.Printf("    📊 Created and started %d concurrent syncs in %v\n", 
		concurrentSyncs, duration3)

	// Performance summary
	fmt.Println("  🏁 Performance benchmarks completed")
	return nil
}

func main() {
	if err := Phase3IntegrationTest(); err != nil {
		log.Fatalf("❌ Phase 3 Integration Test Failed: %v", err)
	}
}

// Helper function for string repetition (Go doesn't have built-in string multiplication)
func repeatString(s string, count int) string {
	result := ""
	for i := 0; i < count; i++ {
		result += s
	}
	return result
}
