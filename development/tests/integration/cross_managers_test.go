package integration

import (
	"context"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// === PHASE 5.1.2: TESTS D'INTÉGRATION CROSS-MANAGERS ===

// CrossManagersTestSuite suite de tests d'intégration entre managers
type CrossManagersTestSuite struct {
	suite.Suite
	dependencyManager   DependencyManager
	planningEcosync     PlanningEcosystemSync
	storageManager      StorageManager
	securityManager     SecurityManager
	vectorizationEngine VectorizationEngine
	ctx                 context.Context
	testEnvironment     *TestEnvironment
}

// Interfaces pour les managers
type DependencyManager interface {
	AutoVectorize(ctx context.Context, deps []Dependency) error
	SearchSemantic(ctx context.Context, query string, limit int) ([]SemanticResult, error)
	EnableVectorization() error
	DisableVectorization() error
	GetVectorizationStatus() bool
	NotifyVectorizationEvent(ctx context.Context, event VectorizationEvent) error
}

type PlanningEcosystemSync interface {
	SyncWithDependencyManager(ctx context.Context) error
	DetectConflicts(ctx context.Context) ([]Conflict, error)
	ResolveConflicts(ctx context.Context, conflicts []Conflict) error
	HandleVectorizationEvent(ctx context.Context, event VectorizationEvent) error
	GetSyncStatus() SyncStatus
}

type StorageManager interface {
	AutoIndex(ctx context.Context, data interface{}) error
	VectorizeSchema(ctx context.Context, schema Schema) ([]float32, error)
	SearchSemantic(ctx context.Context, query string, options SearchOptions) ([]SemanticResult, error)
	OptimizeStorage(ctx context.Context) error
}

type SecurityManager interface {
	VectorizePolicy(ctx context.Context, policy SecurityPolicy) ([]float32, error)
	DetectAnomalies(ctx context.Context, data interface{}) ([]Anomaly, error)
	ClassifyVulnerability(ctx context.Context, vuln Vulnerability) (Classification, error)
	GetSecurityMetrics() SecurityMetrics
}

type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	ParseMarkdown(content string) (*MarkdownDocument, error)
	CacheEmbedding(key string, embedding []float32) error
	GetCachedEmbedding(key string) ([]float32, bool)
}

// Types pour les tests
type Dependency struct {
	Name        string            `json:"name"`
	Version     string            `json:"version"`
	Type        string            `json:"type"`
	Description string            `json:"description"`
	Metadata    map[string]string `json:"metadata"`
}

type SemanticResult struct {
	ID       string                 `json:"id"`
	Score    float32                `json:"score"`
	Content  string                 `json:"content"`
	Metadata map[string]interface{} `json:"metadata"`
}

type VectorizationEvent struct {
	Type      string                 `json:"type"`
	Source    string                 `json:"source"`
	Target    string                 `json:"target"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
}

type Conflict struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Severity    string    `json:"severity"`
	Source      string    `json:"source"`
	Target      string    `json:"target"`
	CreatedAt   time.Time `json:"created_at"`
}

type SyncStatus struct {
	IsActive      bool      `json:"is_active"`
	LastSync      time.Time `json:"last_sync"`
	ConflictCount int       `json:"conflict_count"`
	ErrorCount    int       `json:"error_count"`
}

type Schema struct {
	Name        string                 `json:"name"`
	Fields      map[string]FieldType   `json:"fields"`
	Constraints map[string]interface{} `json:"constraints"`
	Version     string                 `json:"version"`
}

type FieldType struct {
	Type        string `json:"type"`
	Required    bool   `json:"required"`
	Description string `json:"description"`
}

type SearchOptions struct {
	Limit     int                    `json:"limit"`
	Threshold float32                `json:"threshold"`
	Filters   map[string]interface{} `json:"filters"`
	SortBy    string                 `json:"sort_by"`
	Ascending bool                   `json:"ascending"`
}

type SecurityPolicy struct {
	ID         string                 `json:"id"`
	Name       string                 `json:"name"`
	Rules      []SecurityRule         `json:"rules"`
	Conditions map[string]interface{} `json:"conditions"`
	Actions    []SecurityAction       `json:"actions"`
	Priority   int                    `json:"priority"`
}

type SecurityRule struct {
	ID          string `json:"id"`
	Description string `json:"description"`
	Pattern     string `json:"pattern"`
	Severity    string `json:"severity"`
}

type SecurityAction struct {
	Type        string                 `json:"type"`
	Parameters  map[string]interface{} `json:"parameters"`
	Description string                 `json:"description"`
}

type Anomaly struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Severity    string                 `json:"severity"`
	Description string                 `json:"description"`
	Data        map[string]interface{} `json:"data"`
	Score       float32                `json:"score"`
	DetectedAt  time.Time              `json:"detected_at"`
}

type Vulnerability struct {
	ID          string                 `json:"id"`
	CVE         string                 `json:"cve"`
	Description string                 `json:"description"`
	Severity    string                 `json:"severity"`
	Component   string                 `json:"component"`
	Vector      string                 `json:"vector"`
	Metadata    map[string]interface{} `json:"metadata"`
}

type Classification struct {
	Category    string  `json:"category"`
	Confidence  float32 `json:"confidence"`
	Risk        string  `json:"risk"`
	Remediation string  `json:"remediation"`
}

type SecurityMetrics struct {
	TotalPolicies     int     `json:"total_policies"`
	ActivePolicies    int     `json:"active_policies"`
	TotalAnomalies    int     `json:"total_anomalies"`
	HighRiskAnomalies int     `json:"high_risk_anomalies"`
	AverageScore      float32 `json:"average_score"`
}

type MarkdownDocument struct {
	Title      string            `json:"title"`
	Headers    []string          `json:"headers"`
	Paragraphs []string          `json:"paragraphs"`
	Metadata   map[string]string `json:"metadata"`
}

type TestEnvironment struct {
	QdrantEndpoint string
	TestDatabase   string
	TempDir        string
	CleanupFuncs   []func() error
}

// === PHASE 5.1.2.1: TESTS CROSS-MANAGERS ===

// SetupSuite initialise la suite de tests
func (suite *CrossManagersTestSuite) SetupSuite() {
	suite.ctx = context.Background()

	// Setup test environment
	suite.testEnvironment = &TestEnvironment{
		QdrantEndpoint: "localhost:6333",
		TestDatabase:   "test_cross_managers",
		TempDir:        "/tmp/test_cross_managers",
		CleanupFuncs:   make([]func() error, 0),
	}

	// Initialize managers (mocks for now)
	suite.dependencyManager = NewMockDependencyManager()
	suite.planningEcosync = NewMockPlanningEcosystemSync()
	suite.storageManager = NewMockStorageManager()
	suite.securityManager = NewMockSecurityManager()
	suite.vectorizationEngine = NewMockVectorizationEngine()
}

// TearDownSuite nettoie après les tests
func (suite *CrossManagersTestSuite) TearDownSuite() {
	for _, cleanup := range suite.testEnvironment.CleanupFuncs {
		cleanup()
	}
}

// TestDependencyManagerVectorizationIntegration teste l'intégration dependency-manager ↔ vectorization
func (suite *CrossManagersTestSuite) TestDependencyManagerVectorizationIntegration() {
	suite.T().Log("=== Test Dependency Manager ↔ Vectorization Integration ===")

	// Micro-étape 5.1.2.1.1: Test dependency-manager ↔ vectorization
	testDeps := []Dependency{
		{
			Name:        "test-library",
			Version:     "1.0.0",
			Type:        "npm",
			Description: "A test library for dependency management",
			Metadata:    map[string]string{"category": "testing"},
		},
		{
			Name:        "security-lib",
			Version:     "2.1.0",
			Type:        "go",
			Description: "Security utilities for Go applications",
			Metadata:    map[string]string{"category": "security"},
		},
	}

	// Test auto-vectorization
	err := suite.dependencyManager.AutoVectorize(suite.ctx, testDeps)
	require.NoError(suite.T(), err, "Auto-vectorization should succeed")

	// Test semantic search
	results, err := suite.dependencyManager.SearchSemantic(suite.ctx, "security library", 5)
	require.NoError(suite.T(), err, "Semantic search should succeed")
	assert.NotEmpty(suite.T(), results, "Should find semantic matches")

	// Verify vectorization status
	assert.True(suite.T(), suite.dependencyManager.GetVectorizationStatus(), "Vectorization should be enabled")

	// Test vectorization events
	event := VectorizationEvent{
		Type:      "dependency_added",
		Source:    "dependency_manager",
		Target:    "vectorization_engine",
		Data:      map[string]interface{}{"dependency": testDeps[0]},
		Timestamp: time.Now(),
	}

	err = suite.dependencyManager.NotifyVectorizationEvent(suite.ctx, event)
	require.NoError(suite.T(), err, "Event notification should succeed")
}

// TestPlanningEcosystemSyncIntegration teste l'intégration planning-ecosystem-sync ↔ managers
func (suite *CrossManagersTestSuite) TestPlanningEcosystemSyncIntegration() {
	suite.T().Log("=== Test Planning Ecosystem Sync ↔ Managers Integration ===")

	// Micro-étape 5.1.2.1.2: Test planning-ecosystem-sync ↔ managers

	// Test synchronization with dependency manager
	err := suite.planningEcosync.SyncWithDependencyManager(suite.ctx)
	require.NoError(suite.T(), err, "Sync with dependency manager should succeed")

	// Test conflict detection
	conflicts, err := suite.planningEcosync.DetectConflicts(suite.ctx)
	require.NoError(suite.T(), err, "Conflict detection should succeed")

	// Test conflict resolution if conflicts exist
	if len(conflicts) > 0 {
		err = suite.planningEcosync.ResolveConflicts(suite.ctx, conflicts)
		require.NoError(suite.T(), err, "Conflict resolution should succeed")
	}

	// Test vectorization event handling
	event := VectorizationEvent{
		Type:      "sync_completed",
		Source:    "planning_ecosystem_sync",
		Target:    "all_managers",
		Data:      map[string]interface{}{"sync_id": "test_sync_001"},
		Timestamp: time.Now(),
	}

	err = suite.planningEcosync.HandleVectorizationEvent(suite.ctx, event)
	require.NoError(suite.T(), err, "Event handling should succeed")

	// Verify sync status
	status := suite.planningEcosync.GetSyncStatus()
	assert.True(suite.T(), status.IsActive, "Sync should be active")
	assert.Equal(suite.T(), 0, status.ErrorCount, "Should have no sync errors")
}
