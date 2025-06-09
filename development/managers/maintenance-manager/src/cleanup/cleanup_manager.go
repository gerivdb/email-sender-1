package cleanup

import (
	"context"
	"crypto/md5"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/email-sender/maintenance-manager/src/ai"
	"github.com/email-sender/maintenance-manager/src/core"
)

// CleanupManager handles intelligent file organization and cleanup
type CleanupManager struct {
	config     *core.CleanupConfig
	aiAnalyzer *ai.AIAnalyzer
	stats      *CleanupStats
}

// CleanupStats tracks cleanup operations statistics
type CleanupStats struct {
	TotalFilesScanned   int     `json:"total_files_scanned"`
	FilesDeleted        int     `json:"files_deleted"`
	FilesMoved          int     `json:"files_moved"`
	DirectoriesCreated  int     `json:"directories_created"`
	SpaceFreed          int64   `json:"space_freed_bytes"`
	DuplicatesRemoved   int     `json:"duplicates_removed"`
	OperationStartTime  time.Time `json:"operation_start_time"`
	OperationEndTime    time.Time `json:"operation_end_time"`
	ErrorCount          int     `json:"error_count"`
}

// DuplicateGroup represents a group of duplicate files
type DuplicateGroup struct {
	Hash        string   `json:"hash"`
	Files       []string `json:"files"`
	Size        int64    `json:"size"`
	KeepFile    string   `json:"keep_file"`
	RemoveFiles []string `json:"remove_files"`
}

// OrganizationRule represents a file organization rule
type OrganizationRule struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Conditions  []string `json:"conditions"`
	Actions     []string `json:"actions"`
	Priority    int      `json:"priority"`
	Enabled     bool     `json:"enabled"`
}

// CleanupTask represents a cleanup task to be executed
type CleanupTask struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"` // move, delete, organize
	Description string                 `json:"description"`
	SourcePath  string                 `json:"source_path"`
	TargetPath  string                 `json:"target_path,omitempty"`
	Priority    int                    `json:"priority"`
	Risk        string                 `json:"risk"`
	Reversible  bool                   `json:"reversible"`
	Parameters  map[string]interface{} `json:"parameters"`
}

// SafetyCheck represents safety validation for cleanup operations
type SafetyCheck struct {
	FilePath    string   `json:"file_path"`
	IsSafe      bool     `json:"is_safe"`
	Confidence  float64  `json:"confidence"`
	Warnings    []string `json:"warnings"`
	Reasons     []string `json:"reasons"`
}

// Additional structures for Level 2 and Level 3 functionality
type FilePattern struct {
	Pattern     string    `json:"pattern"`
	Type        string    `json:"type"`
	Confidence  float64   `json:"confidence"`
	Examples    []string  `json:"examples"`
	Frequency   int       `json:"frequency"`
	Risk        string    `json:"risk"`
	Suggestion  string    `json:"suggestion"`
	CreatedAt   time.Time `json:"created_at"`
}

type DirectoryAnalysis struct {
	Path                string                 `json:"path"`
	TotalFiles          int                    `json:"total_files"`
	TotalSize           int64                  `json:"total_size"`
	Depth               int                    `json:"depth"`
	FileTypes           map[string]int         `json:"file_types"`
	DuplicateRatio      float64               `json:"duplicate_ratio"`
	OrganizationScore   float64               `json:"organization_score"`
	Patterns            []FilePattern         `json:"patterns"`
	Recommendations     []string              `json:"recommendations"`
	HealthScore         float64               `json:"health_score"`
	LastAnalyzed        time.Time             `json:"last_analyzed"`
	IssuesFound         []string              `json:"issues_found"`
	OptimizationTasks   []CleanupTask         `json:"optimization_tasks"`
}

type OrganizationReport struct {
	DirectoryPath       string                 `json:"directory_path"`
	Analysis            DirectoryAnalysis      `json:"analysis"`
	BeforeStats         CleanupStats          `json:"before_stats"`
	AfterStats          CleanupStats          `json:"after_stats"`
	TasksExecuted       []CleanupTask         `json:"tasks_executed"`
	TimeSpent           time.Duration         `json:"time_spent"`
	SpaceSaved          int64                 `json:"space_saved"`
	FilesReorganized    int                   `json:"files_reorganized"`
	EfficiencyGain      float64               `json:"efficiency_gain"`
	GeneratedAt         time.Time             `json:"generated_at"`
}

// NewCleanupManager creates a new cleanup manager instance
func NewCleanupManager(config *core.CleanupConfig, aiAnalyzer *ai.AIAnalyzer) *CleanupManager {
	return &CleanupManager{
		config:     config,
		aiAnalyzer: aiAnalyzer,
		stats: &CleanupStats{
			OperationStartTime: time.Now(),
		},
	}
}

// ScanForCleanup scans the specified directories for cleanup opportunities
func (cm *CleanupManager) ScanForCleanup(ctx context.Context, directories []string) ([]CleanupTask, error) {
	cm.stats.OperationStartTime = time.Now()
	var allTasks []CleanupTask

	for _, dir := range directories {
		tasks, err := cm.scanDirectory(ctx, dir)
		if err != nil {
			cm.stats.ErrorCount++
			continue
		}
		allTasks = append(allTasks, tasks...)
	}

	// Sort tasks by priority
	sort.Slice(allTasks, func(i, j int) bool {
		return allTasks[i].Priority > allTasks[j].Priority
	})

	return allTasks, nil
}

// scanDirectory scans a single directory for cleanup opportunities
func (cm *CleanupManager) scanDirectory(ctx context.Context, directory string) ([]CleanupTask, error) {
	var tasks []CleanupTask

	// Find duplicate files
	duplicates, err := cm.findDuplicateFiles(directory)
	if err != nil {
		return nil, fmt.Errorf("failed to find duplicates: %w", err)
	}

	// Create tasks for duplicate removal
	for _, group := range duplicates {
		for _, removeFile := range group.RemoveFiles {
			task := CleanupTask{
				ID:          fmt.Sprintf("remove-duplicate-%s", cm.generateTaskID()),
				Type:        "delete",
				Description: fmt.Sprintf("Remove duplicate file: %s", removeFile),
				SourcePath:  removeFile,
				Priority:    8, // High priority for duplicates
				Risk:        "low",
				Reversible:  false,
				Parameters: map[string]interface{}{
					"duplicate_of": group.KeepFile,
					"hash":         group.Hash,
					"size":         group.Size,
				},
			}
			tasks = append(tasks, task)
		}
	}

	// Find temporary and cache files
	tempFiles, err := cm.findTemporaryFiles(directory)
	if err != nil {
		return nil, fmt.Errorf("failed to find temporary files: %w", err)
	}

	// Create tasks for temporary file cleanup
	for _, tempFile := range tempFiles {
		safety := cm.checkFileSafety(tempFile)
		if safety.IsSafe && safety.Confidence >= cm.config.SafetyThreshold {
			task := CleanupTask{
				ID:          fmt.Sprintf("remove-temp-%s", cm.generateTaskID()),
				Type:        "delete",
				Description: fmt.Sprintf("Remove temporary file: %s", tempFile),
				SourcePath:  tempFile,
				Priority:    6, // Medium priority for temp files
				Risk:        "low",
				Reversible:  false,
				Parameters: map[string]interface{}{
					"file_type": "temporary",
					"safety":    safety,
				},
			}
			tasks = append(tasks, task)
		}
	}

	// Find files for organization
	organizationTasks, err := cm.findOrganizationOpportunities(ctx, directory)
	if err != nil {
		return nil, fmt.Errorf("failed to find organization opportunities: %w", err)
	}

	tasks = append(tasks, organizationTasks...)

	return tasks, nil
}

// findDuplicateFiles finds duplicate files in a directory
func (cm *CleanupManager) findDuplicateFiles(directory string) ([]DuplicateGroup, error) {
	fileHashes := make(map[string][]string)
	var duplicateGroups []DuplicateGroup

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() || info.Size() == 0 {
			return nil
		}

		// Skip files smaller than minimum size
		if info.Size() < int64(cm.config.MinFileSize) {
			return nil
		}

		hash, err := cm.calculateFileHash(path)
		if err != nil {
			return nil // Skip files we can't hash
		}

		fileHashes[hash] = append(fileHashes[hash], path)
		cm.stats.TotalFilesScanned++

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to walk directory: %w", err)
	}

	// Identify duplicate groups
	for hash, files := range fileHashes {
		if len(files) > 1 {
			// Get file size
			info, err := os.Stat(files[0])
			if err != nil {
				continue
			}

			// Determine which file to keep (prefer newer or in better location)
			keepFile := cm.selectFileToKeep(files)
			removeFiles := make([]string, 0)
			for _, file := range files {
				if file != keepFile {
					removeFiles = append(removeFiles, file)
				}
			}

			group := DuplicateGroup{
				Hash:        hash,
				Files:       files,
				Size:        info.Size(),
				KeepFile:    keepFile,
				RemoveFiles: removeFiles,
			}

			duplicateGroups = append(duplicateGroups, group)
		}
	}

	return duplicateGroups, nil
}

// calculateFileHash calculates MD5 hash of a file
func (cm *CleanupManager) calculateFileHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// selectFileToKeep determines which duplicate file to keep
func (cm *CleanupManager) selectFileToKeep(files []string) string {
	if len(files) == 0 {
		return ""
	}

	bestFile := files[0]
	bestScore := cm.scoreFile(bestFile)

	for _, file := range files[1:] {
		score := cm.scoreFile(file)
		if score > bestScore {
			bestScore = score
			bestFile = file
		}
	}

	return bestFile
}

// scoreFile scores a file based on various criteria
func (cm *CleanupManager) scoreFile(filePath string) int {
	score := 0

	// Prefer files in main directories over subdirectories
	depth := strings.Count(filePath, string(os.PathSeparator))
	score += (10 - depth) // Higher score for less depth

	// Prefer files with better names (not temp, backup, etc.)
	basename := strings.ToLower(filepath.Base(filePath))
	if strings.Contains(basename, "temp") || strings.Contains(basename, "tmp") {
		score -= 5
	}
	if strings.Contains(basename, "backup") || strings.Contains(basename, "bak") {
		score -= 3
	}
	if strings.Contains(basename, "copy") {
		score -= 2
	}

	// Prefer newer files
	info, err := os.Stat(filePath)
	if err == nil {
		daysSinceModified := int(time.Since(info.ModTime()).Hours() / 24)
		if daysSinceModified < 30 {
			score += 3
		} else if daysSinceModified < 90 {
			score += 1
		}
	}

	return score
}

// findTemporaryFiles finds temporary and cache files for cleanup
func (cm *CleanupManager) findTemporaryFiles(directory string) ([]string, error) {
	var tempFiles []string

	tempPatterns := []string{
		"*.tmp", "*.temp", "*.cache", "*.log",
		"*~", ".DS_Store", "Thumbs.db",
		"*.bak", "*.backup",
	}

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		basename := strings.ToLower(filepath.Base(path))

		// Check against temp patterns
		for _, pattern := range tempPatterns {
			matched, err := filepath.Match(strings.ToLower(pattern), basename)
			if err == nil && matched {
				tempFiles = append(tempFiles, path)
				break
			}
		}

		// Check for old log files
		if strings.Contains(basename, ".log") && cm.isOldFile(info, 30) {
			tempFiles = append(tempFiles, path)
		}

		// Check for cache directories
		if strings.Contains(path, "cache") || strings.Contains(path, "tmp") {
			tempFiles = append(tempFiles, path)
		}

		return nil
	})

	return tempFiles, err
}

// isOldFile checks if a file is older than the specified number of days
func (cm *CleanupManager) isOldFile(info os.FileInfo, days int) bool {
	return time.Since(info.ModTime()) > time.Duration(days)*24*time.Hour
}

// findOrganizationOpportunities finds files that can be better organized
func (cm *CleanupManager) findOrganizationOpportunities(ctx context.Context, directory string) ([]CleanupTask, error) {
	var tasks []CleanupTask

	// Get list of files for AI analysis
	files, err := cm.getFilesForAnalysis(directory)
	if err != nil {
		return nil, fmt.Errorf("failed to get files for analysis: %w", err)
	}

	// Use AI to analyze organization opportunities
	if cm.aiAnalyzer != nil {
		result, err := cm.aiAnalyzer.AnalyzeFiles(ctx, files)
		if err == nil {
			// Convert AI suggestions to cleanup tasks
			for _, suggestion := range result.Suggestions {
				if suggestion.Type == "reorganize" || suggestion.Type == "subdivide" {
					task := CleanupTask{
						ID:          fmt.Sprintf("organize-%s", cm.generateTaskID()),
						Type:        "organize",
						Description: suggestion.Description,
						Priority:    suggestion.Priority,
						Risk:        "medium",
						Reversible:  true,
						Parameters: map[string]interface{}{
							"suggestion": suggestion,
							"confidence": suggestion.Confidence,
						},
					}
					tasks = append(tasks, task)
				}
			}
		}
	}

	// Apply built-in organization rules
	builtInTasks := cm.applyOrganizationRules(files)
	tasks = append(tasks, builtInTasks...)

	return tasks, nil
}

// getFilesForAnalysis collects file information for AI analysis
func (cm *CleanupManager) getFilesForAnalysis(directory string) ([]core.FileInfo, error) {
	var files []core.FileInfo

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		fileInfo := core.FileInfo{
			Path:    path,
			Size:    info.Size(),
			ModTime: info.ModTime(),
			Type:    filepath.Ext(path),
		}

		files = append(files, fileInfo)
		return nil
	})

	return files, err
}

// applyOrganizationRules applies built-in organization rules
func (cm *CleanupManager) applyOrganizationRules(files []core.FileInfo) []CleanupTask {
	var tasks []CleanupTask

	// Group files by type and suggest organization
	typeGroups := make(map[string][]core.FileInfo)
	for _, file := range files {
		ext := strings.ToLower(filepath.Ext(file.Path))
		if ext == "" {
			ext = "no_extension"
		}
		typeGroups[ext] = append(typeGroups[ext], file)
	}

	// Suggest creating type-based directories for large groups
	for ext, groupFiles := range typeGroups {
		if len(groupFiles) > 10 { // Only suggest for significant groups
			task := CleanupTask{
				ID:          fmt.Sprintf("organize-by-type-%s-%s", ext, cm.generateTaskID()),
				Type:        "organize",
				Description: fmt.Sprintf("Group %d %s files into dedicated directory", len(groupFiles), ext),
				Priority:    4,
				Risk:        "low",
				Reversible:  true,
				Parameters: map[string]interface{}{
					"organization_type": "by_extension",
					"extension":         ext,
					"file_count":        len(groupFiles),
					"files":             groupFiles,
				},
			}
			tasks = append(tasks, task)
		}
	}

	return tasks
}

// checkFileSafety checks if a file is safe to delete
func (cm *CleanupManager) checkFileSafety(filePath string) SafetyCheck {
	safety := SafetyCheck{
		FilePath:   filePath,
		IsSafe:     false,
		Confidence: 0.0,
		Warnings:   make([]string, 0),
		Reasons:    make([]string, 0),
	}

	info, err := os.Stat(filePath)
	if err != nil {
		safety.Warnings = append(safety.Warnings, "Cannot access file")
		return safety
	}

	basename := strings.ToLower(filepath.Base(filePath))

	// Check if it's a critical system file
	criticalPatterns := []string{
		"go.mod", "package.json", "requirements.txt",
		"dockerfile", "makefile", "readme",
		".gitignore", ".env",
	}

	for _, pattern := range criticalPatterns {
		if strings.Contains(basename, pattern) {
			safety.Warnings = append(safety.Warnings, "Critical configuration file")
			safety.Confidence = 0.0
			return safety
		}
	}

	// Check for temporary/cache patterns
	tempPatterns := []string{
		"tmp", "temp", "cache", ".log",
		"~", ".bak", ".backup",
	}

	for _, pattern := range tempPatterns {
		if strings.Contains(basename, pattern) {
			safety.IsSafe = true
			safety.Confidence = 0.9
			safety.Reasons = append(safety.Reasons, "Temporary or cache file")
			return safety
		}
	}

	// Check file age
	daysSinceModified := int(time.Since(info.ModTime()).Hours() / 24)
	if daysSinceModified > 180 {
		safety.IsSafe = true
		safety.Confidence = 0.8
		safety.Reasons = append(safety.Reasons, "File not modified for over 6 months")
	} else if daysSinceModified > 90 {
		safety.IsSafe = true
		safety.Confidence = 0.6
		safety.Reasons = append(safety.Reasons, "File not modified for over 3 months")
	}

	return safety
}

// ExecuteTasks executes the provided cleanup tasks
func (cm *CleanupManager) ExecuteTasks(ctx context.Context, tasks []CleanupTask, dryRun bool) error {
	for _, task := range tasks {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		if dryRun {
			fmt.Printf("DRY RUN: Would execute task: %s\n", task.Description)
			continue
		}

		err := cm.executeTask(ctx, task)
		if err != nil {
			cm.stats.ErrorCount++
			fmt.Printf("Error executing task %s: %v\n", task.ID, err)
			continue
		}

		// Update statistics based on task type
		switch task.Type {
		case "delete":
			cm.stats.FilesDeleted++
			if info, err := os.Stat(task.SourcePath); err == nil {
				cm.stats.SpaceFreed += info.Size()
			}
		case "move", "organize":
			cm.stats.FilesMoved++
		}
	}

	cm.stats.OperationEndTime = time.Now()
	return nil
}

// executeTask executes a single cleanup task
func (cm *CleanupManager) executeTask(ctx context.Context, task CleanupTask) error {
	switch task.Type {
	case "delete":
		return os.Remove(task.SourcePath)
	case "move":
		// Ensure target directory exists
		if err := os.MkdirAll(filepath.Dir(task.TargetPath), 0755); err != nil {
			return fmt.Errorf("failed to create target directory: %w", err)
		}
		return os.Rename(task.SourcePath, task.TargetPath)
	case "organize":
		return cm.executeOrganizationTask(ctx, task)
	default:
		return fmt.Errorf("unknown task type: %s", task.Type)
	}
}

// executeOrganizationTask executes an organization task
func (cm *CleanupManager) executeOrganizationTask(ctx context.Context, task CleanupTask) error {
	params := task.Parameters

	if orgType, exists := params["organization_type"]; exists && orgType == "by_extension" {
		ext := params["extension"].(string)
		files := params["files"].([]core.FileInfo)

		// Create directory for this file type
		baseDir := filepath.Dir(files[0].Path)
		typeDirName := cm.getTypeDirName(ext)
		typeDir := filepath.Join(baseDir, typeDirName)

		if err := os.MkdirAll(typeDir, 0755); err != nil {
			return fmt.Errorf("failed to create type directory: %w", err)
		}

		cm.stats.DirectoriesCreated++

		// Move files to the type directory
		for _, file := range files {
			targetPath := filepath.Join(typeDir, filepath.Base(file.Path))
			if err := os.Rename(file.Path, targetPath); err != nil {
				return fmt.Errorf("failed to move file %s: %w", file.Path, err)
			}
			cm.stats.FilesMoved++
		}
	}

	return nil
}

// getTypeDirName returns an appropriate directory name for a file type
func (cm *CleanupManager) getTypeDirName(ext string) string {
	typeDirs := map[string]string{
		".go":   "go-files",
		".js":   "javascript",
		".ts":   "typescript",
		".py":   "python",
		".java": "java",
		".md":   "documentation",
		".txt":  "text-files",
		".json": "json-data",
		".yaml": "yaml-config",
		".yml":  "yaml-config",
		".png":  "images",
		".jpg":  "images",
		".gif":  "images",
		".svg":  "images",
		".pdf":  "documents",
		".log":  "logs",
		"no_extension": "misc",
	}

	if dirName, exists := typeDirs[ext]; exists {
		return dirName
	}

	// Remove dot and use extension as directory name
	return strings.TrimPrefix(ext, ".")
}

// generateTaskID generates a unique task ID
func (cm *CleanupManager) generateTaskID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

// GetStats returns the current cleanup statistics
func (cm *CleanupManager) GetStats() CleanupStats {
	return *cm.stats
}

// GetHealthStatus returns the health status of the cleanup manager
func (cm *CleanupManager) GetHealthStatus(ctx context.Context) core.HealthStatus {
	status := core.HealthStatus{
		Status:  "healthy",
		Details: make(map[string]string),
	}

	// Add cleanup statistics as string
	status.Details["files_scanned"] = fmt.Sprintf("%d", cm.stats.TotalFilesScanned)
	status.Details["files_deleted"] = fmt.Sprintf("%d", cm.stats.FilesDeleted)
	status.Details["space_freed"] = fmt.Sprintf("%d", cm.stats.SpaceFreed)
	status.Details["safety_threshold"] = fmt.Sprintf("%.2f", cm.config.SafetyThreshold)
	status.Details["min_file_size"] = fmt.Sprintf("%d", cm.config.MinFileSize)
	status.Details["max_file_age"] = fmt.Sprintf("%d", cm.config.MaxFileAge)

	return status
}

// Reset resets the cleanup statistics
func (cm *CleanupManager) Reset() {
	cm.stats = &CleanupStats{
		OperationStartTime: time.Now(),
	}
}

// ==== LEVEL 2: INTELLIGENT PATTERN-BASED CLEANUP ====

// AnalyzePatterns analyzes file patterns in the specified directory
func (cm *CleanupManager) AnalyzePatterns(ctx context.Context, directory string) ([]FilePattern, error) {
	var patterns []FilePattern

	// Collect all files with their metadata
	fileMap := make(map[string][]string)
	namePatterns := make(map[string]int)

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}

		// Analyze file extensions
		ext := strings.ToLower(filepath.Ext(path))
		fileMap[ext] = append(fileMap[ext], path)

		// Analyze naming patterns
		basename := strings.ToLower(filepath.Base(path))

		// Extract common naming patterns
		if strings.Contains(basename, "temp") || strings.Contains(basename, "tmp") {
			namePatterns["temporary_files"]++
		}
		if strings.Contains(basename, "copy") || strings.Contains(basename, "duplicate") {
			namePatterns["duplicate_files"]++
		}
		if strings.Contains(basename, "backup") || strings.Contains(basename, "bak") {
			namePatterns["backup_files"]++
		}
		if strings.Contains(basename, "old") || strings.Contains(basename, "archive") {
			namePatterns["archive_files"]++
		}
		if strings.HasPrefix(basename, ".") {
			namePatterns["hidden_files"]++
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to analyze patterns: %w", err)
	}

	// Create patterns for file extensions
	for ext, files := range fileMap {
		if len(files) >= 3 { // Only consider patterns with multiple files
			confidence := cm.calculatePatternConfidence(len(files), len(fileMap))

			pattern := FilePattern{
				Pattern:    fmt.Sprintf("*%s", ext),
				Type:       "extension",
				Confidence: confidence,
				Examples:   files[:min(3, len(files))],
				Frequency:  len(files),
				Risk:       cm.assessPatternRisk(ext, files),
				Suggestion: cm.generatePatternSuggestion(ext, files),
				CreatedAt:  time.Now(),
			}

			patterns = append(patterns, pattern)
		}
	}

	// Create patterns for naming conventions
	for patternType, count := range namePatterns {
		if count >= 2 {
			confidence := cm.calculatePatternConfidence(count, len(namePatterns))

			pattern := FilePattern{
				Pattern:    patternType,
				Type:       "naming",
				Confidence: confidence,
				Frequency:  count,
				Risk:       cm.assessNamingPatternRisk(patternType),
				Suggestion: cm.generateNamingPatternSuggestion(patternType, count),
				CreatedAt:  time.Now(),
			}

			patterns = append(patterns, pattern)
		}
	}

	return patterns, nil
}

// DetectFilePatterns detects specific file patterns that indicate cleanup opportunities
func (cm *CleanupManager) DetectFilePatterns(ctx context.Context, directory string) ([]CleanupTask, error) {
	var tasks []CleanupTask

	patterns, err := cm.AnalyzePatterns(ctx, directory)
	if err != nil {
		return nil, fmt.Errorf("failed to detect patterns: %w", err)
	}

	for _, pattern := range patterns {
		if pattern.Confidence >= 0.7 && pattern.Risk != "high" {
			task := cm.createPatternBasedTask(pattern, directory)
			if task != nil {
				tasks = append(tasks, *task)
			}
		}
	}

	// Detect versioned files (file_v1.txt, file_v2.txt, etc.)
	versionedTasks, err := cm.detectVersionedFiles(directory)
	if err == nil {
		tasks = append(tasks, versionedTasks...)
	}

	// Detect large file clusters
	clusterTasks, err := cm.detectLargeFileClusters(directory)
	if err == nil {
		tasks = append(tasks, clusterTasks...)
	}

	return tasks, nil
}

// ApplyPatternBasedCleanup applies cleanup based on detected patterns
func (cm *CleanupManager) ApplyPatternBasedCleanup(ctx context.Context, directory string, patterns []FilePattern) ([]CleanupTask, error) {
	var tasks []CleanupTask

	for _, pattern := range patterns {
		// Only apply cleanup for high-confidence, low-risk patterns
		if pattern.Confidence >= 0.8 && pattern.Risk == "low" {
			patternTasks := cm.generatePatternCleanupTasks(pattern, directory)
			tasks = append(tasks, patternTasks...)
		}
	}

	// Sort tasks by priority and confidence
	sort.Slice(tasks, func(i, j int) bool {
		iConf := tasks[i].Parameters["confidence"].(float64)
		jConf := tasks[j].Parameters["confidence"].(float64)

		if tasks[i].Priority == tasks[j].Priority {
			return iConf > jConf
		}
		return tasks[i].Priority > tasks[j].Priority
	})

	return tasks, nil
}

// AnalyzeDirectoryStructure performs comprehensive directory structure analysis
func (cm *CleanupManager) AnalyzeDirectoryStructure(ctx context.Context, directory string) (*DirectoryAnalysis, error) {
	analysis := &DirectoryAnalysis{
		Path:          directory,
		FileTypes:     make(map[string]int),
		Patterns:      make([]FilePattern, 0),
		Recommendations: make([]string, 0),
		IssuesFound:   make([]string, 0),
		LastAnalyzed:  time.Now(),
	}

	// Analyze directory depth and structure
	maxDepth := 0
	totalFiles := 0
	totalSize := int64(0)

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			depth := strings.Count(strings.TrimPrefix(path, directory), string(os.PathSeparator))
			if depth > maxDepth {
				maxDepth = depth
			}
		} else {
			totalFiles++
			totalSize += info.Size()

			ext := strings.ToLower(filepath.Ext(path))
			if ext == "" {
				ext = "no_extension"
			}
			analysis.FileTypes[ext]++
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to analyze directory structure: %w", err)
	}

	analysis.TotalFiles = totalFiles
	analysis.TotalSize = totalSize
	analysis.Depth = maxDepth

	// Calculate organization score
	analysis.OrganizationScore = cm.calculateOrganizationScore(analysis)

	// Detect patterns
	patterns, err := cm.AnalyzePatterns(ctx, directory)
	if err == nil {
		analysis.Patterns = patterns
	}

	// Calculate duplicate ratio
	duplicates, err := cm.findDuplicateFiles(directory)
	if err == nil && totalFiles > 0 {
		duplicateCount := 0
		for _, group := range duplicates {
			duplicateCount += len(group.RemoveFiles)
		}
		analysis.DuplicateRatio = float64(duplicateCount) / float64(totalFiles)
	}

	// Generate recommendations
	analysis.Recommendations = cm.generateStructureRecommendations(analysis)

	// Identify issues
	analysis.IssuesFound = cm.identifyStructureIssues(analysis)

	// Calculate health score
	analysis.HealthScore = cm.calculateDirectoryHealthScore(analysis)

	// Generate optimization tasks
	analysis.OptimizationTasks = cm.generateOptimizationTasks(analysis)

	return analysis, nil
}

// ==== LEVEL 3: AI-DRIVEN ORGANIZATION ====

// OptimizeDirectoryStructure optimizes directory structure using AI insights
func (cm *CleanupManager) OptimizeDirectoryStructure(ctx context.Context, directory string) (*OrganizationReport, error) {
	startTime := time.Now()

	// Capture before stats
	beforeStats := *cm.stats

	// Perform directory analysis
	analysis, err := cm.AnalyzeDirectoryStructure(ctx, directory)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze directory: %w", err)
	}

	// Generate AI-driven optimization plan
	optimizationPlan, err := cm.generateAIOptimizationPlan(ctx, analysis)
	if err != nil {
		return nil, fmt.Errorf("failed to generate optimization plan: %w", err)
	}

	// Execute optimization tasks
	var executedTasks []CleanupTask
	for _, task := range optimizationPlan {
		if err := cm.executeTask(ctx, task); err != nil {
			cm.stats.ErrorCount++
			continue
		}
		executedTasks = append(executedTasks, task)
	}

	// Capture after stats
	afterStats := *cm.stats

	// Calculate efficiency gain
	efficiencyGain := cm.calculateEfficiencyGain(beforeStats, afterStats)

	report := &OrganizationReport{
		DirectoryPath:    directory,
		Analysis:         *analysis,
		BeforeStats:      beforeStats,
		AfterStats:       afterStats,
		TasksExecuted:    executedTasks,
		TimeSpent:        time.Since(startTime),
		SpaceSaved:       afterStats.SpaceFreed - beforeStats.SpaceFreed,
		FilesReorganized: afterStats.FilesMoved - beforeStats.FilesMoved,
		EfficiencyGain:   efficiencyGain,
		GeneratedAt:      time.Now(),
	}

	return report, nil
}

// GenerateOrganizationReport generates a comprehensive organization report
func (cm *CleanupManager) GenerateOrganizationReport(ctx context.Context, directory string) (*OrganizationReport, error) {
	analysis, err := cm.AnalyzeDirectoryStructure(ctx, directory)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze directory: %w", err)
	}

	// Use AI to enhance the report with insights
	var aiInsights []string
	if cm.aiAnalyzer != nil {
		files, err := cm.getFilesForAnalysis(directory)
		if err == nil {
			result, err := cm.aiAnalyzer.AnalyzeFiles(ctx, files)
			if err == nil {
				for _, suggestion := range result.Suggestions {
					aiInsights = append(aiInsights, suggestion.Description)
				}
			}
		}
	}

	report := &OrganizationReport{
		DirectoryPath: directory,
		Analysis:      *analysis,
		BeforeStats:   *cm.stats,
		GeneratedAt:   time.Now(),
	}

	// Add AI insights to recommendations
	if len(aiInsights) > 0 {
		report.Analysis.Recommendations = append(report.Analysis.Recommendations, aiInsights...)
	}

	return report, nil
}

// AnalyzeDirectoryHealth performs health analysis of directory structure
func (cm *CleanupManager) AnalyzeDirectoryHealth(ctx context.Context, directory string) (map[string]interface{}, error) {
	analysis, err := cm.AnalyzeDirectoryStructure(ctx, directory)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze directory health: %w", err)
	}

	health := map[string]interface{}{
		"overall_score":      analysis.HealthScore,
		"organization_score": analysis.OrganizationScore,
		"duplicate_ratio":    analysis.DuplicateRatio,
		"total_files":        analysis.TotalFiles,
		"total_size_mb":      float64(analysis.TotalSize) / (1024 * 1024),
		"directory_depth":    analysis.Depth,
		"file_types_count":   len(analysis.FileTypes),
		"issues_found":       analysis.IssuesFound,
		"recommendations":    analysis.Recommendations,
		"patterns_detected":  len(analysis.Patterns),
		"status":            cm.getHealthStatus(analysis.HealthScore),
		"last_analyzed":     analysis.LastAnalyzed,
	}

	// Add detailed file type distribution
	health["file_type_distribution"] = analysis.FileTypes

	// Add pattern analysis
	patternSummary := make(map[string]int)
	for _, pattern := range analysis.Patterns {
		patternSummary[pattern.Type]++
	}
	health["pattern_summary"] = patternSummary

	return health, nil
}

// ==== HELPER METHODS FOR LEVEL 2 & 3 ====

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func (cm *CleanupManager) calculatePatternConfidence(frequency, totalPatterns int) float64 {
	if totalPatterns == 0 {
		return 0.0
	}

	// Base confidence on frequency and relative occurrence
	baseConfidence := float64(frequency) / float64(totalPatterns*10)
	if baseConfidence > 1.0 {
		baseConfidence = 1.0
	}

	// Boost confidence for higher frequencies
	if frequency >= 10 {
		baseConfidence += 0.3
	} else if frequency >= 5 {
		baseConfidence += 0.2
	}

	if baseConfidence > 1.0 {
		baseConfidence = 1.0
	}

	return baseConfidence
}

func (cm *CleanupManager) assessPatternRisk(ext string, files []string) string {
	// High risk extensions
	highRisk := []string{".go", ".js", ".py", ".java", ".cpp", ".h", ".sql"}
	for _, risk := range highRisk {
		if ext == risk {
			return "high"
		}
	}

	// Medium risk extensions
	mediumRisk := []string{".json", ".yaml", ".yml", ".xml", ".config", ".cfg"}
	for _, risk := range mediumRisk {
		if ext == risk {
			return "medium"
		}
	}

	// Low risk extensions (temp, cache, etc.)
	return "low"
}

func (cm *CleanupManager) generatePatternSuggestion(ext string, files []string) string {
	if len(files) > 20 {
		return fmt.Sprintf("Consider organizing %d %s files into a dedicated subdirectory", len(files), ext)
	} else if len(files) > 10 {
		return fmt.Sprintf("Monitor %s files for potential organization", ext)
	}
	return fmt.Sprintf("Keep %s files in current location", ext)
}

func (cm *CleanupManager) assessNamingPatternRisk(patternType string) string {
	switch patternType {
	case "temporary_files", "backup_files":
		return "low"
	case "duplicate_files", "archive_files":
		return "medium"
	default:
		return "low"
	}
}

func (cm *CleanupManager) generateNamingPatternSuggestion(patternType string, count int) string {
	switch patternType {
	case "temporary_files":
		return fmt.Sprintf("Consider cleaning up %d temporary files", count)
	case "backup_files":
		return fmt.Sprintf("Review %d backup files for relevance", count)
	case "duplicate_files":
		return fmt.Sprintf("Investigate %d potential duplicate files", count)
	default:
		return fmt.Sprintf("Review %d files matching pattern %s", count, patternType)
	}
}

func (cm *CleanupManager) createPatternBasedTask(pattern FilePattern, directory string) *CleanupTask {
	if pattern.Type == "naming" && pattern.Pattern == "temporary_files" {
		return &CleanupTask{
			ID:          fmt.Sprintf("pattern-cleanup-%s", cm.generateTaskID()),
			Type:        "delete",
			Description: fmt.Sprintf("Clean up temporary files (pattern confidence: %.2f)", pattern.Confidence),
			Priority:    7,
			Risk:        pattern.Risk,
			Reversible:  false,
			Parameters: map[string]interface{}{
				"pattern":    pattern,
				"confidence": pattern.Confidence,
				"directory":  directory,
			},
		}
	}

	return nil
}

func (cm *CleanupManager) generatePatternCleanupTasks(pattern FilePattern, directory string) []CleanupTask {
	var tasks []CleanupTask

	switch pattern.Type {
	case "extension":
		if pattern.Frequency > 20 && pattern.Risk == "low" {
			task := CleanupTask{
				ID:          fmt.Sprintf("organize-extension-%s", cm.generateTaskID()),
				Type:        "organize",
				Description: fmt.Sprintf("Organize %d %s files", pattern.Frequency, pattern.Pattern),
				Priority:    4,
				Risk:        "low",
				Reversible:  true,
				Parameters: map[string]interface{}{
					"pattern":           pattern,
					"organization_type": "by_extension",
				},
			}
			tasks = append(tasks, task)
		}
	case "naming":
		if pattern.Pattern == "temporary_files" && pattern.Confidence > 0.8 {
			task := CleanupTask{
				ID:          fmt.Sprintf("cleanup-temp-%s", cm.generateTaskID()),
				Type:        "delete",
				Description: fmt.Sprintf("Clean up %d temporary files", pattern.Frequency),
				Priority:    7,
				Risk:        "low",
				Reversible:  false,
				Parameters: map[string]interface{}{
					"pattern": pattern,
				},
			}
			tasks = append(tasks, task)
		}
	}

	return tasks
}

// Helper methods for versioned file detection

func (cm *CleanupManager) extractBaseName(nameWithoutExt, pattern string) string {
	// Simple extraction - remove common version patterns
	name := nameWithoutExt
	
	// Remove patterns at the end
	if strings.Contains(name, "_v") {
		if idx := strings.LastIndex(name, "_v"); idx > 0 {
			name = name[:idx]
		}
	} else if strings.Contains(name, "_version") {
		if idx := strings.LastIndex(name, "_version"); idx > 0 {
			name = name[:idx]
		}
	} else if strings.Contains(name, "(") {
		if idx := strings.LastIndex(name, "("); idx > 0 {
			name = name[:idx]
		}
	}
	
	return strings.TrimSpace(name)
}

func (cm *CleanupManager) sortFilesByVersion(files []string) []string {
	// Simple sort by modification time as a proxy for version
	type fileWithTime struct {
		path    string
		modTime time.Time
	}
	
	var filesWithTime []fileWithTime
	for _, file := range files {
		if info, err := os.Stat(file); err == nil {
			filesWithTime = append(filesWithTime, fileWithTime{
				path:    file,
				modTime: info.ModTime(),
			})
		}
	}
	
	// Sort by modification time (oldest first)
	sort.Slice(filesWithTime, func(i, j int) bool {
		return filesWithTime[i].modTime.Before(filesWithTime[j].modTime)
	})
	
	var sortedFiles []string
	for _, f := range filesWithTime {
		sortedFiles = append(sortedFiles, f.path)
	}
	
	return sortedFiles
}

// GetHealthStatus returns the health status of the cleanup manager
func (cm *CleanupManager) GetHealthStatus(ctx context.Context) core.HealthStatus {
	status := core.HealthStatus{
		Status:  "healthy",
		Details: make(map[string]string),
	}

	// Add cleanup statistics as string
	status.Details["files_scanned"] = fmt.Sprintf("%d", cm.stats.TotalFilesScanned)
	status.Details["files_deleted"] = fmt.Sprintf("%d", cm.stats.FilesDeleted)
	status.Details["space_freed"] = fmt.Sprintf("%d", cm.stats.SpaceFreed)
	status.Details["safety_threshold"] = fmt.Sprintf("%.2f", cm.config.SafetyThreshold)
	status.Details["min_file_size"] = fmt.Sprintf("%d", cm.config.MinFileSize)
	status.Details["max_file_age"] = fmt.Sprintf("%d", cm.config.MaxFileAge)

	return status
}
