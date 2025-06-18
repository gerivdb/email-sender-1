package api

import (
	"encoding/json"
	"time"
)

// WorkflowRequest représente une requête de workflow depuis N8N
type WorkflowRequest struct {
	WorkflowID     string                 `json:"workflow_id" validate:"required"`
	ExecutionID    string                 `json:"execution_id" validate:"required"`
	Data           map[string]interface{} `json:"data"`
	ProcessingType ProcessingType         `json:"processing_type" validate:"required"`
	CallbackURL    string                 `json:"callback_url" validate:"url"`
	Timeout        int                    `json:"timeout" validate:"min=1,max=3600"` // seconds
	Priority       Priority               `json:"priority"`
	Metadata       WorkflowMetadata       `json:"metadata"`
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
	Code      string    `json:"code"`
	Message   string    `json:"message"`
	Details   string    `json:"details,omitempty"`
	Retryable bool      `json:"retryable"`
	Component string    `json:"component"`
	Timestamp time.Time `json:"timestamp"`
}

// Error implémente l'interface error
func (e *ErrorDetails) Error() string {
	return e.Message
}

// ProcessingType définit le type de traitement demandé
type ProcessingType string

const (
	ProcessingEmailSend      ProcessingType = "email_send"
	ProcessingTemplateRender ProcessingType = "template_render"
	ProcessingValidation     ProcessingType = "validation"
	ProcessingDataTransform  ProcessingType = "data_transform"
	ProcessingBulkOperation  ProcessingType = "bulk_operation"
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
	UserID       string            `json:"user_id,omitempty"`
	WorkflowName string            `json:"workflow_name,omitempty"`
	NodeID       string            `json:"node_id,omitempty"`
	Tags         []string          `json:"tags,omitempty"`
	Custom       map[string]string `json:"custom,omitempty"`
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
