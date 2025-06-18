package interfaces

import (
	"context"
	"time"
)

// Action reprÃ©sente une action utilisateur capturÃ©e
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

// ContextResult reprÃ©sente un rÃ©sultat de recherche contextuelle
type ContextResult struct {
	ID             string                 `json:"id"`
	Action         Action                 `json:"action"`
	Score          float64                `json:"score"`
	SimilarityType string                 `json:"similarity_type"` // vector, text, hybrid
	Context        map[string]interface{} `json:"context,omitempty"`
}

// ContextQuery reprÃ©sente une requÃªte de recherche contextuelle
type ContextQuery struct {
	Text                string    `json:"text"`
	WorkspacePath       string    `json:"workspace_path,omitempty"`
	ActionTypes         []string  `json:"action_types,omitempty"`
	TimeRange           TimeRange `json:"time_range,omitempty"`
	Limit               int       `json:"limit,omitempty"`
	SimilarityThreshold float64   `json:"similarity_threshold,omitempty"`
}

// TimeRange reprÃ©sente un intervalle de temps
type TimeRange struct {
	Start time.Time `json:"start,omitempty"`
	End   time.Time `json:"end,omitempty"`
}

// BaseManager interface de base pour tous les managers
type BaseManager interface {
	Initialize(ctx context.Context) error
	Cleanup() error
	HealthCheck(ctx context.Context) error
}

// StorageManager interface pour la gestion du stockage
type StorageManager interface {
	BaseManager
	Store(ctx context.Context, key string, value interface{}) error
	Retrieve(ctx context.Context, key string) (interface{}, error)
	Delete(ctx context.Context, key string) error
	List(ctx context.Context, prefix string) ([]string, error)
}

// ErrorManager interface pour la gestion des erreurs
type ErrorManager interface {
	BaseManager
	LogError(ctx context.Context, component string, message string, err error)
	LogWarning(ctx context.Context, component string, message string)
	LogInfo(ctx context.Context, component string, message string)
	GetErrors(ctx context.Context, component string) ([]ErrorRecord, error)
}

// ConfigManager interface pour la gestion de la configuration
type ConfigManager interface {
	BaseManager
	GetString(key string) string
	GetInt(key string) int
	GetBool(key string) bool
	GetFloat64(key string) float64
	Set(key string, value interface{})
	GetAll() map[string]interface{}
}

// ErrorRecord représente un enregistrement d'erreur
type ErrorRecord struct {
	Component string    `json:"component"`
	Message   string    `json:"message"`
	Error     string    `json:"error"`
	Timestamp time.Time `json:"timestamp"`
	Level     string    `json:"level"`
}

// ContextualMemoryManager interface principale
type ContextualMemoryManager interface {
	BaseManager

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

	// MÃ©triques
	GetMetrics(ctx context.Context) (ManagerMetrics, error)

	// MÃ©thodes existantes
	RecordAction(ctx context.Context, action Action) error
	SearchSimilarActions(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	GetContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)

	// Nouvelles mÃ©thodes AST intÃ©grÃ©es
	RecordActionWithAST(ctx context.Context, action Action) (*EnrichedAction, error)
	SearchWithHybridMode(ctx context.Context, query ContextQuery) (*HybridSearchResult, error)
	GetStructuralContext(ctx context.Context, filePath string, lineNumber int) (*StructuralContext, error)

	// Configuration du mode hybride
	SetHybridMode(ctx context.Context, enabled bool) error
	GetHybridConfig(ctx context.Context) (*HybridConfig, error)
	UpdateHybridConfig(ctx context.Context, config *HybridConfig) error

	// MÃ©triques et optimisation
	GetPerformanceMetrics(ctx context.Context) (*PerformanceMetrics, error)
	OptimizeSearchStrategy(ctx context.Context) error
}

// IndexManager interface pour l'indexation
type IndexManager interface {
	BaseManager
	IndexAction(ctx context.Context, action Action) error
	SearchSimilar(ctx context.Context, vector []float64, limit int) ([]SimilarResult, error)
	CacheEmbedding(ctx context.Context, text string, vector []float64) error
	GetCacheStats(ctx context.Context) (map[string]interface{}, error)
	DeleteFromIndex(ctx context.Context, contextID string) error
}

// RetrievalManager interface pour la rÃ©cupÃ©ration
type RetrievalManager interface {
	BaseManager
	SearchContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	UpdateContext(ctx context.Context, contextID string, updates ContextUpdate) error
	GetContextHistory(ctx context.Context, userID string, limit int) ([]ContextResult, error)
	DeleteContext(ctx context.Context, contextID string) error
	QueryContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
	GetActionMetadata(ctx context.Context, actionID string) (*Action, error)
	SearchByText(ctx context.Context, text string, workspacePath string, limit int) ([]ContextResult, error)
	GetActionsBySession(ctx context.Context, sessionID string) ([]Action, error)
}

// IntegrationManager interface pour les intÃ©grations externes
type IntegrationManager interface {
	BaseManager
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

// ContextUpdate reprÃ©sente une mise Ã  jour de contexte
type ContextUpdate struct {
	Text     string                 `json:"text,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// ManagerMetrics reprÃ©sente les mÃ©triques du manager
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
	BaseManager
	RecordOperation(ctx context.Context, operation string, duration time.Duration, err error) error
	GetMetrics(ctx context.Context) (ManagerMetrics, error)
	RecordCacheHit(ctx context.Context, hit bool) error
	IncrementActiveSession(ctx context.Context) error
	DecrementActiveSession(ctx context.Context) error
}

// Types pour les rÃ©sultats hybrides
type HybridSearchResult struct {
	Query            ContextQuery       `json:"query"`
	UsedMode         AnalysisMode       `json:"used_mode"`
	ASTResults       []StructuralResult `json:"ast_results,omitempty"`
	RAGResults       []ContextResult    `json:"rag_results,omitempty"`
	CombinedResults  []CombinedResult   `json:"combined_results"`
	DecisionMetadata *ModeDecision      `json:"decision_metadata"`
	ProcessingTime   time.Duration      `json:"processing_time"`
	QualityScore     float64            `json:"quality_score"`
}

type CombinedResult struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"` // ast, rag, hybrid
	Content   interface{}            `json:"content"`
	Score     float64                `json:"score"`
	Relevance float64                `json:"relevance"`
	Source    string                 `json:"source"`
	Metadata  map[string]interface{} `json:"metadata"`
}

type PerformanceMetrics struct {
	TotalQueries        int64                  `json:"total_queries"`
	AverageResponseTime time.Duration          `json:"average_response_time"`
	ModeDistribution    map[AnalysisMode]int64 `json:"mode_distribution"`
	CacheHitRate        float64                `json:"cache_hit_rate"`
	ASTPerformance      *ASTPerformanceMetrics `json:"ast_performance"`
	RAGPerformance      *RAGPerformanceMetrics `json:"rag_performance"`
	HybridEfficiency    float64                `json:"hybrid_efficiency"`
	LastOptimization    time.Time              `json:"last_optimization"`
}

type ASTPerformanceMetrics struct {
	AverageAnalysisTime time.Duration `json:"average_analysis_time"`
	CacheHitRate        float64       `json:"cache_hit_rate"`
	SuccessRate         float64       `json:"success_rate"`
	FilesAnalyzed       int64         `json:"files_analyzed"`
}

type RAGPerformanceMetrics struct {
	AverageSearchTime  time.Duration `json:"average_search_time"`
	VectorCacheHitRate float64       `json:"vector_cache_hit_rate"`
	IndexSize          int64         `json:"index_size"`
	EmbeddingQuality   float64       `json:"embedding_quality"`
}
