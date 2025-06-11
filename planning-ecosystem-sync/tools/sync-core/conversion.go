package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"
	"crypto/sha256"
	"encoding/hex"
	"strings"
)

// DynamicPlan represents a plan in the dynamic system format
type DynamicPlan struct {
	ID          string      `json:"id"`
	Metadata    PlanMetadata `json:"metadata"`
	Tasks       []Task      `json:"tasks"`
	Embeddings  []float64   `json:"embeddings"`
	CreatedAt   time.Time   `json:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at"`
}

// PlanMetadata contains plan metadata
type PlanMetadata struct {
	FilePath    string  `json:"file_path"`
	Title       string  `json:"title"`
	Version     string  `json:"version"`
	Date        string  `json:"date"`
	Progression float64 `json:"progression"`
	Description string  `json:"description"`
}

// Task represents a task within a plan
type Task struct {
	ID           string    `json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	Status       string    `json:"status"` // "pending", "in_progress", "completed"
	Phase        string    `json:"phase"`
	Level        int       `json:"level"` // hierarchy level (1=phase, 2=section, 3=subsection, etc.)
	Dependencies []string  `json:"dependencies"`
	Priority     string    `json:"priority"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	Completed    bool      `json:"completed"`
}

// MarkdownParser handles parsing of markdown plans
type MarkdownParser struct {
	logger *log.Logger
}

// NewMarkdownParser creates a new MarkdownParser instance
func NewMarkdownParser() *MarkdownParser {
	return &MarkdownParser{
		logger: log.Default(),
	}
}

// ConvertToDynamic converts parsed markdown data to dynamic plan format
func (mp *MarkdownParser) ConvertToDynamic(metadata *PlanMetadata, tasks []Task) (*DynamicPlan, error) {
	mp.logger.Printf("🔄 Converting plan to dynamic format: %s", metadata.Title)
	
	plan := &DynamicPlan{
		ID:        generatePlanID(metadata.FilePath),
		Metadata:  *metadata,
		Tasks:     tasks,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	
	// Générer embeddings pour recherche sémantique
	embeddings, err := mp.generateEmbeddings(metadata.Title, tasks)
	if err != nil {
		mp.logger.Printf("⚠️  Warning: Failed to generate embeddings: %v", err)
		// Continue without embeddings rather than failing completely
		plan.Embeddings = []float64{}
	} else {
		plan.Embeddings = embeddings
		mp.logger.Printf("✅ Generated %d-dimensional embeddings", len(embeddings))
	}
	
	mp.logger.Printf("✅ Successfully converted plan with %d tasks", len(tasks))
	return plan, nil
}

// generatePlanID creates a unique ID for a plan based on its file path
func generatePlanID(filePath string) string {
	hash := sha256.Sum256([]byte(filePath))
	return fmt.Sprintf("plan_%s", hex.EncodeToString(hash[:8]))
}

// generateEmbeddings creates vector embeddings for semantic search
// This is a simplified implementation - in production, you'd use a proper embedding service
func (mp *MarkdownParser) generateEmbeddings(title string, tasks []Task) ([]float64, error) {
	mp.logger.Printf("🔍 Generating embeddings for plan: %s", title)
	
	// Combine title and task content for embedding generation
	var content strings.Builder
	content.WriteString(title)
	content.WriteString(" ")
	
	for _, task := range tasks {
		content.WriteString(task.Title)
		content.WriteString(" ")
		content.WriteString(task.Description)
		content.WriteString(" ")
	}
	
	// For demonstration purposes, create a simple embedding based on content analysis
	// In production, this would call an actual embedding service (OpenAI, etc.)
	embeddings := mp.createSimpleEmbedding(content.String())
	
	return embeddings, nil
}

// createSimpleEmbedding creates a simple 384-dimensional embedding
// This is a placeholder - replace with actual embedding service in production
func (mp *MarkdownParser) createSimpleEmbedding(content string) []float64 {
	// Create 384-dimensional embedding (standard for many models)
	embeddings := make([]float64, 384)
	
	// Simple heuristic-based embedding generation
	words := strings.Fields(strings.ToLower(content))
	wordCount := float64(len(words))
	
	// Fill embeddings with normalized values based on content characteristics
	for i := range embeddings {
		// Use content characteristics to generate meaningful values
		seed := float64(i) * wordCount
		embeddings[i] = (seed - float64(int(seed))) * 2.0 - 1.0 // Normalize to [-1, 1]
	}
	
	return embeddings
}

// ValidateConversion validates the converted plan for consistency
func (mp *MarkdownParser) ValidateConversion(plan *DynamicPlan) error {
	mp.logger.Printf("🔍 Validating converted plan: %s", plan.ID)
	
	// Validate required fields
	if plan.ID == "" {
		return fmt.Errorf("plan ID is required")
	}
	
	if plan.Metadata.Title == "" {
		return fmt.Errorf("plan title is required")
	}
	
	if len(plan.Tasks) == 0 {
		return fmt.Errorf("plan must contain at least one task")
	}
	
	// Validate tasks
	for i, task := range plan.Tasks {
		if task.ID == "" {
			return fmt.Errorf("task %d: ID is required", i)
		}
		if task.Title == "" {
			return fmt.Errorf("task %d: title is required", i)
		}
		if task.Status == "" {
			task.Status = "pending" // Set default status
		}
	}
	
	// Validate embeddings dimension (should be 384 for compatibility)
	if len(plan.Embeddings) > 0 && len(plan.Embeddings) != 384 {
		return fmt.Errorf("embeddings dimension should be 384, got %d", len(plan.Embeddings))
	}
	
	mp.logger.Printf("✅ Plan validation successful")
	return nil
}

// SerializePlan converts the plan to JSON format for storage
func (mp *MarkdownParser) SerializePlan(plan *DynamicPlan) ([]byte, error) {
	mp.logger.Printf("📄 Serializing plan: %s", plan.ID)
	
	data, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to serialize plan: %w", err)
	}
	
	mp.logger.Printf("✅ Plan serialized successfully (%d bytes)", len(data))
	return data, nil
}
