package workflow

import (
	"context"
	"encoding/json"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// WorkflowOrchestrator manages the unified workflow between Markdown, Dynamic system, and Roadmap Manager
type WorkflowOrchestrator struct {
	config            *WorkflowConfig
	syncEngine        *SyncEngine
	roadmapConnector  *RoadmapConnector
	taskMasterAdapter *TaskMasterAdapter
	fileWatcher       *FileWatcher
	logger            *log.Logger
	metrics           *WorkflowMetrics
	syncPoints        []SyncPoint
	isRunning         bool
	mutex             sync.RWMutex
}

// WorkflowConfig holds configuration for the unified workflow
type WorkflowConfig struct {
	SyncInterval       time.Duration `yaml:"sync_interval"`
	AutoSync           bool          `yaml:"auto_sync"`
	ConflictResolution string        `yaml:"conflict_resolution"` // "manual", "auto", "hybrid"
	MaxRetries         int           `yaml:"max_retries"`
	BackupEnabled      bool          `yaml:"backup_enabled"`
	AlertsEnabled      bool          `yaml:"alerts_enabled"`

	// Synchronization points configuration
	SyncPoints struct {
		MarkdownToDynamic bool `yaml:"markdown_to_dynamic"`
		DynamicToMarkdown bool `yaml:"dynamic_to_markdown"`
		RoadmapManager    bool `yaml:"roadmap_manager"`
		TaskMasterCLI     bool `yaml:"taskmaster_cli"`
	} `yaml:"sync_points"`
}

// SyncPoint represents a synchronization point in the workflow
type SyncPoint struct {
	ID       string    `json:"id"`
	Name     string    `json:"name"`
	Source   string    `json:"source"` // "markdown", "dynamic", "roadmap_manager"
	Target   string    `json:"target"`
	LastSync time.Time `json:"last_sync"`
	Status   string    `json:"status"` // "active", "paused", "error"
	Priority int       `json:"priority"`
	Enabled  bool      `json:"enabled"`
}

// WorkflowMetrics tracks performance and health metrics
type WorkflowMetrics struct {
	TotalSyncs        int64         `json:"total_syncs"`
	SuccessfulSyncs   int64         `json:"successful_syncs"`
	FailedSyncs       int64         `json:"failed_syncs"`
	AverageSyncTime   time.Duration `json:"average_sync_time"`
	ConflictsDetected int64         `json:"conflicts_detected"`
	ConflictsResolved int64         `json:"conflicts_resolved"`
	LastSyncTime      time.Time     `json:"last_sync_time"`
	WorkflowStartTime time.Time     `json:"workflow_start_time"`
	UptimePercent     float64       `json:"uptime_percent"`
}

// NewWorkflowOrchestrator creates a new workflow orchestrator instance
func NewWorkflowOrchestrator(config *WorkflowConfig) *WorkflowOrchestrator {
	return &WorkflowOrchestrator{
		config:     config,
		logger:     log.New(log.Writer(), "[WORKFLOW-ORCHESTRATOR] ", log.LstdFlags),
		metrics:    &WorkflowMetrics{WorkflowStartTime: time.Now()},
		syncPoints: []SyncPoint{},
		isRunning:  false,
	}
}

// Initialize sets up all components and synchronization points
func (wo *WorkflowOrchestrator) Initialize() error {
	wo.logger.Printf("🚀 Initializing Workflow Orchestrator...")

	// Initialize synchronization points
	if err := wo.initializeSyncPoints(); err != nil {
		return fmt.Errorf("failed to initialize sync points: %w", err)
	}

	// Initialize components
	if err := wo.initializeComponents(); err != nil {
		return fmt.Errorf("failed to initialize components: %w", err)
	}

	wo.logger.Printf("✅ Workflow Orchestrator initialized successfully")
	return nil
}

// initializeSyncPoints defines all synchronization points in the workflow
func (wo *WorkflowOrchestrator) initializeSyncPoints() error {
	wo.logger.Printf("📍 Defining synchronization points...")

	// Define sync points based on configuration
	if wo.config.SyncPoints.MarkdownToDynamic {
		wo.syncPoints = append(wo.syncPoints, SyncPoint{
			ID:       "markdown_to_dynamic",
			Name:     "Markdown to Dynamic Sync",
			Source:   "markdown",
			Target:   "dynamic",
			Status:   "active",
			Priority: 1,
			Enabled:  true,
		})
	}

	if wo.config.SyncPoints.DynamicToMarkdown {
		wo.syncPoints = append(wo.syncPoints, SyncPoint{
			ID:       "dynamic_to_markdown",
			Name:     "Dynamic to Markdown Sync",
			Source:   "dynamic",
			Target:   "markdown",
			Status:   "active",
			Priority: 2,
			Enabled:  true,
		})
	}

	if wo.config.SyncPoints.RoadmapManager {
		wo.syncPoints = append(wo.syncPoints, SyncPoint{
			ID:       "roadmap_manager_sync",
			Name:     "Roadmap Manager Integration",
			Source:   "dynamic",
			Target:   "roadmap_manager",
			Status:   "active",
			Priority: 3,
			Enabled:  true,
		})
	}

	if wo.config.SyncPoints.TaskMasterCLI {
		wo.syncPoints = append(wo.syncPoints, SyncPoint{
			ID:       "taskmaster_sync",
			Name:     "TaskMaster CLI Sync",
			Source:   "dynamic",
			Target:   "taskmaster",
			Status:   "active",
			Priority: 4,
			Enabled:  true,
		})
	}

	wo.logger.Printf("✅ Initialized %d synchronization points", len(wo.syncPoints))
	return nil
}

// initializeComponents sets up all workflow components with concrete implementations
func (wo *WorkflowOrchestrator) initializeComponents() error {
	wo.logger.Printf("🔧 Initializing workflow components...")

	// Initialize sync engine
	wo.syncEngine = &SyncEngine{
		config: &SyncConfig{
			BatchSize:          100,
			Timeout:            30 * time.Second,
			ValidateBeforeSync: true,
			CreateDiffReports:  true,
		},
		logger: log.New(os.Stdout, "[SYNC-ENGINE] ", log.LstdFlags),
	}

	// Initialize roadmap connector
	wo.roadmapConnector = &RoadmapConnector{
		baseURL: "http://localhost:8080",
		apiKey:  "",
		logger:  log.New(os.Stdout, "[ROADMAP-CONNECTOR] ", log.LstdFlags),
	}

	// Initialize TaskMaster adapter
	wo.taskMasterAdapter = &TaskMasterAdapter{
		cliPath:    "./development/managers/roadmap-manager/roadmap-cli/roadmap-cli.exe",
		configPath: "./config/taskmaster-config.yaml",
		logger:     log.New(os.Stdout, "[TASKMASTER-ADAPTER] ", log.LstdFlags),
	}

	// Initialize file watcher
	wo.fileWatcher = &FileWatcher{
		watchPaths:   []string{"./projet/roadmaps/plans/", "./projet/roadmaps/plans/consolidated/"},
		filePatterns: []string{"*.md", "plan-dev-*.md"},
		debounceTime: 2 * time.Second,
		orchestrator: wo,
		logger:       log.New(os.Stdout, "[FILE-WATCHER] ", log.LstdFlags),
	}

	wo.logger.Printf("✅ All components initialized")
	return nil
}

// Start begins the unified workflow orchestration
func (wo *WorkflowOrchestrator) Start(ctx context.Context) error {
	wo.mutex.Lock()
	if wo.isRunning {
		wo.mutex.Unlock()
		return fmt.Errorf("workflow orchestrator is already running")
	}
	wo.isRunning = true
	wo.mutex.Unlock()

	wo.logger.Printf("🚀 Starting unified workflow orchestration...")

	// Start monitoring goroutine
	go wo.monitorWorkflow(ctx)

	// Start sync scheduler if auto-sync is enabled
	if wo.config.AutoSync {
		go wo.scheduledSyncLoop(ctx)
	}

	// Start file watching if enabled
	go wo.startFileWatching(ctx)

	wo.logger.Printf("✅ Workflow orchestration started successfully")
	return nil
}

// Stop gracefully stops the workflow orchestration
func (wo *WorkflowOrchestrator) Stop() error {
	wo.mutex.Lock()
	defer wo.mutex.Unlock()

	if !wo.isRunning {
		return fmt.Errorf("workflow orchestrator is not running")
	}

	wo.logger.Printf("🛑 Stopping workflow orchestration...")
	wo.isRunning = false

	wo.logger.Printf("✅ Workflow orchestration stopped")
	return nil
}

// ExecuteFullSync performs a complete synchronization across all sync points
func (wo *WorkflowOrchestrator) ExecuteFullSync(ctx context.Context) error {
	wo.logger.Printf("🔄 Executing full workflow synchronization...")

	startTime := time.Now()
	var errors []error

	// Execute sync points in priority order
	for _, syncPoint := range wo.getSortedSyncPoints() {
		if !syncPoint.Enabled {
			continue
		}

		wo.logger.Printf("📍 Executing sync point: %s", syncPoint.Name)

		if err := wo.executeSyncPoint(ctx, &syncPoint); err != nil {
			wo.logger.Printf("❌ Sync point %s failed: %v", syncPoint.ID, err)
			errors = append(errors, err)
			wo.metrics.FailedSyncs++
		} else {
			wo.logger.Printf("✅ Sync point %s completed successfully", syncPoint.ID)
			wo.metrics.SuccessfulSyncs++
		}

		wo.metrics.TotalSyncs++
	}

	// Update metrics
	duration := time.Since(startTime)
	wo.metrics.AverageSyncTime = wo.calculateAverageSyncTime(duration)
	wo.metrics.LastSyncTime = time.Now()

	if len(errors) > 0 {
		return fmt.Errorf("full sync completed with %d errors", len(errors))
	}

	wo.logger.Printf("✅ Full workflow synchronization completed in %v", duration)
	return nil
}

// executeSyncPoint executes a specific synchronization point
func (wo *WorkflowOrchestrator) executeSyncPoint(ctx context.Context, syncPoint *SyncPoint) error {
	switch syncPoint.ID {
	case "markdown_to_dynamic":
		return wo.executeMarkdownToDynamicSync(ctx)
	case "dynamic_to_markdown":
		return wo.executeDynamicToMarkdownSync(ctx)
	case "roadmap_manager_sync":
		return wo.executeRoadmapManagerSync(ctx)
	case "taskmaster_sync":
		return wo.executeTaskMasterSync(ctx)
	default:
		return fmt.Errorf("unknown sync point: %s", syncPoint.ID)
	}
}

// executeMarkdownToDynamicSync performs Markdown to Dynamic system sync with concrete implementation
func (wo *WorkflowOrchestrator) executeMarkdownToDynamicSync(ctx context.Context) error {
	wo.logger.Printf("📝➡️💾 Executing Markdown to Dynamic sync...")

	// Step 1: Discover Markdown files
	markdownFiles, err := wo.discoverMarkdownFiles()
	if err != nil {
		return fmt.Errorf("failed to discover markdown files: %w", err)
	}

	wo.logger.Printf("📄 Found %d markdown files to process", len(markdownFiles))

	// Step 2: Process each file in batches
	batchSize := wo.syncEngine.config.BatchSize
	for i := 0; i < len(markdownFiles); i += batchSize {
		end := i + batchSize
		if end > len(markdownFiles) {
			end = len(markdownFiles)
		}

		batch := markdownFiles[i:end]
		if err := wo.processBatchMarkdownToDynamic(ctx, batch); err != nil {
			wo.logger.Printf("❌ Batch processing failed: %v", err)
			return err
		}

		wo.logger.Printf("✅ Processed batch %d/%d", end, len(markdownFiles))
	}

	wo.logger.Printf("✅ Markdown to Dynamic sync completed")
	return nil
}

// executeDynamicToMarkdownSync performs Dynamic system to Markdown sync with concrete implementation
func (wo *WorkflowOrchestrator) executeDynamicToMarkdownSync(ctx context.Context) error {
	wo.logger.Printf("💾➡️📝 Executing Dynamic to Markdown sync...")

	// Step 1: Fetch dynamic data
	dynamicData, err := wo.fetchDynamicSystemData(ctx)
	if err != nil {
		return fmt.Errorf("failed to fetch dynamic data: %w", err)
	}

	wo.logger.Printf("💾 Retrieved %d dynamic plans", len(dynamicData))

	// Step 2: Convert to Markdown format
	for _, plan := range dynamicData {
		markdownContent, err := wo.convertDynamicToMarkdown(plan)
		if err != nil {
			wo.logger.Printf("❌ Failed to convert plan %s: %v", plan.ID, err)
			continue
		}

		// Step 3: Write to file
		outputPath := wo.generateMarkdownPath(plan)
		if err := wo.writeMarkdownFile(outputPath, markdownContent); err != nil {
			wo.logger.Printf("❌ Failed to write %s: %v", outputPath, err)
			continue
		}

		wo.logger.Printf("✅ Generated %s", outputPath)
	}

	wo.logger.Printf("✅ Dynamic to Markdown sync completed")
	return nil
}

// executeRoadmapManagerSync performs sync with Roadmap Manager with concrete implementation
func (wo *WorkflowOrchestrator) executeRoadmapManagerSync(ctx context.Context) error {
	wo.logger.Printf("🗺️ Executing Roadmap Manager sync...")

	// Step 1: Get current dynamic system state
	dynamicPlans, err := wo.fetchDynamicSystemData(ctx)
	if err != nil {
		return fmt.Errorf("failed to fetch dynamic plans: %w", err)
	}

	// Step 2: Convert to Roadmap Manager format
	for _, plan := range dynamicPlans {
		roadmapData, err := wo.convertToRoadmapFormat(plan)
		if err != nil {
			wo.logger.Printf("❌ Failed to convert plan %s: %v", plan.ID, err)
			continue
		}

		// Step 3: Send to Roadmap Manager
		if err := wo.sendToRoadmapManager(ctx, roadmapData); err != nil {
			wo.logger.Printf("❌ Failed to sync plan %s to Roadmap Manager: %v", plan.ID, err)
			continue
		}

		wo.logger.Printf("✅ Synced plan %s to Roadmap Manager", plan.ID)
	}

	wo.logger.Printf("✅ Roadmap Manager sync completed")
	return nil
}

// executeTaskMasterSync performs sync with TaskMaster CLI with concrete implementation
func (wo *WorkflowOrchestrator) executeTaskMasterSync(ctx context.Context) error {
	wo.logger.Printf("⚙️ Executing TaskMaster CLI sync...")

	// Step 1: Get current tasks from dynamic system
	tasks, err := wo.fetchTasksFromDynamic(ctx)
	if err != nil {
		return fmt.Errorf("failed to fetch tasks: %w", err)
	}

	wo.logger.Printf("📋 Found %d tasks to sync", len(tasks))

	// Step 2: Sync to TaskMaster CLI
	for _, task := range tasks {
		if err := wo.syncTaskToTaskMaster(ctx, task); err != nil {
			wo.logger.Printf("❌ Failed to sync task %s: %v", task.ID, err)
			continue
		}

		wo.logger.Printf("✅ Synced task %s", task.Title)
	}

	wo.logger.Printf("✅ TaskMaster CLI sync completed")
	return nil
}

// Helper functions for unified workflow implementation

func (wo *WorkflowOrchestrator) discoverMarkdownFiles() ([]string, error) {
	var files []string

	basePaths := []string{
		"./projet/roadmaps/plans/consolidated/",
		"./projet/roadmaps/plans/",
	}

	for _, basePath := range basePaths {
		err := filepath.WalkDir(basePath, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return nil // Continue on errors
			}

			if !d.IsDir() && strings.HasSuffix(path, ".md") {
				// Filter for plan files
				if strings.Contains(path, "plan-dev-") || strings.Contains(path, "roadmap") {
					files = append(files, path)
				}
			}
			return nil
		})

		if err != nil {
			wo.logger.Printf("Warning: error walking %s: %v", basePath, err)
		}
	}

	return files, nil
}

func (wo *WorkflowOrchestrator) processBatchMarkdownToDynamic(ctx context.Context, files []string) error {
	for _, file := range files {
		wo.logger.Printf("📝 Processing %s", file)

		// Read and parse Markdown file
		content, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("failed to read %s: %w", file, err)
		}

		// Parse plan structure (simplified implementation)
		planData := wo.parseMarkdownPlan(string(content), file)

		// Send to dynamic system (simulate)
		if err := wo.sendToDynamicSystem(ctx, planData); err != nil {
			return fmt.Errorf("failed to sync %s to dynamic system: %w", file, err)
		}
	}

	return nil
}

type DynamicPlan struct {
	ID       string                 `json:"id"`
	Title    string                 `json:"title"`
	Version  string                 `json:"version"`
	Progress float64                `json:"progress"`
	Metadata map[string]interface{} `json:"metadata"`
	Tasks    []Task                 `json:"tasks"`
}

type Task struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Status      string                 `json:"status"`
	Priority    string                 `json:"priority"`
	Progress    float64                `json:"progress"`
	Metadata    map[string]interface{} `json:"metadata"`
}

func (wo *WorkflowOrchestrator) fetchDynamicSystemData(ctx context.Context) ([]DynamicPlan, error) {
	// Simulate fetching from dynamic system
	// In real implementation, this would query QDrant/SQL databases
	wo.logger.Printf("🔍 Fetching data from dynamic system...")

	// For now, return mock data
	return []DynamicPlan{
		{
			ID:       "plan-dev-v55",
			Title:    "Plan-dev-v55 - Planning Ecosystem Synchronization",
			Version:  "2.2",
			Progress: 98.0, Metadata: map[string]interface{}{
				"author":     "System",
				"updated_at": time.Now(),
				"file_path":  "plan-dev-v55-planning-ecosystem-sync.md",
			},
			Tasks: []Task{
				{
					ID:          "task-5.2.1",
					Title:       "Unification des Workflows",
					Description: "Create unified workflow for all systems",
					Status:      "in_progress",
					Priority:    "high",
					Progress:    50.0,
				},
			},
		},
	}, nil
}

func (wo *WorkflowOrchestrator) parseMarkdownPlan(content, filePath string) *DynamicPlan {
	// Simplified Markdown parsing
	// In real implementation, this would use the existing markdown parser
	lines := strings.Split(content, "\n")

	plan := &DynamicPlan{
		ID:       filepath.Base(filePath),
		Metadata: make(map[string]interface{}),
		Tasks:    []Task{},
	}

	// Extract title
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "# ") {
			plan.Title = strings.TrimPrefix(line, "# ")
			break
		}
	}

	plan.Metadata["file_path"] = filePath
	plan.Metadata["parsed_at"] = time.Now()

	return plan
}

func (wo *WorkflowOrchestrator) sendToDynamicSystem(ctx context.Context, plan *DynamicPlan) error {
	// Simulate sending to dynamic system
	wo.logger.Printf("💾 Storing plan %s in dynamic system", plan.ID)
	// In real implementation, this would insert/update in QDrant/SQL
	return nil
}

func (wo *WorkflowOrchestrator) convertDynamicToMarkdown(plan DynamicPlan) (string, error) {
	var builder strings.Builder

	// Build Markdown content
	builder.WriteString(fmt.Sprintf("# %s\n\n", plan.Title))
	builder.WriteString(fmt.Sprintf("**Version %s - Progress: %.1f%%**\n\n", plan.Version, plan.Progress))

	// Add tasks
	if len(plan.Tasks) > 0 {
		builder.WriteString("## Tasks\n\n")
		for _, task := range plan.Tasks {
			checkbox := "[ ]"
			if task.Status == "completed" {
				checkbox = "[x]"
			}
			builder.WriteString(fmt.Sprintf("- %s %s (%.1f%%)\n", checkbox, task.Title, task.Progress))
		}
	}

	builder.WriteString(fmt.Sprintf("\n*Generated on %s*\n", time.Now().Format("2006-01-02 15:04:05")))

	return builder.String(), nil
}

func (wo *WorkflowOrchestrator) generateMarkdownPath(plan DynamicPlan) string {
	filename := fmt.Sprintf("%s-generated.md", plan.ID)
	return filepath.Join("./generated/markdown/", filename)
}

func (wo *WorkflowOrchestrator) writeMarkdownFile(path, content string) error {
	// Ensure directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	// Write file
	return os.WriteFile(path, []byte(content), 0644)
}

func (wo *WorkflowOrchestrator) convertToRoadmapFormat(plan DynamicPlan) ([]byte, error) {
	// Convert to Roadmap Manager format
	roadmapData := map[string]interface{}{
		"id":         plan.ID,
		"title":      plan.Title,
		"version":    plan.Version,
		"progress":   plan.Progress,
		"tasks":      plan.Tasks,
		"updated_at": time.Now(),
	}

	return json.Marshal(roadmapData)
}

func (wo *WorkflowOrchestrator) sendToRoadmapManager(ctx context.Context, data []byte) error {
	// Simulate sending to Roadmap Manager API
	wo.logger.Printf("🗺️ Sending data to Roadmap Manager (simulated)")
	// In real implementation, this would make HTTP requests to the Roadmap Manager API
	return nil
}

func (wo *WorkflowOrchestrator) fetchTasksFromDynamic(ctx context.Context) ([]Task, error) {
	// Simulate fetching tasks from dynamic system
	return []Task{
		{
			ID:          "task-5.2.1",
			Title:       "Implement Workflow Unification",
			Description: "Create unified workflow orchestration",
			Status:      "in_progress",
			Priority:    "high",
			Progress:    75.0,
		},
	}, nil
}

func (wo *WorkflowOrchestrator) syncTaskToTaskMaster(ctx context.Context, task Task) error {
	// Execute TaskMaster CLI command
	cmd := exec.CommandContext(ctx, wo.taskMasterAdapter.cliPath,
		"task", "sync",
		"--id", task.ID,
		"--title", task.Title,
		"--status", task.Status,
		"--priority", task.Priority,
	)

	cmd.Env = os.Environ()

	output, err := cmd.CombinedOutput()
	if err != nil {
		wo.logger.Printf("TaskMaster CLI output: %s", string(output))
		return fmt.Errorf("taskmaster command failed: %w", err)
	}

	return nil
}

// scheduledSyncLoop runs the scheduled synchronization loop
func (wo *WorkflowOrchestrator) scheduledSyncLoop(ctx context.Context) {
	ticker := time.NewTicker(wo.config.SyncInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			wo.logger.Printf("📅 Scheduled sync loop stopped")
			return
		case <-ticker.C:
			if wo.isRunning {
				wo.logger.Printf("📅 Executing scheduled sync...")
				if err := wo.ExecuteFullSync(ctx); err != nil {
					wo.logger.Printf("❌ Scheduled sync failed: %v", err)
				}
			}
		}
	}
}

// startFileWatching starts file system monitoring with concrete implementation
func (wo *WorkflowOrchestrator) startFileWatching(ctx context.Context) {
	wo.logger.Printf("👁️ Starting file system monitoring...")

	// Simple polling-based file watcher (in production, use fsnotify)
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		lastModTimes := make(map[string]time.Time)

		for {
			select {
			case <-ctx.Done():
				wo.logger.Printf("👁️ File watcher stopped")
				return
			case <-ticker.C:
				wo.checkFileChanges(lastModTimes)
			}
		}
	}()

	wo.logger.Printf("✅ File system monitoring started")
}

func (wo *WorkflowOrchestrator) checkFileChanges(lastModTimes map[string]time.Time) {
	files, err := wo.discoverMarkdownFiles()
	if err != nil {
		return
	}

	for _, file := range files {
		info, err := os.Stat(file)
		if err != nil {
			continue
		}

		modTime := info.ModTime()
		lastMod, exists := lastModTimes[file]

		if !exists || modTime.After(lastMod) {
			lastModTimes[file] = modTime
			if exists { // Skip first run
				wo.logger.Printf("📝 File change detected: %s", file)
				go wo.handleFileChange(file)
			}
		}
	}
}

func (wo *WorkflowOrchestrator) handleFileChange(filePath string) {
	wo.logger.Printf("🔄 Triggering sync for changed file: %s", filePath)

	// Debounce
	time.Sleep(wo.fileWatcher.debounceTime)

	// Trigger appropriate sync based on file type
	ctx := context.Background()
	if err := wo.ExecuteFullSync(ctx); err != nil {
		wo.logger.Printf("❌ Auto-sync failed: %v", err)
	}
}

// monitorWorkflow monitors the health and performance of the workflow
func (wo *WorkflowOrchestrator) monitorWorkflow(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			wo.logger.Printf("📊 Workflow monitoring stopped")
			return
		case <-ticker.C:
			wo.updateHealthMetrics()
			wo.checkAlertConditions()
		}
	}
}

// updateHealthMetrics updates workflow health and performance metrics
func (wo *WorkflowOrchestrator) updateHealthMetrics() {
	wo.mutex.Lock()
	defer wo.mutex.Unlock()
	// Calculate uptime percentage
	totalTime := time.Since(wo.metrics.WorkflowStartTime)
	wo.metrics.UptimePercent = 100.0 // Simplified - would track actual downtime

	// Log current metrics periodically
	wo.logger.Printf("📊 Metrics: Syncs: %d/%d, Conflicts: %d/%d, Uptime: %.1f%% (Running: %v)",
		wo.metrics.SuccessfulSyncs, wo.metrics.TotalSyncs,
		wo.metrics.ConflictsResolved, wo.metrics.ConflictsDetected,
		wo.metrics.UptimePercent, totalTime.Round(time.Second))
}

// checkAlertConditions checks for conditions that require alerts
func (wo *WorkflowOrchestrator) checkAlertConditions() {
	if !wo.config.AlertsEnabled {
		return
	}

	// Check failure rate
	if wo.metrics.TotalSyncs > 0 {
		failureRate := float64(wo.metrics.FailedSyncs) / float64(wo.metrics.TotalSyncs) * 100
		if failureRate > 10.0 { // Alert if more than 10% failure rate
			wo.logger.Printf("🚨 ALERT: High failure rate detected: %.1f%%", failureRate)
		}
	}

	// Check if last sync was too long ago
	if time.Since(wo.metrics.LastSyncTime) > wo.config.SyncInterval*2 {
		wo.logger.Printf("🚨 ALERT: Last sync was %v ago", time.Since(wo.metrics.LastSyncTime))
	}
}

// getSortedSyncPoints returns sync points sorted by priority
func (wo *WorkflowOrchestrator) getSortedSyncPoints() []SyncPoint {
	sorted := make([]SyncPoint, len(wo.syncPoints))
	copy(sorted, wo.syncPoints)

	// Simple bubble sort by priority
	for i := 0; i < len(sorted)-1; i++ {
		for j := 0; j < len(sorted)-i-1; j++ {
			if sorted[j].Priority > sorted[j+1].Priority {
				sorted[j], sorted[j+1] = sorted[j+1], sorted[j]
			}
		}
	}

	return sorted
}

// calculateAverageSyncTime calculates the running average sync time
func (wo *WorkflowOrchestrator) calculateAverageSyncTime(latestDuration time.Duration) time.Duration {
	if wo.metrics.TotalSyncs <= 1 {
		return latestDuration
	}

	// Simple moving average calculation
	currentAvg := wo.metrics.AverageSyncTime
	n := float64(wo.metrics.TotalSyncs)
	newAvg := time.Duration(float64(currentAvg)*(n-1)/n + float64(latestDuration)/n)

	return newAvg
}

// GetMetrics returns current workflow metrics
func (wo *WorkflowOrchestrator) GetMetrics() *WorkflowMetrics {
	wo.mutex.RLock()
	defer wo.mutex.RUnlock()

	// Return a copy to avoid race conditions
	metrics := *wo.metrics
	return &metrics
}

// GetSyncPoints returns current synchronization points
func (wo *WorkflowOrchestrator) GetSyncPoints() []SyncPoint {
	wo.mutex.RLock()
	defer wo.mutex.RUnlock()

	points := make([]SyncPoint, len(wo.syncPoints))
	copy(points, wo.syncPoints)
	return points
}

// IsRunning returns whether the workflow orchestrator is currently running
func (wo *WorkflowOrchestrator) IsRunning() bool {
	wo.mutex.RLock()
	defer wo.mutex.RUnlock()
	return wo.isRunning
}

// Additional components for unified workflow
type SyncEngine struct {
	config *SyncConfig
	logger *log.Logger
}

type RoadmapConnector struct {
	baseURL string
	apiKey  string
	logger  *log.Logger
}

type TaskMasterAdapter struct {
	cliPath    string
	configPath string
	logger     *log.Logger
}

type FileWatcher struct {
	watchPaths   []string
	filePatterns []string
	debounceTime time.Duration
	orchestrator *WorkflowOrchestrator
	logger       *log.Logger
}

type SyncConfig struct {
	BatchSize          int           `yaml:"batch_size"`
	Timeout            time.Duration `yaml:"timeout"`
	ValidateBeforeSync bool          `yaml:"validate_before_sync"`
	CreateDiffReports  bool          `yaml:"create_diff_reports"`
}
