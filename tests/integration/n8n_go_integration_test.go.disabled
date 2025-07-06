package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"email_sender/pkg/bridge"
	"email_sender/pkg/managers"
	"email_sender/pkg/queue"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// TestSuite structure pour les tests d'intégration
type IntegrationTestSuite struct {
	logger      *zap.Logger
	manager     managers.N8NManager
	bridge      *bridge.ParameterBridge
	queueSystem *queue.AsyncQueueSystem
	httpServer  *httptest.Server
	testResults *TestResults
}

// TestResults contient les résultats des tests
type TestResults struct {
	TotalTests       int                    `json:"total_tests"`
	PassedTests      int                    `json:"passed_tests"`
	FailedTests      int                    `json:"failed_tests"`
	SkippedTests     int                    `json:"skipped_tests"`
	ExecutionTime    time.Duration          `json:"execution_time"`
	TestSuites       map[string]SuiteResult `json:"test_suites"`
	Errors           []string               `json:"errors"`
	Coverage         float64                `json:"coverage"`
	PerformanceStats PerformanceStats       `json:"performance_stats"`
}

// SuiteResult résultats d'une suite de tests
type SuiteResult struct {
	Name          string        `json:"name"`
	Tests         int           `json:"tests"`
	Passed        int           `json:"passed"`
	Failed        int           `json:"failed"`
	ExecutionTime time.Duration `json:"execution_time"`
	Errors        []string      `json:"errors"`
}

// PerformanceStats statistiques de performance
type PerformanceStats struct {
	AverageResponseTime time.Duration `json:"average_response_time"`
	MinResponseTime     time.Duration `json:"min_response_time"`
	MaxResponseTime     time.Duration `json:"max_response_time"`
	Throughput          float64       `json:"throughput"` // requests per second
	ErrorRate           float64       `json:"error_rate"`
	MemoryUsage         int64         `json:"memory_usage"`
	CPUUsage            float64       `json:"cpu_usage"`
}

// N8NWorkflowRequest structure pour les requêtes N8N
type N8NWorkflowRequest struct {
	WorkflowID    string                 `json:"workflowId"`
	NodeID        string                 `json:"nodeId"`
	Parameters    map[string]interface{} `json:"parameters"`
	InputData     []interface{}          `json:"inputData"`
	Options       map[string]interface{} `json:"options"`
	TraceID       string                 `json:"traceId"`
	CorrelationID string                 `json:"correlationId"`
}

// NewIntegrationTestSuite crée une nouvelle suite de tests
func NewIntegrationTestSuite(t *testing.T) *IntegrationTestSuite {
	logger := zaptest.NewLogger(t)

	// Configuration N8N Manager
	managerConfig := &managers.N8NManagerConfig{
		Name:              "test-manager",
		Version:           "1.0.0-test",
		MaxConcurrency:    10,
		DefaultTimeout:    30 * time.Second,
		HeartbeatInterval: 5 * time.Second,
		CLIPath:           "email-sender",
		CLITimeout:        30 * time.Second,
		CLIRetries:        3,
		DefaultQueue:      "test-queue",
		QueueWorkers:      map[string]int{"test-queue": 3},
		EnableMetrics:     true,
		EnableTracing:     true,
		LogLevel:          "debug",
		MetricsInterval:   1 * time.Second,
	}

	// Créer le manager
	manager, err := managers.NewSimpleN8NManager(managerConfig, logger)
	require.NoError(t, err)

	// Créer le bridge
	parameterBridge := bridge.NewParameterBridge(logger)

	// Configuration Queue
	queueConfig := &queue.QueueConfig{
		DefaultWorkers:  3,
		MaxWorkers:      10,
		JobTimeout:      30 * time.Second,
		RetryAttempts:   3,
		RetryBackoff:    1 * time.Second,
		QueueCapacity:   100,
		MetricsInterval: 1 * time.Second,
	}

	// Créer le système de queue
	queueSystem := queue.NewAsyncQueueSystem(queueConfig, logger)

	suite := &IntegrationTestSuite{
		logger:      logger,
		manager:     manager,
		bridge:      parameterBridge,
		queueSystem: queueSystem,
		testResults: &TestResults{
			TestSuites: make(map[string]SuiteResult),
			Errors:     make([]string, 0),
		},
	}

	// Démarrer le serveur HTTP de test
	suite.setupHTTPServer()

	return suite
}

// setupHTTPServer configure le serveur HTTP pour les tests
func (suite *IntegrationTestSuite) setupHTTPServer() {
	mux := http.NewServeMux()

	// Endpoint pour workflow execution
	mux.HandleFunc("/api/v1/workflows/execute", suite.handleWorkflowExecution)

	// Endpoint pour parameter bridging
	mux.HandleFunc("/api/v1/parameters/transform", suite.handleParameterTransform)

	// Endpoint pour job queue
	mux.HandleFunc("/api/v1/jobs/enqueue", suite.handleJobEnqueue)
	mux.HandleFunc("/api/v1/jobs/status", suite.handleJobStatus)

	// Endpoint pour métriques
	mux.HandleFunc("/api/v1/metrics", suite.handleMetrics)

	// Endpoint pour health check
	mux.HandleFunc("/health", suite.handleHealthCheck)

	suite.httpServer = httptest.NewServer(mux)
	suite.logger.Info("Test HTTP server started", zap.String("url", suite.httpServer.URL))
}

// TestN8NToGoWorkflowExecution teste l'exécution complète N8N → Go
func TestN8NToGoWorkflowExecution(t *testing.T) {
	suite := NewIntegrationTestSuite(t)
	defer suite.Cleanup()

	startTime := time.Now()

	ctx := context.Background()

	// 1. Démarrer les composants
	err := suite.manager.Start(ctx)
	require.NoError(t, err)

	// 2. Préparer la requête N8N
	workflowRequest := &N8NWorkflowRequest{
		WorkflowID: "email-workflow-001",
		NodeID:     "go-cli-node-001",
		Parameters: map[string]interface{}{
			"recipient": "test@example.com",
			"subject":   "Test Email",
			"body":      "This is a test email from N8N integration test",
			"timeout":   30,
			"async":     false,
		},
		InputData: []interface{}{
			map[string]interface{}{
				"user_id": 12345,
				"action":  "send_email",
				"data":    map[string]interface{}{"priority": "high"},
			},
		},
		Options: map[string]interface{}{
			"enableTracing": true,
			"timeout":       30,
		},
		TraceID:       uuid.New().String(),
		CorrelationID: uuid.New().String(),
	}

	// 3. Exécuter le workflow via le manager
	managerRequest := &managers.WorkflowRequest{
		WorkflowID:    workflowRequest.WorkflowID,
		NodeID:        workflowRequest.NodeID,
		Parameters:    workflowRequest.Parameters,
		InputData:     workflowRequest.InputData,
		TraceID:       workflowRequest.TraceID,
		CorrelationID: workflowRequest.CorrelationID,
	}

	response, err := suite.manager.ExecuteWorkflow(ctx, managerRequest)
	require.NoError(t, err)
	require.NotNil(t, response)

	// 4. Valider la réponse
	assert.Equal(t, managers.ExecutionStatusSuccess, response.Status)
	assert.NotEmpty(t, response.ExecutionID)
	assert.Equal(t, workflowRequest.TraceID, response.TraceID)
	assert.Equal(t, workflowRequest.CorrelationID, response.CorrelationID)
	assert.NotNil(t, response.Metrics)
	assert.True(t, response.Metrics.Duration > 0)

	// 5. Vérifier les données de sortie
	assert.NotEmpty(t, response.OutputData)
	assert.Empty(t, response.Errors)

	executionTime := time.Since(startTime)
	suite.recordTestResult("N8NToGoWorkflowExecution", true, executionTime, nil)

	suite.logger.Info("N8N to Go workflow execution test completed",
		zap.String("execution_id", response.ExecutionID),
		zap.Duration("execution_time", executionTime))
}

// TestParameterBridgeTransformation teste la transformation des paramètres
func TestParameterBridgeTransformation(t *testing.T) {
	suite := NewIntegrationTestSuite(t)
	defer suite.Cleanup()

	startTime := time.Now()

	ctx := context.Background()

	// 1. Préparer les paramètres N8N
	bridgeRequest := &bridge.BridgeRequest{
		Parameters: []bridge.N8NParameter{
			{Name: "recipient", Value: "user@example.com", Type: "string", Required: true, Source: "input"},
			{Name: "timeout", Value: "30", Type: "number", Required: false, Source: "config"},
			{Name: "async", Value: "true", Type: "boolean", Required: false, Source: "config"},
			{Name: "tags", Value: "urgent,important", Type: "array", Required: false, Source: "input"},
			{Name: "metadata", Value: `{"priority": "high", "category": "test"}`, Type: "object", Required: false, Source: "input"},
		},
		TargetSchema:  "email",
		Context:       map[string]interface{}{"workflow_id": "email-workflow-001"},
		TraceID:       uuid.New().String(),
		CorrelationID: uuid.New().String(),
	}

	// 2. Exécuter la transformation
	response, err := suite.bridge.TransformParameters(ctx, bridgeRequest)
	require.NoError(t, err)
	require.NotNil(t, response)

	// 3. Valider la transformation
	assert.True(t, response.Success)
	assert.Equal(t, len(bridgeRequest.Parameters), len(response.Parameters))
	assert.Equal(t, len(bridgeRequest.Parameters), len(response.ParameterMap))
	assert.Empty(t, response.ValidationErrors)

	// 4. Vérifier les types transformés
	for _, param := range response.Parameters {
		switch param.Name {
		case "recipient":
			assert.Equal(t, "string", param.Type)
			assert.Equal(t, "user@example.com", param.Value)
		case "timeout":
			assert.Equal(t, "float64", param.Type)
			assert.Equal(t, float64(30), param.Value)
		case "async":
			assert.Equal(t, "bool", param.Type)
			assert.Equal(t, true, param.Value)
		case "tags":
			assert.Equal(t, "array", param.Type)
			tags, ok := param.Value.([]interface{})
			assert.True(t, ok)
			assert.Len(t, tags, 2)
		case "metadata":
			assert.Equal(t, "object", param.Type)
			metadata, ok := param.Value.(map[string]interface{})
			assert.True(t, ok)
			assert.Equal(t, "high", metadata["priority"])
		}
	}

	// 5. Vérifier les statistiques
	assert.Equal(t, len(bridgeRequest.Parameters), response.TransformStats.TotalParameters)
	assert.Equal(t, len(bridgeRequest.Parameters), response.TransformStats.TransformedParams)
	assert.Equal(t, 0, response.TransformStats.ValidationErrors)
	assert.Equal(t, float64(100), response.TransformStats.SuccessRate)

	executionTime := time.Since(startTime)
	suite.recordTestResult("ParameterBridgeTransformation", true, executionTime, nil)

	suite.logger.Info("Parameter bridge transformation test completed",
		zap.Duration("execution_time", executionTime),
		zap.Float64("success_rate", response.TransformStats.SuccessRate))
}

// TestAsyncQueueProcessing teste le système de queue asynchrone
func TestAsyncQueueProcessing(t *testing.T) {
	suite := NewIntegrationTestSuite(t)
	defer suite.Cleanup()

	startTime := time.Now()

	ctx := context.Background()

	// 1. Créer une queue de test
	err := suite.queueSystem.CreateQueue("integration-test-queue", 2)
	require.NoError(t, err)

	// 2. Préparer plusieurs jobs
	jobs := []*queue.Job{
		{
			Type:      "go-cli",
			QueueName: "integration-test-queue",
			Priority:  queue.PriorityNormal,
			Payload: map[string]interface{}{
				"command": "email-sender",
				"args":    []string{"--recipient", "test1@example.com"},
			},
			MaxRetries:    3,
			TraceID:       uuid.New().String(),
			CorrelationID: uuid.New().String(),
		},
		{
			Type:      "data-conversion",
			QueueName: "integration-test-queue",
			Priority:  queue.PriorityHigh,
			Payload: map[string]interface{}{
				"source_format": "n8n",
				"target_format": "go",
				"data":          map[string]interface{}{"test": "data"},
			},
			MaxRetries:    3,
			TraceID:       uuid.New().String(),
			CorrelationID: uuid.New().String(),
		},
		{
			Type:      "parameter-mapping",
			QueueName: "integration-test-queue",
			Priority:  queue.PriorityLow,
			Payload: map[string]interface{}{
				"parameters": map[string]interface{}{"key": "value"},
				"schema":     "test-schema",
			},
			MaxRetries:    3,
			TraceID:       uuid.New().String(),
			CorrelationID: uuid.New().String(),
		},
	}

	// 3. Enqueuer les jobs
	jobIDs := make([]string, len(jobs))
	for i, job := range jobs {
		err := suite.queueSystem.EnqueueJob(job)
		require.NoError(t, err)
		jobIDs[i] = job.ID
	}

	// 4. Attendre le traitement des jobs
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	completedJobs := 0
	for completedJobs < len(jobs) {
		select {
		case <-timeout:
			t.Fatal("Timeout waiting for jobs to complete")
		case <-ticker.C:
			completedJobs = 0
			for _, jobID := range jobIDs {
				job, err := suite.queueSystem.GetJobStatus(jobID)
				if err == nil && (job.Status == queue.JobStatusCompleted || job.Status == queue.JobStatusFailed) {
					completedJobs++
				}
			}
		}
	}

	// 5. Vérifier les résultats des jobs
	successCount := 0
	for _, jobID := range jobIDs {
		job, err := suite.queueSystem.GetJobStatus(jobID)
		require.NoError(t, err)

		if job.Status == queue.JobStatusCompleted {
			successCount++
			assert.NotNil(t, job.Result)
			assert.True(t, job.ExecutionTime > 0)
		}

		assert.NotEmpty(t, job.TraceID)
		assert.NotEmpty(t, job.CorrelationID)
	}

	// 6. Vérifier les métriques de la queue
	metrics := suite.queueSystem.GetMetrics()
	assert.NotNil(t, metrics)
	assert.Contains(t, metrics.QueueStats, "integration-test-queue")

	queueStats := metrics.QueueStats["integration-test-queue"]
	assert.Equal(t, "integration-test-queue", queueStats.Name)
	assert.True(t, queueStats.Completed >= successCount)

	executionTime := time.Since(startTime)
	suite.recordTestResult("AsyncQueueProcessing", true, executionTime, nil)

	suite.logger.Info("Async queue processing test completed",
		zap.Duration("execution_time", executionTime),
		zap.Int("total_jobs", len(jobs)),
		zap.Int("successful_jobs", successCount))
}

// TestEndToEndWorkflow teste le flux complet end-to-end
func TestEndToEndWorkflow(t *testing.T) {
	suite := NewIntegrationTestSuite(t)
	defer suite.Cleanup()

	startTime := time.Now()

	ctx := context.Background()

	// Démarrer tous les composants
	err := suite.manager.Start(ctx)
	require.NoError(t, err)

	// 1. Simulation d'une requête N8N complète
	n8nRequest := map[string]interface{}{
		"operation": "execute",
		"command":   "email-sender",
		"parameters": map[string]interface{}{
			"recipient": "integration-test@example.com",
			"subject":   "Integration Test Email",
			"body":      "This email was sent through the complete N8N/Go integration pipeline",
			"timeout":   "30",
			"async":     "false",
		},
		"inputData": []interface{}{
			map[string]interface{}{
				"user_id": 98765,
				"action":  "send_email",
				"source":  "n8n_integration_test",
			},
		},
		"options": map[string]interface{}{
			"enableTracing": true,
			"timeout":       30,
		},
		"traceId":       uuid.New().String(),
		"correlationId": uuid.New().String(),
	}

	// 2. Étape 1: Transformation des paramètres
	bridgeRequest := &bridge.BridgeRequest{
		Parameters: []bridge.N8NParameter{
			{Name: "recipient", Value: n8nRequest["parameters"].(map[string]interface{})["recipient"], Type: "string", Required: true},
			{Name: "subject", Value: n8nRequest["parameters"].(map[string]interface{})["subject"], Type: "string", Required: true},
			{Name: "body", Value: n8nRequest["parameters"].(map[string]interface{})["body"], Type: "string", Required: true},
			{Name: "timeout", Value: n8nRequest["parameters"].(map[string]interface{})["timeout"], Type: "number", Required: false},
			{Name: "async", Value: n8nRequest["parameters"].(map[string]interface{})["async"], Type: "boolean", Required: false},
		},
		TargetSchema:  "email",
		TraceID:       n8nRequest["traceId"].(string),
		CorrelationID: n8nRequest["correlationId"].(string),
	}

	bridgeResponse, err := suite.bridge.TransformParameters(ctx, bridgeRequest)
	require.NoError(t, err)
	require.True(t, bridgeResponse.Success)

	// 3. Étape 2: Exécution via le manager
	workflowRequest := &managers.WorkflowRequest{
		WorkflowID:    "end-to-end-test-workflow",
		NodeID:        "go-cli-executor",
		Parameters:    bridgeResponse.ParameterMap,
		InputData:     n8nRequest["inputData"].([]interface{}),
		TraceID:       n8nRequest["traceId"].(string),
		CorrelationID: n8nRequest["correlationId"].(string),
	}

	workflowResponse, err := suite.manager.ExecuteWorkflow(ctx, workflowRequest)
	require.NoError(t, err)
	require.Equal(t, managers.ExecutionStatusSuccess, workflowResponse.Status)

	// 4. Validation des résultats end-to-end
	assert.NotEmpty(t, workflowResponse.ExecutionID)
	assert.Equal(t, n8nRequest["traceId"], workflowResponse.TraceID)
	assert.Equal(t, n8nRequest["correlationId"], workflowResponse.CorrelationID)
	assert.NotNil(t, workflowResponse.Metrics)
	assert.NotEmpty(t, workflowResponse.OutputData)
	assert.Empty(t, workflowResponse.Errors)

	// 5. Vérification de la propagation des IDs de corrélation
	assert.Equal(t, bridgeRequest.TraceID, workflowResponse.TraceID)
	assert.Equal(t, bridgeRequest.CorrelationID, workflowResponse.CorrelationID)

	executionTime := time.Since(startTime)
	suite.recordTestResult("EndToEndWorkflow", true, executionTime, nil)

	suite.logger.Info("End-to-end workflow test completed",
		zap.String("execution_id", workflowResponse.ExecutionID),
		zap.Duration("total_execution_time", executionTime),
		zap.Duration("workflow_execution_time", workflowResponse.Metrics.Duration))
}

// HTTP Handlers pour les tests

func (suite *IntegrationTestSuite) handleWorkflowExecution(w http.ResponseWriter, r *http.Request) {
	var request N8NWorkflowRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	response := map[string]interface{}{
		"success":       true,
		"executionId":   uuid.New().String(),
		"status":        "completed",
		"outputData":    []interface{}{"Workflow executed successfully"},
		"traceId":       request.TraceID,
		"correlationId": request.CorrelationID,
		"metrics": map[string]interface{}{
			"duration":      "150ms",
			"nodesExecuted": 1,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (suite *IntegrationTestSuite) handleParameterTransform(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"success": true,
		"transformedParameters": map[string]interface{}{
			"recipient": "test@example.com",
			"subject":   "Test Subject",
		},
		"stats": map[string]interface{}{
			"totalParameters":   2,
			"transformedParams": 2,
			"successRate":       100.0,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (suite *IntegrationTestSuite) handleJobEnqueue(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"success": true,
		"jobId":   uuid.New().String(),
		"status":  "queued",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (suite *IntegrationTestSuite) handleJobStatus(w http.ResponseWriter, r *http.Request) {
	jobID := r.URL.Query().Get("jobId")

	response := map[string]interface{}{
		"jobId":     jobID,
		"status":    "completed",
		"result":    "Job completed successfully",
		"startTime": time.Now().Add(-1 * time.Minute),
		"endTime":   time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (suite *IntegrationTestSuite) handleMetrics(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"totalQueues":    1,
		"totalWorkers":   3,
		"processedJobs":  10,
		"failedJobs":     0,
		"averageLatency": "50ms",
		"throughput":     100.5,
		"uptime":         "5m30s",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (suite *IntegrationTestSuite) handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":  "healthy",
		"version": "1.0.0-test",
		"uptime":  "5m30s",
		"components": map[string]interface{}{
			"manager": "healthy",
			"bridge":  "healthy",
			"queue":   "healthy",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Utility methods

func (suite *IntegrationTestSuite) recordTestResult(testName string, passed bool, duration time.Duration, err error) {
	suite.testResults.TotalTests++
	if passed {
		suite.testResults.PassedTests++
	} else {
		suite.testResults.FailedTests++
		if err != nil {
			suite.testResults.Errors = append(suite.testResults.Errors, fmt.Sprintf("%s: %s", testName, err.Error()))
		}
	}

	suite.testResults.ExecutionTime += duration
}

func (suite *IntegrationTestSuite) Cleanup() {
	if suite.httpServer != nil {
		suite.httpServer.Close()
	}

	if suite.queueSystem != nil {
		suite.queueSystem.Shutdown()
	}

	if suite.manager != nil {
		suite.manager.Stop()
	}

	suite.logger.Info("Integration test suite cleanup completed")
}

// TestRunner fonction principale pour exécuter tous les tests
func TestIntegrationSuite(t *testing.T) {
	suite := NewIntegrationTestSuite(t)
	defer suite.Cleanup()

	startTime := time.Now()

	// Exécuter tous les tests d'intégration
	t.Run("N8NToGoWorkflowExecution", TestN8NToGoWorkflowExecution)
	t.Run("ParameterBridgeTransformation", TestParameterBridgeTransformation)
	t.Run("AsyncQueueProcessing", TestAsyncQueueProcessing)
	t.Run("EndToEndWorkflow", TestEndToEndWorkflow)

	totalTime := time.Since(startTime)

	// Générer le rapport final
	suite.generateTestReport(totalTime)
}

func (suite *IntegrationTestSuite) generateTestReport(totalTime time.Duration) {
	suite.testResults.ExecutionTime = totalTime
	suite.testResults.Coverage = float64(suite.testResults.PassedTests) / float64(suite.testResults.TotalTests) * 100

	report, _ := json.MarshalIndent(suite.testResults, "", "  ")

	suite.logger.Info("Integration Test Report",
		zap.String("report", string(report)))
}
