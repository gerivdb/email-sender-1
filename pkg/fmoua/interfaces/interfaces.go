// Package interfaces provides shared interfaces for FMOUA
// Avoids circular dependencies between packages
package interfaces

import (
	"context"
	"time"

	"email_sender/pkg/fmoua/types"
)

// ManagerHub interface for integration operations
type ManagerHub interface {
	Start(ctx context.Context) error
	Stop() error
	GetManager(name string) (Manager, error)
	GetHealthStatus() map[string]HealthStatus
	GetActiveManagers() []string
	ExecuteManagerOperation(managerName, operation string, params map[string]interface{}) (interface{}, error)
}

// Manager interface for individual managers
type Manager interface {
	Name() string
	Status() HealthStatus
	Start(ctx context.Context) error
	Stop() error
	Health() error
}

// HealthStatus represents the health state of a manager
type HealthStatus struct {
	IsHealthy    bool          `json:"is_healthy"`
	LastCheck    time.Time     `json:"last_check"`
	ErrorMessage string        `json:"error_message,omitempty"`
	ResponseTime time.Duration `json:"response_time"`
}

// IntelligenceEngine interface for AI operations
type IntelligenceEngine interface {
	Start(ctx context.Context) error
	Stop() error
	AnalyzeRepository(repoPath string) (*AIDecision, error)
	MakeOrganizationDecision(context map[string]interface{}) (*AIDecision, error)
	OptimizePerformance(metrics map[string]interface{}) (*AIDecision, error)
	GetPerformanceStats() *PerformanceStats
}

// AIDecision represents an AI-powered decision
type AIDecision struct {
	ID             string                 `json:"id"`
	Type           DecisionType           `json:"type"`
	Confidence     float64                `json:"confidence"`
	Recommendation string                 `json:"recommendation"`
	Actions        []RecommendedAction    `json:"actions"`
	Reasoning      string                 `json:"reasoning"`
	Timestamp      time.Time              `json:"timestamp"`
	ExecutionTime  time.Duration          `json:"execution_time"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// DecisionType represents the type of AI decision
type DecisionType string

const (
	DecisionOrganization DecisionType = "organization"
	DecisionOptimization DecisionType = "optimization"
	DecisionCleaning     DecisionType = "cleaning"
	DecisionMaintenance  DecisionType = "maintenance"
	DecisionSecurity     DecisionType = "security"
	DecisionPerformance  DecisionType = "performance"
	DecisionArchitecture DecisionType = "architecture"
)

// RecommendedAction represents an action recommended by AI
type RecommendedAction struct {
	Type       string                 `json:"type"`
	Target     string                 `json:"target"`
	Parameters map[string]interface{} `json:"parameters"`
	Priority   int                    `json:"priority"`
	Risk       string                 `json:"risk"`
	Impact     string                 `json:"impact"`
}

// PerformanceStats tracks performance metrics
type PerformanceStats struct {
	TotalRequests     int64         `json:"total_requests"`
	AverageLatency    time.Duration `json:"average_latency"`
	SuccessRate       float64       `json:"success_rate"`
	CacheHitRate      float64       `json:"cache_hit_rate"`
	LastResponseTime  time.Duration `json:"last_response_time"`
	LatencyUnder100ms int64         `json:"latency_under_100ms"`
}

// FMOUAConfig interface for configuration access
type FMOUAConfig interface {
	GetPerformanceTargets() map[string]interface{}
	IsAIEnabled() bool
	GetEnabledManagers() []string
	GetCleanupLevelConfig(level int) (*types.CleanupLevelConfig, error)
}
