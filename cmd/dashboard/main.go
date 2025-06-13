package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"email_sender/tools"
	"email_sender/web/dashboard"
)

// DashboardConfig holds configuration for the sync dashboard
type DashboardConfig struct {
	Port        string
	DBPath      string
	LogPath     string
	Host        string
	Debug       bool
	CleanupDays int
}

func main() {
	// Parse command line flags
	config := parseFlags()

	// Setup logging
	logger := setupLogger(config.LogPath)
	logger.Println("Starting Synchronization Dashboard...")
	// Initialize sync logger with file-based storage
	syncLogger, err := tools.NewSyncLogger(filepath.Dir(config.DBPath), logger)
	if err != nil {
		logger.Fatalf("Failed to initialize sync logger: %v", err)
	}
	defer syncLogger.Close()

	// Initialize mock sync engine (replace with real implementation)
	syncEngine := NewMockSyncEngine(syncLogger, logger)
	// Create and configure dashboard
	dashboardInstance := dashboard.NewSyncDashboard(syncEngine, logger)

	// Setup graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown signals
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		logger.Println("Received shutdown signal, stopping dashboard...")
		cancel()
	}()

	// Start periodic cleanup
	if config.CleanupDays > 0 {
		go startPeriodicCleanup(syncLogger, config.CleanupDays, logger)
	}

	// Start dashboard server
	logger.Printf("Dashboard starting on http://%s:%s", config.Host, config.Port)
	logger.Printf("Database path: %s", config.DBPath)
	logger.Printf("Cleanup retention: %d days", config.CleanupDays)
	// Run server with graceful shutdown
	go func() {
		if err := dashboardInstance.Start(config.Port); err != nil {
			logger.Printf("Dashboard server error: %v", err)
			cancel()
		}
	}()

	// Wait for shutdown signal
	<-ctx.Done()

	// Graceful shutdown
	logger.Println("Shutting down dashboard...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()
	if err := dashboardInstance.Stop(shutdownCtx); err != nil {
		logger.Printf("Error during shutdown: %v", err)
	}

	logger.Println("Dashboard stopped successfully")
}

// parseFlags parses command line flags and returns configuration
func parseFlags() *DashboardConfig {
	config := &DashboardConfig{}

	flag.StringVar(&config.Port, "port", "8080", "Port to run the dashboard on")
	flag.StringVar(&config.Host, "host", "localhost", "Host to bind the dashboard to")
	flag.StringVar(&config.DBPath, "db", "./sync_logs.db", "Path to the SQLite database file")
	flag.StringVar(&config.LogPath, "log", "./dashboard.log", "Path to the log file")
	flag.BoolVar(&config.Debug, "debug", false, "Enable debug logging")
	flag.IntVar(&config.CleanupDays, "cleanup-days", 30, "Number of days to retain logs (0 disables cleanup)")

	flag.Parse()

	// Ensure database directory exists
	dbDir := filepath.Dir(config.DBPath)
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		log.Fatalf("Failed to create database directory: %v", err)
	}

	return config
}

// setupLogger configures logging based on configuration
func setupLogger(logPath string) *log.Logger {
	// Ensure log directory exists
	logDir := filepath.Dir(logPath)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		log.Fatalf("Failed to create log directory: %v", err)
	}

	// Open log file
	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("Failed to open log file: %v", err)
	}

	return log.New(logFile, "[DASHBOARD] ", log.LstdFlags|log.Lshortfile)
}

// startPeriodicCleanup starts a background goroutine for periodic log cleanup
func startPeriodicCleanup(syncLogger *tools.SyncLogger, retentionDays int, logger *log.Logger) {
	ticker := time.NewTicker(24 * time.Hour) // Run daily
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			logger.Printf("Starting periodic log cleanup (retention: %d days)", retentionDays)
			if err := syncLogger.CleanupOldLogs(retentionDays); err != nil {
				logger.Printf("Error during log cleanup: %v", err)
			} else {
				logger.Println("Periodic log cleanup completed successfully")
			}
		}
	}
}

// MockSyncEngine is a mock implementation for testing/demo purposes
// Replace this with your actual sync engine implementation
type MockSyncEngine struct {
	syncLogger *tools.SyncLogger
	logger     *log.Logger
	startTime  time.Time
}

func NewMockSyncEngine(syncLogger *tools.SyncLogger, logger *log.Logger) *MockSyncEngine {
	engine := &MockSyncEngine{
		syncLogger: syncLogger,
		logger:     logger,
		startTime:  time.Now(),
	}

	// Initialize with some sample data
	engine.initializeSampleData()

	return engine
}

func (m *MockSyncEngine) initializeSampleData() {
	// Log some sample operations
	m.syncLogger.LogOperation("system_startup", "success", 200*time.Millisecond, "Dashboard initialized", map[string]interface{}{
		"version": "1.0.0",
		"port":    "8080",
	})

	// Log a sample conflict
	m.syncLogger.LogConflict(
		"conflict_001",
		"plan-dev-v55.md",
		"content_divergence",
		"medium",
		"Original markdown content",
		"Modified database content",
	)
}

func (m *MockSyncEngine) GetLastSyncTime() time.Time {
	return time.Now().Add(-5 * time.Minute)
}

func (m *MockSyncEngine) GetActiveSyncs() []string {
	return []string{"plan-dev-v55", "plan-dev-v54"}
}

func (m *MockSyncEngine) GetConflictCount() int {
	conflicts, err := m.syncLogger.GetActiveConflicts()
	if err != nil {
		m.logger.Printf("Error getting conflict count: %v", err)
		return 0
	}
	return len(conflicts)
}

func (m *MockSyncEngine) GetHealthStatus() string {
	if time.Since(m.startTime) < 1*time.Hour {
		return "healthy"
	}
	return "degraded"
}

func (m *MockSyncEngine) GetMetrics() *dashboard.PerformanceMetrics {
	stats, err := m.syncLogger.GetSyncStats(time.Now().Add(-24 * time.Hour))
	if err != nil {
		m.logger.Printf("Error getting metrics: %v", err)
		return &dashboard.PerformanceMetrics{
			TotalSyncs:  0,
			SuccessRate: 0,
			AverageTime: 0,
			ErrorCount:  0,
		}
	}

	return &dashboard.PerformanceMetrics{
		TotalSyncs:  stats.TotalOperations,
		SuccessRate: stats.SuccessRate,
		AverageTime: stats.AverageTime,
		ErrorCount:  stats.FailedOps,
		LastError:   "",
	}
}

func (m *MockSyncEngine) GetDivergences() []dashboard.DivergenceInfo {
	conflicts, err := m.syncLogger.GetActiveConflicts()
	if err != nil {
		m.logger.Printf("Error getting divergences: %v", err)
		return []dashboard.DivergenceInfo{}
	}

	divergences := make([]dashboard.DivergenceInfo, len(conflicts))
	for i, conflict := range conflicts {
		divergences[i] = dashboard.DivergenceInfo{
			ID:            conflict.ConflictID,
			FilePath:      conflict.FilePath,
			Severity:      conflict.Severity,
			SourceContent: conflict.SourceContent,
			TargetContent: conflict.TargetContent,
			Timestamp:     conflict.Timestamp,
			Status:        conflict.Status,
		}
	}

	return divergences
}

func (m *MockSyncEngine) GetActiveConflicts() []dashboard.ConflictInfo {
	conflicts, err := m.syncLogger.GetActiveConflicts()
	if err != nil {
		m.logger.Printf("Error getting active conflicts: %v", err)
		return []dashboard.ConflictInfo{}
	}

	result := make([]dashboard.ConflictInfo, len(conflicts))
	for i, conflict := range conflicts {
		result[i] = dashboard.ConflictInfo{
			ID:            conflict.ConflictID,
			FilePath:      conflict.FilePath,
			Severity:      conflict.Severity,
			SourceContent: conflict.SourceContent,
			TargetContent: conflict.TargetContent,
			Timestamp:     conflict.Timestamp,
			Status:        conflict.Status,
		}
	}

	return result
}

func (m *MockSyncEngine) ResolveConflict(conflictID, resolution, customMerge string) error {
	resolvedBy := "dashboard_user"
	mergedContent := customMerge

	if resolution != "custom" {
		mergedContent = fmt.Sprintf("Auto-resolved using: %s", resolution)
	}

	return m.syncLogger.LogConflictResolution(conflictID, resolution, resolvedBy, mergedContent)
}

func (m *MockSyncEngine) GetSyncHistory(limit int) []dashboard.SyncHistoryEntry {
	entries, err := m.syncLogger.GetSyncHistory(limit, 0, "", "")
	if err != nil {
		m.logger.Printf("Error getting sync history: %v", err)
		return []dashboard.SyncHistoryEntry{}
	}

	result := make([]dashboard.SyncHistoryEntry, len(entries))
	for i, entry := range entries {
		result[i] = dashboard.SyncHistoryEntry{
			Timestamp: entry.Timestamp,
			Operation: entry.Operation,
			Status:    entry.Status,
			Duration:  entry.Duration,
			Details:   entry.Details,
		}
	}
	return result
}
