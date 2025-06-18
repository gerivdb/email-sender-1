# Task 023: Créer Structure API REST N8N→Go
# Durée: 20 minutes max
# Sortie: pkg/bridge/api/n8n_receiver.go + tests

param(
   [string]$OutputDir = "pkg/bridge/api",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 2.1.1 - TÂCHE 023: Créer Structure API REST N8N→Go" -ForegroundColor Cyan
Write-Host "=" * 60

# Création des répertoires de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force -Recurse | Out-Null
}

$Results = @{
   task               = "023-creer-structure-api-rest-n8n-go"
   timestamp          = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   files_created      = @()
   interfaces_created = @()
   endpoints_created  = @()
   tests_created      = @()
   summary            = @{}
   errors             = @()
}

Write-Host "📂 Création de la structure API REST N8N→Go..." -ForegroundColor Yellow

# 1. Créer les types de base pour les workflows
Write-Host "🏗️ Création des types de base..." -ForegroundColor Yellow
try {
   $workflowTypesContent = @'
package api

import (
	"time"
	"encoding/json"
)

// WorkflowRequest représente une requête de workflow depuis N8N
type WorkflowRequest struct {
	WorkflowID   string                 `json:"workflow_id" validate:"required"`
	ExecutionID  string                 `json:"execution_id" validate:"required"`
	Data         map[string]interface{} `json:"data"`
	ProcessingType ProcessingType       `json:"processing_type" validate:"required"`
	CallbackURL  string                 `json:"callback_url" validate:"url"`
	Timeout      int                    `json:"timeout" validate:"min=1,max=3600"` // seconds
	Priority     Priority               `json:"priority"`
	Metadata     WorkflowMetadata       `json:"metadata"`
}

// WorkflowResponse représente la réponse envoyée à N8N
type WorkflowResponse struct {
	Success     bool                   `json:"success"`
	ExecutionID string                 `json:"execution_id"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Error       *ErrorDetails          `json:"error,omitempty"`
	ProcessedAt time.Time              `json:"processed_at"`
	Duration    int64                  `json:"duration_ms"`
	Status      ProcessingStatus       `json:"status"`
}

// ErrorDetails détaille les erreurs survenues
type ErrorDetails struct {
	Code        string `json:"code"`
	Message     string `json:"message"`
	Details     string `json:"details,omitempty"`
	Retryable   bool   `json:"retryable"`
	Component   string `json:"component"`
	Timestamp   time.Time `json:"timestamp"`
}

// ProcessingType définit le type de traitement demandé
type ProcessingType string

const (
	ProcessingEmailSend     ProcessingType = "email_send"
	ProcessingTemplateRender ProcessingType = "template_render"
	ProcessingValidation    ProcessingType = "validation"
	ProcessingDataTransform ProcessingType = "data_transform"
	ProcessingBulkOperation ProcessingType = "bulk_operation"
)

// Priority définit la priorité du traitement
type Priority string

const (
	PriorityLow      Priority = "low"
	PriorityNormal   Priority = "normal"
	PriorityHigh     Priority = "high"
	PriorityCritical Priority = "critical"
)

// ProcessingStatus indique l'état du traitement
type ProcessingStatus string

const (
	StatusPending    ProcessingStatus = "pending"
	StatusProcessing ProcessingStatus = "processing"
	StatusCompleted  ProcessingStatus = "completed"
	StatusFailed     ProcessingStatus = "failed"
	StatusTimeout    ProcessingStatus = "timeout"
)

// WorkflowMetadata contient les métadonnées du workflow
type WorkflowMetadata struct {
	UserID      string            `json:"user_id,omitempty"`
	WorkflowName string           `json:"workflow_name,omitempty"`
	NodeID      string            `json:"node_id,omitempty"`
	Tags        []string          `json:"tags,omitempty"`
	Custom      map[string]string `json:"custom,omitempty"`
}

// Validate vérifie la validité de la requête workflow
func (w *WorkflowRequest) Validate() error {
	if w.WorkflowID == "" {
		return &ErrorDetails{
			Code:      "INVALID_WORKFLOW_ID",
			Message:   "Workflow ID is required",
			Component: "validation",
			Timestamp: time.Now(),
		}
	}
	
	if w.ExecutionID == "" {
		return &ErrorDetails{
			Code:      "INVALID_EXECUTION_ID",
			Message:   "Execution ID is required",
			Component: "validation",
			Timestamp: time.Now(),
		}
	}
	
	if w.Timeout <= 0 || w.Timeout > 3600 {
		w.Timeout = 300 // Default 5 minutes
	}
	
	if w.Priority == "" {
		w.Priority = PriorityNormal
	}
	
	return nil
}

// ToJSON convertit la structure en JSON
func (w *WorkflowRequest) ToJSON() ([]byte, error) {
	return json.Marshal(w)
}

// FromJSON parse un JSON vers la structure
func (w *WorkflowRequest) FromJSON(data []byte) error {
	return json.Unmarshal(data, w)
}

// NewErrorResponse crée une réponse d'erreur
func NewErrorResponse(executionID, code, message string) *WorkflowResponse {
	return &WorkflowResponse{
		Success:     false,
		ExecutionID: executionID,
		Error: &ErrorDetails{
			Code:      code,
			Message:   message,
			Component: "api",
			Timestamp: time.Now(),
		},
		ProcessedAt: time.Now(),
		Status:      StatusFailed,
	}
}

// NewSuccessResponse crée une réponse de succès
func NewSuccessResponse(executionID string, data map[string]interface{}, duration int64) *WorkflowResponse {
	return &WorkflowResponse{
		Success:     true,
		ExecutionID: executionID,
		Data:        data,
		ProcessedAt: time.Now(),
		Duration:    duration,
		Status:      StatusCompleted,
	}
}
'@

   $workflowTypesFile = Join-Path $OutputDir "workflow_types.go"
   $workflowTypesContent | Set-Content $workflowTypesFile -Encoding UTF8
   $Results.files_created += $workflowTypesFile
   Write-Host "✅ Types de base créés: workflow_types.go" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création types: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 2. Créer l'interface N8NReceiver
Write-Host "🔌 Création de l'interface N8NReceiver..." -ForegroundColor Yellow
try {
   $receiverInterfaceContent = @'
package api

import (
	"context"
	"net/http"
)

// N8NReceiver définit l'interface pour recevoir les requêtes de N8N
type N8NReceiver interface {
	// HandleWorkflow traite une requête de workflow depuis N8N
	HandleWorkflow(ctx context.Context, req *WorkflowRequest) (*WorkflowResponse, error)
	
	// GetStatus retourne le statut d'un workflow en cours
	GetStatus(ctx context.Context, executionID string) (*WorkflowStatus, error)
	
	// CancelWorkflow annule un workflow en cours
	CancelWorkflow(ctx context.Context, executionID string) error
	
	// ListActiveWorkflows retourne la liste des workflows actifs
	ListActiveWorkflows(ctx context.Context) ([]*WorkflowStatus, error)
	
	// HealthCheck vérifie la santé du service
	HealthCheck(ctx context.Context) (*HealthStatus, error)
}

// WorkflowStatus représente le statut d'un workflow
type WorkflowStatus struct {
	ExecutionID   string           `json:"execution_id"`
	WorkflowID    string           `json:"workflow_id"`
	Status        ProcessingStatus `json:"status"`
	Progress      float64          `json:"progress"` // 0.0 to 1.0
	StartedAt     time.Time        `json:"started_at"`
	UpdatedAt     time.Time        `json:"updated_at"`
	EstimatedETA  *time.Time       `json:"estimated_eta,omitempty"`
	CurrentStep   string           `json:"current_step,omitempty"`
	ErrorDetails  *ErrorDetails    `json:"error_details,omitempty"`
}

// HealthStatus représente l'état de santé du service
type HealthStatus struct {
	Status       string            `json:"status"` // healthy, degraded, unhealthy
	Version      string            `json:"version"`
	Uptime       time.Duration     `json:"uptime"`
	Dependencies map[string]string `json:"dependencies"` // service -> status
	Metrics      map[string]interface{} `json:"metrics"`
	Timestamp    time.Time         `json:"timestamp"`
}

// HTTPHandler interface pour les handlers HTTP
type HTTPHandler interface {
	// RegisterRoutes enregistre les routes HTTP
	RegisterRoutes(router *http.ServeMux)
	
	// HandleWorkflowHTTP handler HTTP pour les workflows
	HandleWorkflowHTTP(w http.ResponseWriter, r *http.Request)
	
	// HandleStatusHTTP handler HTTP pour le statut
	HandleStatusHTTP(w http.ResponseWriter, r *http.Request)
	
	// HandleHealthHTTP handler HTTP pour la santé
	HandleHealthHTTP(w http.ResponseWriter, r *http.Request)
}

// ProcessorFactory interface pour créer des processeurs
type ProcessorFactory interface {
	// CreateProcessor crée un processeur pour un type donné
	CreateProcessor(processingType ProcessingType) (WorkflowProcessor, error)
	
	// ListAvailableProcessors retourne les processeurs disponibles
	ListAvailableProcessors() []ProcessingType
	
	// ValidateProcessingType vérifie si un type est supporté
	ValidateProcessingType(processingType ProcessingType) bool
}

// WorkflowProcessor interface pour les processeurs de workflow
type WorkflowProcessor interface {
	// Process traite les données du workflow
	Process(ctx context.Context, req *WorkflowRequest) (*WorkflowResponse, error)
	
	// CanProcess vérifie si le processeur peut traiter la requête
	CanProcess(req *WorkflowRequest) bool
	
	// EstimateDuration estime la durée de traitement
	EstimateDuration(req *WorkflowRequest) time.Duration
	
	// GetCapabilities retourne les capacités du processeur
	GetCapabilities() ProcessorCapabilities
}

// ProcessorCapabilities décrit les capacités d'un processeur
type ProcessorCapabilities struct {
	MaxConcurrency     int           `json:"max_concurrency"`
	SupportedTypes     []ProcessingType `json:"supported_types"`
	MaxPayloadSize     int64         `json:"max_payload_size"`
	EstimatedLatency   time.Duration `json:"estimated_latency"`
	RequiresAuth       bool          `json:"requires_auth"`
	SupportsBatching   bool          `json:"supports_batching"`
}
'@

   $receiverInterfaceFile = Join-Path $OutputDir "n8n_receiver.go"
   $receiverInterfaceContent | Set-Content $receiverInterfaceFile -Encoding UTF8
   $Results.files_created += $receiverInterfaceFile
   $Results.interfaces_created += "N8NReceiver"
   $Results.interfaces_created += "HTTPHandler"
   $Results.interfaces_created += "ProcessorFactory"
   $Results.interfaces_created += "WorkflowProcessor"
   Write-Host "✅ Interface N8NReceiver créée: n8n_receiver.go" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création interface: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 3. Créer l'implémentation HTTP du receiver
Write-Host "🌐 Création de l'implémentation HTTP..." -ForegroundColor Yellow
try {
   $httpReceiverContent = @'
package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
	"strings"
	"strconv"
)

// HTTPReceiver implémente N8NReceiver avec HTTP
type HTTPReceiver struct {
	processorFactory ProcessorFactory
	activeWorkflows  map[string]*WorkflowStatus
	startTime       time.Time
	version         string
}

// NewHTTPReceiver crée une nouvelle instance de HTTPReceiver
func NewHTTPReceiver(factory ProcessorFactory) *HTTPReceiver {
	return &HTTPReceiver{
		processorFactory: factory,
		activeWorkflows:  make(map[string]*WorkflowStatus),
		startTime:       time.Now(),
		version:         "1.0.0",
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
	h.activeWorkflows[req.ExecutionID] = status
	
	// Obtenir le processeur approprié
	processor, err := h.processorFactory.CreateProcessor(req.ProcessingType)
	if err != nil {
		status.Status = StatusFailed
		status.ErrorDetails = &ErrorDetails{
			Code:      "PROCESSOR_NOT_FOUND",
			Message:   fmt.Sprintf("No processor found for type: %s", req.ProcessingType),
			Component: "factory",
			Timestamp: time.Now(),
		}
		return NewErrorResponse(req.ExecutionID, "PROCESSOR_NOT_FOUND", err.Error()), err
	}
	
	// Vérifier si le processeur peut traiter la requête
	if !processor.CanProcess(req) {
		status.Status = StatusFailed
		return NewErrorResponse(req.ExecutionID, "CANNOT_PROCESS", "Processor cannot handle this request"), 
			fmt.Errorf("processor cannot handle request")
	}
	
	// Estimer la durée et mettre à jour l'ETA
	estimatedDuration := processor.EstimateDuration(req)
	eta := startTime.Add(estimatedDuration)
	status.EstimatedETA = &eta
	status.CurrentStep = "processing"
	status.Progress = 0.1
	
	// Traiter la requête
	response, err := processor.Process(ctx, req)
	if err != nil {
		status.Status = StatusFailed
		status.ErrorDetails = &ErrorDetails{
			Code:      "PROCESSING_FAILED",
			Message:   err.Error(),
			Component: "processor",
			Timestamp: time.Now(),
		}
		return NewErrorResponse(req.ExecutionID, "PROCESSING_FAILED", err.Error()), err
	}
	
	// Mettre à jour le statut final
	status.Status = StatusCompleted
	status.Progress = 1.0
	status.UpdatedAt = time.Now()
	status.CurrentStep = "completed"
	
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
	status, exists := h.activeWorkflows[executionID]
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
		"memory":           "healthy",
		"goroutines":       "healthy",
	}
	
	// Métriques de base
	metrics := map[string]interface{}{
		"active_workflows":    len(h.activeWorkflows),
		"uptime_seconds":     uptime.Seconds(),
		"version":            h.version,
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
			"GET /api/v1/health":           "Health check",
			"GET /api/v1/capabilities":     "Get service capabilities",
		},
		"example_request": WorkflowRequest{
			WorkflowID:     "example-workflow",
			ExecutionID:    "exec-123",
			ProcessingType: ProcessingEmailSend,
			Data:          map[string]interface{}{"email": "test@example.com"},
			CallbackURL:   "http://n8n:5678/webhook/callback",
			Timeout:       300,
		},
	}
	
	h.writeJSONResponse(w, docs, http.StatusOK)
}

func (h *HTTPReceiver) handleCapabilitiesHTTP(w http.ResponseWriter, r *http.Request) {
	capabilities := map[string]interface{}{
		"supported_processing_types": h.processorFactory.ListAvailableProcessors(),
		"max_concurrent_workflows":  100,
		"version":                   h.version,
		"features": []string{
			"workflow_execution",
			"status_tracking", 
			"cancellation",
			"health_monitoring",
		},
	}
	
	h.writeJSONResponse(w, capabilities, http.StatusOK)
}
'@

   $httpReceiverFile = Join-Path $OutputDir "http_receiver.go"
   $httpReceiverContent | Set-Content $httpReceiverFile -Encoding UTF8
   $Results.files_created += $httpReceiverFile
   
   # Endpoints créés
   $Results.endpoints_created += "/api/v1/workflow/execute"
   $Results.endpoints_created += "/api/v1/workflow/status" 
   $Results.endpoints_created += "/api/v1/workflow/cancel"
   $Results.endpoints_created += "/api/v1/workflow/list"
   $Results.endpoints_created += "/api/v1/health"
   $Results.endpoints_created += "/api/v1/docs"
   $Results.endpoints_created += "/api/v1/capabilities"
   
   Write-Host "✅ Implémentation HTTP créée: http_receiver.go" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création HTTP receiver: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 4. Créer les tests unitaires
Write-Host "🧪 Création des tests unitaires..." -ForegroundColor Yellow
try {
   $testsContent = @'
package api

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// MockProcessorFactory pour les tests
type MockProcessorFactory struct {
	processors map[ProcessingType]*MockProcessor
}

func NewMockProcessorFactory() *MockProcessorFactory {
	return &MockProcessorFactory{
		processors: make(map[ProcessingType]*MockProcessor),
	}
}

func (f *MockProcessorFactory) CreateProcessor(processingType ProcessingType) (WorkflowProcessor, error) {
	if processor, exists := f.processors[processingType]; exists {
		return processor, nil
	}
	// Créer un processeur mock par défaut
	processor := &MockProcessor{
		processingType: processingType,
		canProcess:     true,
		duration:       time.Second,
	}
	f.processors[processingType] = processor
	return processor, nil
}

func (f *MockProcessorFactory) ListAvailableProcessors() []ProcessingType {
	var types []ProcessingType
	for t := range f.processors {
		types = append(types, t)
	}
	if len(types) == 0 {
		return []ProcessingType{ProcessingEmailSend, ProcessingTemplateRender}
	}
	return types
}

func (f *MockProcessorFactory) ValidateProcessingType(processingType ProcessingType) bool {
	_, exists := f.processors[processingType]
	return exists
}

// MockProcessor pour les tests
type MockProcessor struct {
	processingType ProcessingType
	canProcess     bool
	duration       time.Duration
	shouldFail     bool
	result         map[string]interface{}
}

func (p *MockProcessor) Process(ctx context.Context, req *WorkflowRequest) (*WorkflowResponse, error) {
	if p.shouldFail {
		return NewErrorResponse(req.ExecutionID, "MOCK_ERROR", "Mock processor error"), 
			fmt.Errorf("mock processor error")
	}
	
	result := p.result
	if result == nil {
		result = map[string]interface{}{
			"processed": true,
			"type":      string(p.processingType),
		}
	}
	
	return NewSuccessResponse(req.ExecutionID, result, p.duration.Milliseconds()), nil
}

func (p *MockProcessor) CanProcess(req *WorkflowRequest) bool {
	return p.canProcess
}

func (p *MockProcessor) EstimateDuration(req *WorkflowRequest) time.Duration {
	return p.duration
}

func (p *MockProcessor) GetCapabilities() ProcessorCapabilities {
	return ProcessorCapabilities{
		MaxConcurrency:   10,
		SupportedTypes:   []ProcessingType{p.processingType},
		MaxPayloadSize:   1024 * 1024, // 1MB
		EstimatedLatency: p.duration,
		RequiresAuth:     false,
		SupportsBatching: false,
	}
}

// Tests

func TestWorkflowRequest_Validate(t *testing.T) {
	tests := []struct {
		name    string
		req     WorkflowRequest
		wantErr bool
	}{
		{
			name: "valid_request",
			req: WorkflowRequest{
				WorkflowID:     "test-workflow",
				ExecutionID:    "test-execution",
				ProcessingType: ProcessingEmailSend,
				Timeout:        300,
			},
			wantErr: false,
		},
		{
			name: "missing_workflow_id",
			req: WorkflowRequest{
				ExecutionID:    "test-execution", 
				ProcessingType: ProcessingEmailSend,
			},
			wantErr: true,
		},
		{
			name: "missing_execution_id",
			req: WorkflowRequest{
				WorkflowID:     "test-workflow",
				ProcessingType: ProcessingEmailSend,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.req.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("WorkflowRequest.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestHTTPReceiver_HandleWorkflowHTTP(t *testing.T) {
	factory := NewMockProcessorFactory()
	receiver := NewHTTPReceiver(factory)
	
	tests := []struct {
		name           string
		method         string
		body           interface{}
		expectedStatus int
		expectedSuccess bool
	}{
		{
			name:   "valid_workflow_request",
			method: "POST",
			body: WorkflowRequest{
				WorkflowID:     "test-workflow",
				ExecutionID:    "test-execution-1",
				ProcessingType: ProcessingEmailSend,
				Data:          map[string]interface{}{"email": "test@example.com"},
				Timeout:       300,
			},
			expectedStatus:  http.StatusOK,
			expectedSuccess: true,
		},
		{
			name:           "invalid_method",
			method:         "GET",
			body:           nil,
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "invalid_json",
			method:         "POST", 
			body:           "invalid json",
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:   "missing_workflow_id",
			method: "POST",
			body: WorkflowRequest{
				ExecutionID:    "test-execution-2",
				ProcessingType: ProcessingEmailSend,
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var reqBody []byte
			if tt.body != nil {
				if str, ok := tt.body.(string); ok {
					reqBody = []byte(str)
				} else {
					reqBody, _ = json.Marshal(tt.body)
				}
			}

			req := httptest.NewRequest(tt.method, "/api/v1/workflow/execute", bytes.NewReader(reqBody))
			w := httptest.NewRecorder()

			receiver.HandleWorkflowHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}

			if tt.expectedStatus == http.StatusOK {
				var response WorkflowResponse
				if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
					t.Fatalf("Failed to decode response: %v", err)
				}

				if response.Success != tt.expectedSuccess {
					t.Errorf("Expected success %v, got %v", tt.expectedSuccess, response.Success)
				}
			}
		})
	}
}

func TestHTTPReceiver_HandleStatusHTTP(t *testing.T) {
	factory := NewMockProcessorFactory()
	receiver := NewHTTPReceiver(factory)
	
	// Créer un workflow pour tester le statut
	ctx := context.Background()
	req := &WorkflowRequest{
		WorkflowID:     "test-workflow",
		ExecutionID:    "test-execution-status",
		ProcessingType: ProcessingEmailSend,
		Timeout:       300,
	}
	
	// Exécuter le workflow
	_, err := receiver.HandleWorkflow(ctx, req)
	if err != nil {
		t.Fatalf("Failed to execute workflow: %v", err)
	}

	tests := []struct {
		name           string
		executionID    string
		expectedStatus int
	}{
		{
			name:           "existing_execution",
			executionID:    "test-execution-status",
			expectedStatus: http.StatusOK,
		},
		{
			name:           "missing_execution",
			executionID:    "non-existent",
			expectedStatus: http.StatusNotFound,
		},
		{
			name:           "empty_execution_id",
			executionID:    "",
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			url := "/api/v1/workflow/status"
			if tt.executionID != "" {
				url += "?execution_id=" + tt.executionID
			}
			
			req := httptest.NewRequest("GET", url, nil)
			w := httptest.NewRecorder()

			receiver.HandleStatusHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestHTTPReceiver_HandleHealthHTTP(t *testing.T) {
	factory := NewMockProcessorFactory()
	receiver := NewHTTPReceiver(factory)

	req := httptest.NewRequest("GET", "/api/v1/health", nil)
	w := httptest.NewRecorder()

	receiver.HandleHealthHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}

	var health HealthStatus
	if err := json.NewDecoder(w.Body).Decode(&health); err != nil {
		t.Fatalf("Failed to decode health response: %v", err)
	}

	if health.Status != "healthy" {
		t.Errorf("Expected healthy status, got %s", health.Status)
	}

	if health.Version != receiver.version {
		t.Errorf("Expected version %s, got %s", receiver.version, health.Version)
	}
}

func TestNewErrorResponse(t *testing.T) {
	response := NewErrorResponse("test-exec", "TEST_ERROR", "Test error message")
	
	if response.Success {
		t.Error("Expected success to be false")
	}
	
	if response.ExecutionID != "test-exec" {
		t.Errorf("Expected execution ID 'test-exec', got '%s'", response.ExecutionID)
	}
	
	if response.Error.Code != "TEST_ERROR" {
		t.Errorf("Expected error code 'TEST_ERROR', got '%s'", response.Error.Code)
	}
	
	if response.Status != StatusFailed {
		t.Errorf("Expected status 'failed', got '%s'", response.Status)
	}
}

func TestNewSuccessResponse(t *testing.T) {
	data := map[string]interface{}{"result": "success"}
	response := NewSuccessResponse("test-exec", data, 1000)
	
	if !response.Success {
		t.Error("Expected success to be true")
	}
	
	if response.ExecutionID != "test-exec" {
		t.Errorf("Expected execution ID 'test-exec', got '%s'", response.ExecutionID)
	}
	
	if response.Duration != 1000 {
		t.Errorf("Expected duration 1000, got %d", response.Duration)
	}
	
	if response.Status != StatusCompleted {
		t.Errorf("Expected status 'completed', got '%s'", response.Status)
	}
}
'@

   $testsFile = Join-Path $OutputDir "n8n_receiver_test.go"
   $testsContent | Set-Content $testsFile -Encoding UTF8
   $Results.files_created += $testsFile
   $Results.tests_created += "TestWorkflowRequest_Validate"
   $Results.tests_created += "TestHTTPReceiver_HandleWorkflowHTTP"
   $Results.tests_created += "TestHTTPReceiver_HandleStatusHTTP"
   $Results.tests_created += "TestHTTPReceiver_HandleHealthHTTP"
   $Results.tests_created += "TestNewErrorResponse"
   $Results.tests_created += "TestNewSuccessResponse"
   
   Write-Host "✅ Tests unitaires créés: n8n_receiver_test.go" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création tests: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 5. Créer un fichier go.mod pour le module bridge s'il n'existe pas
Write-Host "📦 Vérification module Go..." -ForegroundColor Yellow
try {
   $goModPath = "go.mod"
   if (!(Test-Path $goModPath)) {
      $goModContent = @'
module email_sender

go 1.21

require (
	github.com/stretchr/testify v1.8.4
	github.com/go-playground/validator/v10 v10.15.4
)
'@
      $goModContent | Set-Content $goModPath -Encoding UTF8
      Write-Host "✅ Fichier go.mod créé" -ForegroundColor Green
   }
   else {
      Write-Host "✅ Module Go existant détecté" -ForegroundColor Green
   }
}
catch {
   $errorMsg = "Erreur module Go: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds   = $TotalDuration
   files_created_count      = $Results.files_created.Count
   interfaces_created_count = $Results.interfaces_created.Count
   endpoints_created_count  = $Results.endpoints_created.Count
   tests_created_count      = $Results.tests_created.Count
   errors_count             = $Results.errors.Count
   status                   = if ($Results.errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
}

# Sauvegarde des résultats
$outputReportFile = Join-Path "output/phase2" "task-023-results.json"
if (!(Test-Path "output/phase2")) {
   New-Item -ItemType Directory -Path "output/phase2" -Force | Out-Null
}
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputReportFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 023:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Fichiers créés: $($Results.summary.files_created_count)" -ForegroundColor White
Write-Host "   Interfaces créées: $($Results.summary.interfaces_created_count)" -ForegroundColor White
Write-Host "   Endpoints créés: $($Results.summary.endpoints_created_count)" -ForegroundColor White
Write-Host "   Tests créés: $($Results.summary.tests_created_count)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "📁 FICHIERS CRÉÉS:" -ForegroundColor Cyan
foreach ($file in $Results.files_created) {
   Write-Host "   📄 $file" -ForegroundColor White
}

Write-Host ""
Write-Host "🔌 INTERFACES CRÉÉES:" -ForegroundColor Cyan
foreach ($interface in $Results.interfaces_created) {
   Write-Host "   🔗 $interface" -ForegroundColor White
}

Write-Host ""
Write-Host "🌐 ENDPOINTS CRÉÉS:" -ForegroundColor Cyan
foreach ($endpoint in $Results.endpoints_created) {
   Write-Host "   🌍 $endpoint" -ForegroundColor White
}

if ($Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "💾 Rapport sauvé: $outputReportFile" -ForegroundColor Green
Write-Host ""
Write-Host "✅ TÂCHE 023 TERMINÉE" -ForegroundColor Green
