package api

import (
	"context"
	"net/http"
	"time"
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
	ExecutionID  string           `json:"execution_id"`
	WorkflowID   string           `json:"workflow_id"`
	Status       ProcessingStatus `json:"status"`
	Progress     float64          `json:"progress"` // 0.0 to 1.0
	StartedAt    time.Time        `json:"started_at"`
	UpdatedAt    time.Time        `json:"updated_at"`
	EstimatedETA *time.Time       `json:"estimated_eta,omitempty"`
	CurrentStep  string           `json:"current_step,omitempty"`
	ErrorDetails *ErrorDetails    `json:"error_details,omitempty"`
}

// HealthStatus représente l'état de santé du service
type HealthStatus struct {
	Status       string                 `json:"status"` // healthy, degraded, unhealthy
	Version      string                 `json:"version"`
	Uptime       time.Duration          `json:"uptime"`
	Dependencies map[string]string      `json:"dependencies"` // service -> status
	Metrics      map[string]interface{} `json:"metrics"`
	Timestamp    time.Time              `json:"timestamp"`
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
	MaxConcurrency   int              `json:"max_concurrency"`
	SupportedTypes   []ProcessingType `json:"supported_types"`
	MaxPayloadSize   int64            `json:"max_payload_size"`
	EstimatedLatency time.Duration    `json:"estimated_latency"`
	RequiresAuth     bool             `json:"requires_auth"`
	SupportsBatching bool             `json:"supports_batching"`
}
