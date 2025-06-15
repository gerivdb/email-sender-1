package vectorization

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"
)

// MarkdownTaskExtractor extracts tasks from markdown files
// Based on analysis of Python vectorize_single_file.py
type MarkdownTaskExtractor struct {
	logger *zap.Logger
	client *UnifiedQdrantClient
}

// TaskExtractionConfig holds configuration for task extraction
type TaskExtractionConfig struct {
	CollectionName string `yaml:"collection_name" json:"collection_name"`
	VectorSize     int    `yaml:"vector_size" json:"vector_size"`
	BatchSize      int    `yaml:"batch_size" json:"batch_size"`
}

// ExtractedTask represents a task extracted from markdown
type ExtractedTask struct {
	Status        string
	TaskID        string
	Description   string
	Section       string
	IndentLevel   int
	ParentID      string
	IsMVP         bool
	Priority      string
	EstimatedTime string
	Category      string
	FilePath      string
}

// NewMarkdownTaskExtractor creates a new task extractor
func NewMarkdownTaskExtractor(client *UnifiedQdrantClient, logger *zap.Logger) *MarkdownTaskExtractor {
	return &MarkdownTaskExtractor{
		logger: logger,
		client: client,
	}
}

// ExtractTasksFromFile extracts tasks from a markdown file
// Migrated from Python vectorize_single_file.py regex logic
func (e *MarkdownTaskExtractor) ExtractTasksFromFile(filePath string) ([]ExtractedTask, error) {
	e.logger.Info("Extracting tasks from file", zap.String("file", filePath))

	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filePath, err)
	}

	// Task pattern from Python: r'- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
	taskPattern := regexp.MustCompile(`- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)`)

	// Section pattern from Python: r'##\s+(.*?)(?:\r?\n)'
	sectionPattern := regexp.MustCompile(`##\s+(.*?)(?:\r?\n)`)

	contentStr := string(content)
	taskMatches := taskPattern.FindAllStringSubmatch(contentStr, -1)
	sectionMatches := sectionPattern.FindAllStringSubmatch(contentStr, -1)

	e.logger.Info("Found matches",
		zap.Int("tasks", len(taskMatches)),
		zap.Int("sections", len(sectionMatches)))

	var tasks []ExtractedTask

	for _, match := range taskMatches {
		if len(match) < 4 {
			continue
		}

		status := match[1]
		taskID := match[2]
		description := strings.TrimSpace(match[3])

		// Calculate indent level (number of dots + 1)
		indentLevel := len(strings.Split(taskID, "."))

		// Calculate parent ID
		parentID := ""
		if indentLevel > 1 {
			parts := strings.Split(taskID, ".")
			parentID = strings.Join(parts[:len(parts)-1], ".")
		}

		// Find section for this task
		section := e.findSectionForTask(contentStr, match, sectionMatches)

		// Extract metadata
		isMVP := strings.Contains(description, "MVP")
		priority := e.extractPriority(description)
		estimatedTime := e.extractEstimatedTime(description)
		category := e.extractCategory(description)

		// Determine status
		taskStatus := "pending"
		if status == "x" || status == "X" {
			taskStatus = "completed"
		}

		task := ExtractedTask{
			Status:        taskStatus,
			TaskID:        taskID,
			Description:   description,
			Section:       section,
			IndentLevel:   indentLevel,
			ParentID:      parentID,
			IsMVP:         isMVP,
			Priority:      priority,
			EstimatedTime: estimatedTime,
			Category:      category,
			FilePath:      filepath.Base(filePath),
		}

		tasks = append(tasks, task)
	}

	e.logger.Info("Extracted tasks", zap.Int("count", len(tasks)))
	return tasks, nil
}

// VectorizeAndInsert vectorizes tasks and inserts them into Qdrant
func (e *MarkdownTaskExtractor) VectorizeAndInsert(ctx context.Context, tasks []ExtractedTask, config TaskExtractionConfig) error {
	if len(tasks) == 0 {
		e.logger.Info("No tasks to vectorize")
		return nil
	}

	// Ensure collection exists
	err := e.client.CreateCollection(ctx, config.CollectionName, config.VectorSize)
	if err != nil {
		// Collection might already exist, log but continue
		e.logger.Warn("Failed to create collection (might already exist)", zap.Error(err))
	}

	// Convert tasks to points
	points := make([]TaskPoint, len(tasks))
	for i, task := range tasks {
		// Generate deterministic ID from task ID (same as Python)
		idHash := e.hashString(task.TaskID + task.Description)

		// Generate vector (placeholder - in real implementation, use embedding model)
		vector := e.generateVector(task, config.VectorSize)

		points[i] = TaskPoint{
			ID:     idHash,
			Vector: vector,
			Payload: TaskPayload{
				TaskID:        task.TaskID,
				Description:   task.Description,
				Status:        task.Status,
				IndentLevel:   task.IndentLevel,
				ParentID:      task.ParentID,
				Section:       task.Section,
				IsMVP:         task.IsMVP,
				Priority:      task.Priority,
				EstimatedTime: task.EstimatedTime,
				Category:      task.Category,
				LastUpdated:   time.Now(),
				FilePath:      task.FilePath,
			},
		}
	}

	// Insert in batches
	e.logger.Info("Inserting points in batches",
		zap.Int("total_points", len(points)),
		zap.Int("batch_size", config.BatchSize))

	err = e.client.InsertPoints(ctx, config.CollectionName, points)
	if err != nil {
		return fmt.Errorf("failed to insert points: %w", err)
	}

	e.logger.Info("Successfully vectorized and inserted tasks", zap.Int("count", len(points)))
	return nil
}

// ProcessMarkdownFile processes a single markdown file (complete migration of Python script)
func (e *MarkdownTaskExtractor) ProcessMarkdownFile(ctx context.Context, filePath string, config TaskExtractionConfig) error {
	// Validate file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return fmt.Errorf("file does not exist: %s", filePath)
	}

	// Extract tasks
	tasks, err := e.ExtractTasksFromFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to extract tasks: %w", err)
	}

	if len(tasks) == 0 {
		e.logger.Info("No tasks found in file", zap.String("file", filePath))
		return nil
	}

	// Vectorize and insert
	err = e.VectorizeAndInsert(ctx, tasks, config)
	if err != nil {
		return fmt.Errorf("failed to vectorize and insert: %w", err)
	}

	return nil
}

// Helper methods (migrated from Python logic)

func (e *MarkdownTaskExtractor) findSectionForTask(content string, taskMatch []string, sectionMatches [][]string) string {
	// Find the position of the task in content
	taskIndex := strings.Index(content, taskMatch[0])
	if taskIndex == -1 {
		return "Non spécifié"
	}

	// Find the last section before this task
	lastSection := "Non spécifié"
	for _, sectionMatch := range sectionMatches {
		sectionIndex := strings.Index(content, sectionMatch[0])
		if sectionIndex != -1 && sectionIndex < taskIndex {
			lastSection = strings.TrimSpace(sectionMatch[1])
		}
	}

	return lastSection
}

func (e *MarkdownTaskExtractor) extractPriority(description string) string {
	priorityPattern := regexp.MustCompile(`\b(P[0-3])\b`)
	match := priorityPattern.FindString(description)
	if match != "" {
		return match
	}
	return "P3" // Default priority
}

func (e *MarkdownTaskExtractor) extractEstimatedTime(description string) string {
	timePattern := regexp.MustCompile(`\b(\d+[hj])\b`)
	match := timePattern.FindString(description)
	return match
}

func (e *MarkdownTaskExtractor) extractCategory(description string) string {
	categoryPattern := regexp.MustCompile(`\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b`)
	match := categoryPattern.FindString(strings.ToLower(description))
	if match != "" {
		return match
	}
	return "non_categorise"
}

func (e *MarkdownTaskExtractor) hashString(s string) int {
	hash := 0
	for _, char := range s {
		hash = hash*31 + int(char)
	}
	// Ensure positive 31-bit integer (same as Python % 2**31)
	return hash & 0x7FFFFFFF
}

func (e *MarkdownTaskExtractor) generateVector(task ExtractedTask, size int) []float32 {
	// TODO: Replace with real embedding model (sentence-transformers equivalent)
	// For now, generate deterministic vector based on task content
	seed := e.hashString(task.TaskID + task.Description)

	vector := make([]float32, size)
	for i := range vector {
		// Simple deterministic generation (replace with real embeddings)
		seed = seed*1664525 + 1013904223
		vector[i] = float32(seed%10000-5000) / 5000.0 // Normalize to [-1, 1]
	}

	return vector
}
