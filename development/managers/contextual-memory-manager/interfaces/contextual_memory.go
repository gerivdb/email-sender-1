package interfaces

import (
	"context"
	"time"

	"github.com/email-sender/development/managers/interfaces"
)

// Action représente une action utilisateur capturée
type Action struct {
	ID            string                 `json:"id"`
	Type          string                 `json:"type"` // command, edit, search, etc.
	Text          string                 `json:"text"`
	WorkspacePath string                 `json:"workspace_path"`
	FilePath      string                 `json:"file_path,omitempty"`
	LineNumber    int                    `json:"line_number,omitempty"`
	Timestamp     time.Time              `json:"timestamp"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
}

// ContextResult représente un résultat de recherche contextuelle
type ContextResult struct {
	ID             string                 `json:"id"`
	Action         Action                 `json:"action"`
	Score          float64                `json:"score"`
	SimilarityType string                 `json:"similarity_type"` // vector, text, hybrid
	Context        map[string]interface{} `json:"context,omitempty"`
}

// ContextQuery représente une requête de recherche contextuelle
type ContextQuery struct {
	Text                string    `json:"text"`
	WorkspacePath       string    `json:"workspace_path,omitempty"`
	ActionTypes         []string  `json:"action_types,omitempty"`
	TimeRange           TimeRange `json:"time_range,omitempty"`
	Limit               int       `json:"limit,omitempty"`
	SimilarityThreshold float64   `json:"similarity_threshold,omitempty"`
}

// TimeRange représente un intervalle de temps
type TimeRange struct {
	Start time.Time `json:"start,omitempty"`
	End   time.Time `json:"end,omitempty"`
}

// ContextualMemoryManager interface principale
type ContextualMemoryManager interface {
	interfaces.BaseManager

	// Indexation
	CaptureAction(ctx context.Context, action Action) error
	BatchCaptureActions(ctx context.Context, actions []Action) error

	// Recherche
	SearchContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	GetActionHistory(ctx context.Context, workspacePath string, limit int) ([]Action, error)

	// Contexte
	UpdateContext(ctx context.Context, contextID string, updates ContextUpdate) error
	GetContextHistory(ctx context.Context, userID string, limit int) ([]ContextResult, error)
	DeleteContext(ctx context.Context, contextID string) error

	// Sessions
	StartSession(ctx context.Context, workspacePath string) (string, error)
	EndSession(ctx context.Context, sessionID string) error
	GetSessionActions(ctx context.Context, sessionID string) ([]Action, error)

	// Analyse
	AnalyzePatternsUsage(ctx context.Context, workspacePath string) (map[string]interface{}, error)
	GetSimilarActions(ctx context.Context, actionID string, limit int) ([]ContextResult, error)

	// Métriques
	GetMetrics(ctx context.Context) (ManagerMetrics, error)
}

// IndexManager interface pour l'indexation
type IndexManager interface {
	interfaces.BaseManager
	IndexAction(ctx context.Context, action Action) error
	SearchSimilar(ctx context.Context, vector []float64, limit int) ([]SimilarResult, error)
	CacheEmbedding(ctx context.Context, text string, vector []float64) error
	GetCacheStats(ctx context.Context) (map[string]interface{}, error)
	DeleteFromIndex(ctx context.Context, contextID string) error
}

// RetrievalManager interface pour la récupération
type RetrievalManager interface {
	interfaces.BaseManager
	SearchContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	UpdateContext(ctx context.Context, contextID string, updates ContextUpdate) error
	GetContextHistory(ctx context.Context, userID string, limit int) ([]ContextResult, error)
	DeleteContext(ctx context.Context, contextID string) error
	QueryContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	GetActionMetadata(ctx context.Context, actionID string) (*Action, error)
	SearchByText(ctx context.Context, text string, workspacePath string, limit int) ([]ContextResult, error)
	GetActionsBySession(ctx context.Context, sessionID string) ([]Action, error)
}

// IntegrationManager interface pour les intégrations externes
type IntegrationManager interface {
	interfaces.BaseManager
	NotifyAction(ctx context.Context, action Action) error
	NotifyContextUpdate(ctx context.Context, contextID string, updates ContextUpdate) error
	NotifyContextDeletion(ctx context.Context, contextID string) error
	NotifyMCPGateway(ctx context.Context, event ContextEvent) error
	TriggerN8NWorkflow(ctx context.Context, workflowID string, data interface{}) error
	SyncToMCPDatabase(ctx context.Context, actions []Action) error
	SendWebhook(ctx context.Context, url string, payload interface{}) error
}

// Types de support
type SimilarResult struct {
	ID    string  `json:"id"`
	Score float64 `json:"score"`
}

type ContextEvent struct {
	Action    Action                 `json:"action"`
	Context   map[string]interface{} `json:"context"`
	Timestamp time.Time              `json:"timestamp"`
}

// ContextUpdate représente une mise à jour de contexte
type ContextUpdate struct {
	Text     string                 `json:"text,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// ManagerMetrics représente les métriques du manager
type ManagerMetrics struct {
	TotalActions      int64             `json:"total_actions"`
	CacheHitRatio     float64           `json:"cache_hit_ratio"`
	AverageLatency    time.Duration     `json:"average_latency"`
	ActiveSessions    int               `json:"active_sessions"`
	MCPNotifications  int64             `json:"mcp_notifications"`
	LastOperationTime time.Time         `json:"last_operation_time"`
	ErrorCount        int64             `json:"error_count"`
	ComponentStatus   map[string]string `json:"component_status"`
}

// MonitoringManager interface pour le monitoring
type MonitoringManager interface {
	interfaces.BaseManager
	RecordOperation(ctx context.Context, operation string, duration time.Duration, err error) error
	GetMetrics(ctx context.Context) (ManagerMetrics, error)
	RecordCacheHit(ctx context.Context, hit bool) error
	IncrementActiveSession(ctx context.Context) error
	DecrementActiveSession(ctx context.Context) error
}
