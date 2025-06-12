package tests

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// IntegrationTestSuite contains all integration tests for the planning ecosystem sync
type IntegrationTestSuite struct {
	suite.Suite
	testDataDir    string
	tempDir        string
	syncEngine     *SyncEngine
	validator      *ValidationEngine
	testDatabase   *sql.DB
	logger         *log.Logger
	ctx            context.Context
	cancel         context.CancelFunc
}

// SyncEngine mock for testing
type SyncEngine struct {
	lastSyncTime    time.Time
	activeSyncs     int
	conflictCount   int
	healthStatus    string
	totalOperations int
	successRate     float64
	avgTime         time.Duration
	failedOps       int
}

// ValidationEngine mock for testing
type ValidationEngine struct {
	validationRules map[string]ValidationRule
	strictMode      bool
}

// ValidationRule represents a validation rule
type ValidationRule struct {
	Name        string
	Description string
	Severity    string
	Checker     func(interface{}) error
}

// TestPlan represents a test plan structure
type TestPlan struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Path        string                 `json:"path"`
	Phases      []TestPhase            `json:"phases"`
	Tasks       []TestTask             `json:"tasks"`
	Metadata    map[string]interface{} `json:"metadata"`
	Progression float64                `json:"progression"`
}

// TestPhase represents a test phase
type TestPhase struct {
	Name     string  `json:"name"`
	Progress float64 `json:"progress"`
	Status   string  `json:"status"`
	Tasks    []TestTask `json:"tasks"`
}

// TestTask represents a test task
type TestTask struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Status   string `json:"status"`
	Priority string `json:"priority"`
	Phase    string `json:"phase"`
}

// ConflictScenario represents a conflict test scenario
type ConflictScenario struct {
	Name               string
	MarkdownChange     TaskChange
	DynamicChange      TaskChange
	ExpectedResolution string
}

// TaskChange represents a task modification
type TaskChange struct {
	ID     string
	Status string
	Field  string
	Value  interface{}
}

// ProgressChange represents a progress modification
type ProgressChange struct {
	Phase    string
	Progress float64
}

// SetupSuite initializes the test suite
func (suite *IntegrationTestSuite) SetupSuite() {
	suite.ctx, suite.cancel = context.WithCancel(context.Background())
	
	// Setup test logger
	suite.logger = log.New(os.Stdout, "[TEST] ", log.LstdFlags)
	
	// Create temporary directories
	var err error
	suite.tempDir, err = os.MkdirTemp("", "planning_sync_test_*")
	require.NoError(suite.T(), err)
	
	suite.testDataDir = filepath.Join(suite.tempDir, "test_data")
	err = os.MkdirAll(suite.testDataDir, 0755)
	require.NoError(suite.T(), err)
	
	// Initialize mock components
	suite.syncEngine = &SyncEngine{
		lastSyncTime:  time.Now(),
		activeSyncs:   0,
		conflictCount: 0,
		healthStatus:  "healthy",
		successRate:   95.2,
		avgTime:       150 * time.Millisecond,
	}
	
	suite.validator = &ValidationEngine{
		validationRules: make(map[string]ValidationRule),
		strictMode:      true,
	}
	
	suite.logger.Printf("Integration test suite initialized in %s", suite.tempDir)
}

// TearDownSuite cleans up after all tests
func (suite *IntegrationTestSuite) TearDownSuite() {
	if suite.cancel != nil {
		suite.cancel()
	}
	
	if suite.testDatabase != nil {
		suite.testDatabase.Close()
	}
	
	if suite.tempDir != "" {
		os.RemoveAll(suite.tempDir)
	}
	
	suite.logger.Printf("Integration test suite cleaned up")
}

// SetupTest prepares each individual test
func (suite *IntegrationTestSuite) SetupTest() {
	// Reset sync engine state
	suite.syncEngine.activeSyncs = 0
	suite.syncEngine.conflictCount = 0
	suite.syncEngine.totalOperations = 0
	suite.syncEngine.failedOps = 0
}

// Test_MarkdownToDynamicSync tests synchronization from Markdown to dynamic systems
func (suite *IntegrationTestSuite) Test_MarkdownToDynamicSync() {
	// Create test markdown plan
	testPlan := suite.createTestMarkdownPlan("plan-test-sync.md")
	
	// Setup synchronizer with test configuration
	config := &SyncConfig{
		QDrantURL:       "http://localhost:6333",
		PostgresURL:     "postgres://test:test@localhost/test_db",
		ValidationLevel: "strict",
		DryRun:          true, // Safe for testing
	}
	
	synchronizer := NewPlanSynchronizer(config, suite.logger)
	
	// Test synchronization
	err := synchronizer.SyncMarkdownToDynamic(testPlan.Path)
	assert.NoError(suite.T(), err, "Synchronization should succeed")
	
	// Validation
	dynamicData, err := synchronizer.fetchFromDynamic(testPlan.ID)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), testPlan.Title, dynamicData.Title)
	assert.Equal(suite.T(), len(testPlan.Tasks), len(dynamicData.Tasks))
	assert.Equal(suite.T(), testPlan.Progression, dynamicData.Progression)
	
	// Verify metadata preservation
	assert.Equal(suite.T(), testPlan.Metadata["version"], dynamicData.Metadata["version"])
	assert.Equal(suite.T(), testPlan.Metadata["author"], dynamicData.Metadata["author"])
	
	// Verify structure of phases
	for i, phase := range testPlan.Phases {
		assert.Equal(suite.T(), phase.Name, dynamicData.Phases[i].Name)
		assert.Equal(suite.T(), phase.Progress, dynamicData.Phases[i].Progress)
	}
	
	suite.logger.Printf("✅ Markdown to Dynamic sync test passed")
}

// Test_DynamicToMarkdownSync tests synchronization from dynamic systems to Markdown
func (suite *IntegrationTestSuite) Test_DynamicToMarkdownSync() {
	// Setup dynamic data
	dynamicPlan := suite.createTestDynamicPlan()
	synchronizer := NewPlanSynchronizer(suite.getTestConfig(), suite.logger)
	
	// Test export to Markdown
	markdownContent, err := synchronizer.ExportToMarkdown(dynamicPlan)
	assert.NoError(suite.T(), err)
	
	// Re-parse generated Markdown
	parser := NewMarkdownParser()
	reparsedPlan, err := parser.ParseContent(markdownContent)
	assert.NoError(suite.T(), err)
	
	// Validation round-trip
	assert.Equal(suite.T(), dynamicPlan.Title, reparsedPlan.Title)
	assert.Equal(suite.T(), len(dynamicPlan.Tasks), len(reparsedPlan.Tasks))
	
	// Test specific task properties
	for i, task := range dynamicPlan.Tasks {
		assert.Equal(suite.T(), task.Title, reparsedPlan.Tasks[i].Title)
		assert.Equal(suite.T(), task.Status, reparsedPlan.Tasks[i].Status)
		assert.Equal(suite.T(), task.Priority, reparsedPlan.Tasks[i].Priority)
	}
	
	suite.logger.Printf("✅ Dynamic to Markdown sync test passed")
}

// Test_ConflictHandling tests conflict detection and resolution
func (suite *IntegrationTestSuite) Test_ConflictHandling() {
	// Create conflicting scenarios
	scenarios := []ConflictScenario{
		{
			Name:           "Task Status Conflict",
			MarkdownChange: TaskChange{ID: "task-1", Status: "completed"},
			DynamicChange:  TaskChange{ID: "task-1", Status: "in-progress"},
			ExpectedResolution: "manual_review",
		},
		{
			Name:           "Priority Mismatch",
			MarkdownChange: TaskChange{ID: "task-2", Field: "priority", Value: "high"},
			DynamicChange:  TaskChange{ID: "task-2", Field: "priority", Value: "medium"},
			ExpectedResolution: "automatic_merge",
		},
		{
			Name:           "Title Modification",
			MarkdownChange: TaskChange{ID: "task-3", Field: "title", Value: "Updated Task Title"},
			DynamicChange:  TaskChange{ID: "task-3", Field: "title", Value: "Original Task Title"},
			ExpectedResolution: "timestamp_based",
		},
	}
	
	conflictResolver := NewConflictResolver(suite.logger)
	
	for _, scenario := range scenarios {
		suite.T().Run(scenario.Name, func(t *testing.T) {
			conflict := conflictResolver.DetectConflict(scenario.MarkdownChange, scenario.DynamicChange)
			
			assert.NotNil(t, conflict)
			assert.Equal(t, scenario.ExpectedResolution, conflict.RecommendedResolution)
			
			// Test resolution
			resolution, err := conflictResolver.ResolveConflict(conflict)
			assert.NoError(t, err)
			assert.NotNil(t, resolution)
			
			suite.logger.Printf("✅ Conflict scenario '%s' resolved successfully", scenario.Name)
		})
	}
}

// Test_MigrationRollback tests migration rollback functionality
func (suite *IntegrationTestSuite) Test_MigrationRollback() {
	// Setup initial state
	originalPlan := suite.createTestPlan("original-plan.md")
	migrator := NewMigrationAssistant(suite.logger)
	
	// Create backup
	backup, err := migrator.CreateBackup(originalPlan.Path)
	assert.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), backup.BackupID)
	
	// Perform migration
	migrationResult, err := migrator.MigratePlan(originalPlan.Path)
	assert.NoError(suite.T(), err)
	assert.True(suite.T(), migrationResult.Success)
	
	// Simulate failure requiring rollback
	err = migrator.RollbackMigration(backup)
	assert.NoError(suite.T(), err)
	
	// Verify rollback was successful
	restoredPlan, err := suite.loadPlanFromFile(originalPlan.Path)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), originalPlan.Title, restoredPlan.Title)
	assert.Equal(suite.T(), len(originalPlan.Tasks), len(restoredPlan.Tasks))
	
	suite.logger.Printf("✅ Migration rollback test passed")
}

// Test_PerformanceMetrics tests performance monitoring and metrics collection
func (suite *IntegrationTestSuite) Test_PerformanceMetrics() {
	metricsConfig := &MetricsConfig{
		DatabaseURL:     "", // Use in-memory for testing
		RetentionDays:   7,
		SampleInterval:  1 * time.Second,
		MaxSamples:      100,
		AlertThresholds: map[string]float64{
			"sync_duration_ms": 5000,
			"error_rate_pct":   5.0,
		},
	}
	
	performanceMetrics, err := NewPerformanceMetrics(metricsConfig, suite.logger)
	assert.NoError(suite.T(), err)
	
	// Record some test operations
	performanceMetrics.RecordSyncOperation(150*time.Millisecond, 100, 2)
	performanceMetrics.RecordSyncOperation(200*time.Millisecond, 150, 1)
	performanceMetrics.RecordSyncOperation(120*time.Millisecond, 80, 0)
	
	performanceMetrics.RecordResponseTime(50 * time.Millisecond)
	performanceMetrics.RecordResponseTime(75 * time.Millisecond)
	
	performanceMetrics.RecordMemoryUsage(512 * 1024 * 1024) // 512MB
	
	// Generate performance report
	report := performanceMetrics.GetPerformanceReport()
	assert.NotNil(suite.T(), report)
	assert.True(suite.T(), report.AvgSyncDuration > 0)
	assert.True(suite.T(), report.AvgThroughput > 0)
	assert.True(suite.T(), report.AvgErrorRate >= 0)
	
	// Test real-time dashboard data
	dashboardData := performanceMetrics.GetRealtimeDashboardData()
	assert.NotNil(suite.T(), dashboardData)
	assert.Contains(suite.T(), dashboardData, "health_status")
	
	suite.logger.Printf("✅ Performance metrics test passed")
}

// Test_AlertSystem tests the alert detection and notification system
func (suite *IntegrationTestSuite) Test_AlertSystem() {
	alertConfig := &AlertConfig{
		EmailSMTP: SMTPConfig{
			Host:     "localhost",
			Port:     25,
			Username: "test",
			Password: "test",
		},
		SlackWebhook: "https://hooks.slack.com/test",
		Enabled:      true,
	}
	
	alertManager := NewAlertManager(alertConfig, suite.logger)
	
	// Test critical alert
	criticalAlert := Alert{
		ID:        "test-critical-001",
		Type:      "sync_failure",
		Severity:  "critical",
		Message:   "Synchronization failed completely",
		Timestamp: time.Now(),
		Source:    "test_suite",
		Details: map[string]interface{}{
			"error_count": 5,
			"last_error":  "connection timeout",
		},
	}
	
	err := alertManager.SendAlert(criticalAlert)
	assert.NoError(suite.T(), err)
	
	// Test warning alert
	warningAlert := Alert{
		ID:        "test-warning-001",
		Type:      "performance_degradation",
		Severity:  "warning",
		Message:   "Sync performance degraded by 15%",
		Timestamp: time.Now(),
		Source:    "test_suite",
		Details: map[string]interface{}{
			"performance_drop": 15.2,
			"threshold":        10.0,
		},
	}
	
	err = alertManager.SendAlert(warningAlert)
	assert.NoError(suite.T(), err)
	
	// Verify alert history
	recentAlerts := alertManager.GetRecentAlerts(10)
	assert.GreaterOrEqual(suite.T(), len(recentAlerts), 2)
	
	// Test alert resolution
	err = alertManager.ResolveAlert(criticalAlert.ID)
	assert.NoError(suite.T(), err)
	
	suite.logger.Printf("✅ Alert system test passed")
}

// Test_DriftDetection tests drift detection functionality
func (suite *IntegrationTestSuite) Test_DriftDetection() {
	metricsCollector := NewMetricsCollector(suite.logger)
	alertManager := NewAlertManager(&AlertConfig{Enabled: false}, suite.logger)
	
	driftDetector := NewDriftDetector(alertManager, metricsCollector, suite.logger)
	
	// Start drift detection
	err := driftDetector.StartMonitoring(suite.ctx)
	assert.NoError(suite.T(), err)
	
	// Simulate drift conditions
	// 1. Sync delay drift
	metricsCollector.SetLastSyncTime(time.Now().Add(-45 * time.Minute)) // 45 minutes ago
	
	// 2. Error rate drift
	metricsCollector.SetErrorRate(8.5) // Above 5% threshold
	
	// 3. Performance drift
	metricsCollector.SetResponseTime(1500 * time.Millisecond) // Above 1s threshold
	
	// Wait for drift detection to trigger
	time.Sleep(2 * time.Second)
	
	// Check if alerts were generated
	alerts := alertManager.GetRecentAlerts(10)
	
	// We should have alerts for sync delay, error rate, and performance
	alertTypes := make(map[string]bool)
	for _, alert := range alerts {
		alertTypes[alert.Type] = true
	}
	
	assert.True(suite.T(), alertTypes["sync_drift"] || alertTypes["error_rate_drift"] || alertTypes["performance_drift"])
	
	// Stop monitoring
	driftDetector.StopMonitoring()
	
	suite.logger.Printf("✅ Drift detection test passed")
}

// Test_RealtimeDashboard tests the real-time dashboard functionality
func (suite *IntegrationTestSuite) Test_RealtimeDashboard() {
	performanceMetrics, _ := NewPerformanceMetrics(&MetricsConfig{MaxSamples: 100}, suite.logger)
	alertManager := NewAlertManager(&AlertConfig{Enabled: false}, suite.logger)
	driftDetector := NewDriftDetector(alertManager, nil, suite.logger)
	
	dashboard := NewRealtimeDashboard(performanceMetrics, driftDetector, alertManager, suite.logger)
	
	// Test dashboard data collection
	data := dashboard.collectDashboardData()
	assert.NotNil(suite.T(), data)
	assert.NotZero(suite.T(), data.Timestamp)
	
	// Test WebSocket connection count
	initialConnections := dashboard.GetConnectionCount()
	assert.Equal(suite.T(), 0, initialConnections)
	
	// Test system status collection
	status := dashboard.collectSystemStatus()
	assert.NotNil(suite.T(), status)
	assert.Greater(suite.T(), status.CPUUsage, 0.0)
	assert.Greater(suite.T(), status.MemoryUsage, uint64(0))
	
	suite.logger.Printf("✅ Real-time dashboard test passed")
}

// Test_ReportGeneration tests automated report generation
func (suite *IntegrationTestSuite) Test_ReportGeneration() {
	reportConfig := &ReportConfig{
		OutputDir:           filepath.Join(suite.tempDir, "reports"),
		ReportFormats:       []string{"json", "html"},
		Schedule:            "daily",
		RetentionDays:       30,
		IncludeCharts:       true,
		AutomaticGeneration: false, // Manual for testing
	}
	
	performanceMetrics, _ := NewPerformanceMetrics(&MetricsConfig{MaxSamples: 100}, suite.logger)
	alertManager := NewAlertManager(&AlertConfig{Enabled: false}, suite.logger)
	driftDetector := NewDriftDetector(alertManager, nil, suite.logger)
	
	reportGenerator := NewReportGenerator(performanceMetrics, alertManager, driftDetector, reportConfig, suite.logger)
	
	// Generate test report
	period := ReportPeriod{
		StartTime: time.Now().AddDate(0, 0, -1),
		EndTime:   time.Now(),
		Duration:  "24 hours",
		Type:      "daily",
	}
	
	report, err := reportGenerator.GenerateReport("Daily", period)
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), report)
	assert.Equal(suite.T(), "Daily", strings.Split(report.Title, " - ")[1])
	
	// Test report saving
	err = reportGenerator.SaveReport(report)
	assert.NoError(suite.T(), err)
	
	// Verify files were created
	jsonFile := filepath.Join(reportConfig.OutputDir, fmt.Sprintf("%s_daily.json", report.ID))
	htmlFile := filepath.Join(reportConfig.OutputDir, fmt.Sprintf("%s_daily.html", report.ID))
	
	assert.FileExists(suite.T(), jsonFile)
	assert.FileExists(suite.T(), htmlFile)
	
	suite.logger.Printf("✅ Report generation test passed")
}

// Helper functions

func (suite *IntegrationTestSuite) createTestMarkdownPlan(filename string) *TestPlan {
	plan := &TestPlan{
		ID:    "test-plan-001",
		Title: "Test Plan for Integration",
		Path:  filepath.Join(suite.testDataDir, filename),
		Phases: []TestPhase{
			{Name: "Phase 1", Progress: 100.0, Status: "completed"},
			{Name: "Phase 2", Progress: 75.0, Status: "in-progress"},
			{Name: "Phase 3", Progress: 0.0, Status: "pending"},
		},
		Tasks: []TestTask{
			{ID: "task-1", Title: "Setup Infrastructure", Status: "completed", Priority: "high", Phase: "Phase 1"},
			{ID: "task-2", Title: "Implement Core Features", Status: "in-progress", Priority: "high", Phase: "Phase 2"},
			{ID: "task-3", Title: "Testing and Validation", Status: "pending", Priority: "medium", Phase: "Phase 3"},
		},
		Metadata: map[string]interface{}{
			"version": "1.0.0",
			"author":  "Test Suite",
			"created": time.Now().Format("2006-01-02"),
		},
		Progression: 58.3,
	}
	
	// Create the markdown file
	content := suite.generateMarkdownContent(plan)
	err := os.WriteFile(plan.Path, []byte(content), 0644)
	require.NoError(suite.T(), err)
	
	return plan
}

func (suite *IntegrationTestSuite) createTestDynamicPlan() *TestPlan {
	return &TestPlan{
		ID:    "dynamic-plan-001",
		Title: "Dynamic Test Plan",
		Tasks: []TestTask{
			{ID: "dyn-task-1", Title: "Dynamic Task 1", Status: "completed", Priority: "high"},
			{ID: "dyn-task-2", Title: "Dynamic Task 2", Status: "in-progress", Priority: "medium"},
		},
		Metadata: map[string]interface{}{
			"version": "2.0.0",
			"source":  "dynamic_system",
		},
		Progression: 50.0,
	}
}

func (suite *IntegrationTestSuite) createTestPlan(filename string) *TestPlan {
	return suite.createTestMarkdownPlan(filename)
}

func (suite *IntegrationTestSuite) getTestConfig() *SyncConfig {
	return &SyncConfig{
		QDrantURL:       "http://localhost:6333",
		PostgresURL:     "postgres://test:test@localhost/test_db",
		ValidationLevel: "strict",
		DryRun:          true,
	}
}

func (suite *IntegrationTestSuite) loadPlanFromFile(path string) (*TestPlan, error) {
	// Mock implementation - in real scenario would parse the file
	return &TestPlan{
		Title: "Loaded Test Plan",
		Tasks: []TestTask{},
	}, nil
}

func (suite *IntegrationTestSuite) generateMarkdownContent(plan *TestPlan) string {
	content := fmt.Sprintf(`# %s

## Metadata
- Version: %v
- Author: %v
- Created: %v

## Phases
`, plan.Title, plan.Metadata["version"], plan.Metadata["author"], plan.Metadata["created"])

	for _, phase := range plan.Phases {
		content += fmt.Sprintf("### %s (%.1f%% - %s)\n\n", phase.Name, phase.Progress, phase.Status)
	}

	content += "## Tasks\n\n"
	for _, task := range plan.Tasks {
		content += fmt.Sprintf("- [%s] **%s** (%s, %s) - %s\n", 
			getCheckboxStatus(task.Status), task.Title, task.Priority, task.Status, task.Phase)
	}

	return content
}

func getCheckboxStatus(status string) string {
	if status == "completed" {
		return "x"
	}
	return " "
}

// SyncConfig represents synchronization configuration
type SyncConfig struct {
	QDrantURL       string
	PostgresURL     string
	ValidationLevel string
	DryRun          bool
}

// Run the integration test suite
func TestIntegrationSuite(t *testing.T) {
	suite.Run(t, new(IntegrationTestSuite))
}
