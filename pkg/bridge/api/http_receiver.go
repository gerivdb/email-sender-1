package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

// HTTPReceiver implémente N8NReceiver avec HTTP
type HTTPReceiver struct {
	processorFactory ProcessorFactory
	activeWorkflows  map[string]*WorkflowStatus
	mu               sync.RWMutex
	startTime        time.Time
	version          string
}

// NewHTTPReceiver crée une nouvelle instance de HTTPReceiver
func NewHTTPReceiver(factory ProcessorFactory) *HTTPReceiver {
	return &HTTPReceiver{
		processorFactory: factory,
		activeWorkflows:  make(map[string]*WorkflowStatus),
		startTime:        time.Now(),
		version:          "1.0.0",
	}
}

// RegisterRoutes enregistre les routes HTTP
func (h *HTTPReceiver) RegisterRoutes(router *http.ServeMux) {
	// Endpoints principaux
	router.HandleFunc("/api/v1/workflow/execute", h.HandleWorkflowHTTP)
	router.HandleFunc("/api/v1/workflow/status", h.HandleStatusHTTP)
	router.HandleFunc("/api/v1/workflow/cancel", h.handleCancelHTTP)
	router.HandleFunc("/api/v1/workflow/list", h.handleListHTTP)
	router.HandleFunc("/api/v1/health", h.HandleHealthHTTP)

	// Documentation
	router.HandleFunc("/api/v1/docs", h.handleDocsHTTP)
	router.HandleFunc("/api/v1/capabilities", h.handleCapabilitiesHTTP)
}

// HandleWorkflowHTTP handler HTTP pour l'exécution de workflows
func (h *HTTPReceiver) HandleWorkflowHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req WorkflowRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response := NewErrorResponse("", "INVALID_JSON", fmt.Sprintf("Invalid JSON: %v", err))
		h.writeJSONResponse(w, response, http.StatusBadRequest)
		return
	}

	if err := req.Validate(); err != nil {
		response := NewErrorResponse(req.ExecutionID, "VALIDATION_ERROR", err.Error())
		h.writeJSONResponse(w, response, http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	response, err := h.HandleWorkflow(ctx, &req)
	if err != nil {
		log.Printf("Error processing workflow %s: %v", req.ExecutionID, err)
		response = NewErrorResponse(req.ExecutionID, "PROCESSING_ERROR", err.Error())
		h.writeJSONResponse(w, response, http.StatusInternalServerError)
		return
	}

	statusCode := http.StatusOK
	if !response.Success {
		statusCode = http.StatusInternalServerError
	}

	h.writeJSONResponse(w, response, statusCode)
}

// HandleWorkflow implémente l'interface N8NReceiver
func (h *HTTPReceiver) HandleWorkflow(ctx context.Context, req *WorkflowRequest) (*WorkflowResponse, error) {
	startTime := time.Now()

	// Créer le statut du workflow
	status := &WorkflowStatus{
		ExecutionID: req.ExecutionID,
		WorkflowID:  req.WorkflowID,
		Status:      StatusProcessing,
		Progress:    0.0,
		StartedAt:   startTime,
		UpdatedAt:   startTime,
		CurrentStep: "initializing",
	}

	h.mu.Lock()
	h.activeWorkflows[req.ExecutionID] = status
	h.mu.Unlock()

	// Obtenir le processeur approprié
	processor, err := h.processorFactory.CreateProcessor(req.ProcessingType)
	if err != nil {
		h.mu.Lock()
		status.Status = StatusFailed
		status.ErrorDetails = &ErrorDetails{
			Code:      "PROCESSOR_NOT_FOUND",
			Message:   fmt.Sprintf("No processor found for type: %s", req.ProcessingType),
			Component: "factory",
			Timestamp: time.Now(),
		}
		h.mu.Unlock()
		return NewErrorResponse(req.ExecutionID, "PROCESSOR_NOT_FOUND", err.Error()), err
	}

	// Vérifier si le processeur peut traiter la requête
	if !processor.CanProcess(req) {
		h.mu.Lock()
		status.Status = StatusFailed
		h.mu.Unlock()
		return NewErrorResponse(req.ExecutionID, "CANNOT_PROCESS", "Processor cannot handle this request"),
			fmt.Errorf("processor cannot handle request")
	}

	// Estimer la durée et mettre à jour l'ETA
	estimatedDuration := processor.EstimateDuration(req)
	eta := startTime.Add(estimatedDuration)

	h.mu.Lock()
	status.EstimatedETA = &eta
	status.CurrentStep = "processing"
	status.Progress = 0.1
	h.mu.Unlock()

	// Traiter la requête
	response, err := processor.Process(ctx, req)
	if err != nil {
		h.mu.Lock()
		status.Status = StatusFailed
		status.ErrorDetails = &ErrorDetails{
			Code:      "PROCESSING_FAILED",
			Message:   err.Error(),
			Component: "processor",
			Timestamp: time.Now(),
		}
		h.mu.Unlock()
		return NewErrorResponse(req.ExecutionID, "PROCESSING_FAILED", err.Error()), err
	}

	// Mettre à jour le statut final
	h.mu.Lock()
	status.Status = StatusCompleted
	status.Progress = 1.0
	status.UpdatedAt = time.Now()
	status.CurrentStep = "completed"
	h.mu.Unlock()

	// Calculer la durée réelle
	duration := time.Since(startTime).Milliseconds()
	response.Duration = duration

	return response, nil
}

// HandleStatusHTTP handler HTTP pour le statut
func (h *HTTPReceiver) HandleStatusHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	executionID := r.URL.Query().Get("execution_id")
	if executionID == "" {
		http.Error(w, "execution_id parameter required", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	status, err := h.GetStatus(ctx, executionID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Status not found: %v", err), http.StatusNotFound)
		return
	}

	h.writeJSONResponse(w, status, http.StatusOK)
}

// GetStatus implémente l'interface N8NReceiver
func (h *HTTPReceiver) GetStatus(ctx context.Context, executionID string) (*WorkflowStatus, error) {
	h.mu.RLock()
	status, exists := h.activeWorkflows[executionID]
	h.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("workflow execution %s not found", executionID)
	}
	return status, nil
}

// HandleHealthHTTP handler HTTP pour la santé
func (h *HTTPReceiver) HandleHealthHTTP(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	health, err := h.HealthCheck(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("Health check failed: %v", err), http.StatusInternalServerError)
		return
	}

	statusCode := http.StatusOK
	if health.Status != "healthy" {
		statusCode = http.StatusServiceUnavailable
	}

	h.writeJSONResponse(w, health, statusCode)
}

// HealthCheck implémente l'interface N8NReceiver
func (h *HTTPReceiver) HealthCheck(ctx context.Context) (*HealthStatus, error) {
	uptime := time.Since(h.startTime)

	// Vérifier les dépendances (simulé)
	dependencies := map[string]string{
		"processor_factory": "healthy",
		"memory":            "healthy",
		"goroutines":        "healthy",
	}

	// Métriques de base
	h.mu.RLock()
	activeCount := len(h.activeWorkflows)
	h.mu.RUnlock()

	metrics := map[string]interface{}{
		"active_workflows":     activeCount,
		"uptime_seconds":       uptime.Seconds(),
		"version":              h.version,
		"available_processors": len(h.processorFactory.ListAvailableProcessors()),
	}

	return &HealthStatus{
		Status:       "healthy",
		Version:      h.version,
		Uptime:       uptime,
		Dependencies: dependencies,
		Metrics:      metrics,
		Timestamp:    time.Now(),
	}, nil
}

// CancelWorkflow implémente l'interface N8NReceiver
func (h *HTTPReceiver) CancelWorkflow(ctx context.Context, executionID string) error {
	h.mu.Lock()
	defer h.mu.Unlock()

	status, exists := h.activeWorkflows[executionID]
	if !exists {
		return fmt.Errorf("workflow execution %s not found", executionID)
	}

	if status.Status == StatusCompleted || status.Status == StatusFailed {
		return fmt.Errorf("workflow %s already finished", executionID)
	}

	status.Status = StatusFailed
	status.ErrorDetails = &ErrorDetails{
		Code:      "CANCELLED",
		Message:   "Workflow cancelled by user",
		Component: "api",
		Timestamp: time.Now(),
	}

	return nil
}

// ListActiveWorkflows implémente l'interface N8NReceiver
func (h *HTTPReceiver) ListActiveWorkflows(ctx context.Context) ([]*WorkflowStatus, error) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	var workflows []*WorkflowStatus
	for _, status := range h.activeWorkflows {
		workflows = append(workflows, status)
	}
	return workflows, nil
}

// Méthodes utilitaires

func (h *HTTPReceiver) writeJSONResponse(w http.ResponseWriter, data interface{}, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Printf("Error encoding JSON response: %v", err)
	}
}

func (h *HTTPReceiver) handleCancelHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	executionID := r.URL.Query().Get("execution_id")
	if executionID == "" {
		http.Error(w, "execution_id parameter required", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	if err := h.CancelWorkflow(ctx, executionID); err != nil {
		http.Error(w, fmt.Sprintf("Cancel failed: %v", err), http.StatusBadRequest)
		return
	}

	response := map[string]interface{}{
		"success":      true,
		"execution_id": executionID,
		"message":      "Workflow cancelled successfully",
	}

	h.writeJSONResponse(w, response, http.StatusOK)
}

func (h *HTTPReceiver) handleListHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()
	workflows, err := h.ListActiveWorkflows(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("List failed: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"success":   true,
		"count":     len(workflows),
		"workflows": workflows,
	}

	h.writeJSONResponse(w, response, http.StatusOK)
}

func (h *HTTPReceiver) handleDocsHTTP(w http.ResponseWriter, r *http.Request) {
	docs := map[string]interface{}{
		"version": h.version,
		"endpoints": map[string]interface{}{
			"POST /api/v1/workflow/execute": "Execute a workflow",
			"GET /api/v1/workflow/status":   "Get workflow status",
			"POST /api/v1/workflow/cancel":  "Cancel a workflow",
			"GET /api/v1/workflow/list":     "List active workflows",
			"GET /api/v1/health":            "Health check",
			"GET /api/v1/capabilities":      "Get service capabilities",
		},
		"example_request": WorkflowRequest{
			WorkflowID:     "example-workflow",
			ExecutionID:    "exec-123",
			ProcessingType: ProcessingEmailSend,
			Data:           map[string]interface{}{"email": "test@example.com"},
			CallbackURL:    "http://n8n:5678/webhook/callback",
			Timeout:        300,
		},
	}

	h.writeJSONResponse(w, docs, http.StatusOK)
}

func (h *HTTPReceiver) handleCapabilitiesHTTP(w http.ResponseWriter, r *http.Request) {
	capabilities := map[string]interface{}{
		"supported_processing_types": h.processorFactory.ListAvailableProcessors(),
		"max_concurrent_workflows":   100,
		"version":                    h.version,
		"features": []string{
			"workflow_execution",
			"status_tracking",
			"cancellation",
			"health_monitoring",
		},
	}

	h.writeJSONResponse(w, capabilities, http.StatusOK)
}
