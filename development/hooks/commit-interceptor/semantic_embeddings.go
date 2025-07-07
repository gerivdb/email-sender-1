// development/hooks/commit-interceptor/semantic_embeddings.go
package commitinterceptor

import (
	"context"
	"crypto/md5"
	"fmt"
	"log"
	"strings"
	"time"
)

// CommitContext represents the complete context of a commit for semantic analysis
type CommitContext struct {
	Files          []string               `json:"files"`
	Message        string                 `json:"message"`
	Author         string                 `json:"author"`
	Timestamp      time.Time              `json:"timestamp"`
	Hash           string                 `json:"hash"`
	Embeddings     []float64              `json:"embeddings"`
	PredictedType  string                 `json:"predicted_type"`
	Confidence     float64                `json:"confidence"`
	RelatedCommits []string               `json:"related_commits"`
	Impact         string                 `json:"impact"`
	Keywords       []string               `json:"keywords"`
	SemanticScore  float64                `json:"semantic_score"`
	ContextID      string                 `json:"context_id"`
	ProjectHistory *ProjectHistory        `json:"project_history,omitempty"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// ProjectHistory represents historical patterns for the project
type ProjectHistory struct {
	TotalCommits     int                 `json:"total_commits"`
	CommitPatterns   map[string]int      `json:"commit_patterns"`
	AuthorPatterns   map[string][]string `json:"author_patterns"`
	FilePatterns     map[string][]string `json:"file_patterns"`
	RecentCommits    []*CommitContext    `json:"recent_commits"`
	SemanticClusters map[string][]string `json:"semantic_clusters"`
}

// SemanticEmbeddingManager manages semantic analysis and embeddings
type SemanticEmbeddingManager struct {
	config             *Config
	embeddingCache     map[string][]float64
	commitHistoryCache map[string]*CommitContext
	autonomyManager    AdvancedAutonomyManagerInterface
	contextualMemory   ContextualMemoryInterface
	projectHistory     *ProjectHistory
	semanticThreshold  float64
	maxHistorySize     int
}

// AdvancedAutonomyManagerInterface defines the interface for AI/ML integration
type AdvancedAutonomyManagerInterface interface {
	GenerateEmbeddings(ctx context.Context, text string) ([]float64, error)
	PredictCommitType(ctx context.Context, embeddings []float64, history *ProjectHistory) (string, float64, error)
	DetectConflicts(ctx context.Context, files []string, embeddings []float64) (float64, error)
	AnalyzeSimilarity(ctx context.Context, embeddings1, embeddings2 []float64) (float64, error)
	TrainOnHistory(ctx context.Context, history []*CommitContext) error
}

// ContextualMemoryInterface defines the interface for contextual memory operations
type ContextualMemoryInterface interface {
	StoreCommitContext(ctx context.Context, commitCtx *CommitContext) error
	RetrieveSimilarCommits(ctx context.Context, embeddings []float64, limit int) ([]*CommitContext, error)
	UpdateProjectHistory(ctx context.Context, commitCtx *CommitContext) error
	GetProjectHistory(ctx context.Context) (*ProjectHistory, error)
	CacheEmbeddings(key string, embeddings []float64) error
	GetCachedEmbeddings(key string) ([]float64, bool)
}

// MockAdvancedAutonomyManager provides a mock implementation for testing
type MockAdvancedAutonomyManager struct {
	embeddingDimension int
}

// NewMockAdvancedAutonomyManager creates a new mock autonomy manager
func NewMockAdvancedAutonomyManager() *MockAdvancedAutonomyManager {
	return &MockAdvancedAutonomyManager{
		embeddingDimension: 384, // Standard sentence-transformer dimension
	}
}

// GenerateEmbeddings generates mock embeddings based on text content
func (m *MockAdvancedAutonomyManager) GenerateEmbeddings(ctx context.Context, text string) ([]float64, error) {
	// Simple hash-based embedding for deterministic testing
	hash := md5.Sum([]byte(text))
	embeddings := make([]float64, m.embeddingDimension)

	for i := 0; i < m.embeddingDimension; i++ {
		embeddings[i] = float64(hash[i%16]) / 255.0 // Normalize to [0,1]
	}

	// Add some semantic meaning based on keywords
	keywords := []string{"feat", "fix", "refactor", "docs", "test", "chore"}
	lowerText := strings.ToLower(text)

	for i, keyword := range keywords {
		if strings.Contains(lowerText, keyword) {
			// Boost certain dimensions for semantic clustering
			startIdx := i * (m.embeddingDimension / len(keywords))
			endIdx := (i + 1) * (m.embeddingDimension / len(keywords))
			for j := startIdx; j < endIdx && j < m.embeddingDimension; j++ {
				embeddings[j] += 0.3 // Semantic boost
			}
		}
	}

	return embeddings, nil
}

// PredictCommitType predicts the commit type based on embeddings and history
func (m *MockAdvancedAutonomyManager) PredictCommitType(ctx context.Context, embeddings []float64, history *ProjectHistory) (string, float64, error) {
	if len(embeddings) == 0 {
		return "chore", 0.5, nil
	}

	// Simple prediction based on embedding patterns
	avgEmbedding := 0.0
	for _, val := range embeddings[:10] { // Use first 10 dimensions
		avgEmbedding += val
	}
	avgEmbedding /= 10.0

	commitTypes := []string{"feature", "fix", "refactor", "docs", "test", "chore"}
	predictedType := commitTypes[int(avgEmbedding*float64(len(commitTypes)))%len(commitTypes)]

	confidence := 0.8 + (avgEmbedding * 0.15) // Range: 0.8-0.95

	return predictedType, confidence, nil
}

// DetectConflicts predicts potential conflicts based on file patterns and embeddings
func (m *MockAdvancedAutonomyManager) DetectConflicts(ctx context.Context, files []string, embeddings []float64) (float64, error) {
	if len(files) == 0 {
		return 0.0, nil
	}

	conflictRisk := 0.0

	// Higher risk for certain file patterns
	riskPatterns := map[string]float64{
		"main.go":    0.7,
		"config":     0.6,
		"Dockerfile": 0.5,
		"go.mod":     0.8,
		".github":    0.4,
		"Makefile":   0.3,
	}

	for _, file := range files {
		for pattern, risk := range riskPatterns {
			if strings.Contains(file, pattern) {
				conflictRisk += risk
			}
		}
	}

	// Normalize by number of files
	if len(files) > 0 {
		conflictRisk /= float64(len(files))
	}

	// Cap at 1.0
	if conflictRisk > 1.0 {
		conflictRisk = 1.0
	}

	return conflictRisk, nil
}

// AnalyzeSimilarity analyzes similarity between two embeddings using cosine similarity
func (m *MockAdvancedAutonomyManager) AnalyzeSimilarity(ctx context.Context, embeddings1, embeddings2 []float64) (float64, error) {
	if len(embeddings1) != len(embeddings2) || len(embeddings1) == 0 {
		return 0.0, fmt.Errorf("embeddings must have same non-zero length")
	}

	// Calculate cosine similarity
	dotProduct := 0.0
	norm1 := 0.0
	norm2 := 0.0

	for i := 0; i < len(embeddings1); i++ {
		dotProduct += embeddings1[i] * embeddings2[i]
		norm1 += embeddings1[i] * embeddings1[i]
		norm2 += embeddings2[i] * embeddings2[i]
	}

	if norm1 == 0.0 || norm2 == 0.0 {
		return 0.0, nil
	}

	similarity := dotProduct / (norm1 * norm2)
	return similarity, nil
}

// TrainOnHistory trains the model on historical commits
func (m *MockAdvancedAutonomyManager) TrainOnHistory(ctx context.Context, history []*CommitContext) error {
	// Mock training - just log the training data
	log.Printf("Training on %d historical commits", len(history))
	return nil
}

// MockContextualMemory provides a mock implementation for testing
type MockContextualMemory struct {
	commitStore map[string]*CommitContext
	embeddings  map[string][]float64
}

// NewMockContextualMemory creates a new mock contextual memory
func NewMockContextualMemory() *MockContextualMemory {
	return &MockContextualMemory{
		commitStore: make(map[string]*CommitContext),
		embeddings:  make(map[string][]float64),
	}
}

// StoreCommitContext stores a commit context
func (m *MockContextualMemory) StoreCommitContext(ctx context.Context, commitCtx *CommitContext) error {
	m.commitStore[commitCtx.ContextID] = commitCtx
	return nil
}

// RetrieveSimilarCommits retrieves commits similar to the given embeddings
func (m *MockContextualMemory) RetrieveSimilarCommits(ctx context.Context, embeddings []float64, limit int) ([]*CommitContext, error) {
	var results []*CommitContext
	count := 0

	for _, commit := range m.commitStore {
		if count >= limit {
			break
		}
		// Simple similarity check - in real implementation, use vector database
		if len(commit.Embeddings) > 0 {
			results = append(results, commit)
			count++
		}
	}

	return results, nil
}

// UpdateProjectHistory updates the project history with new commit
func (m *MockContextualMemory) UpdateProjectHistory(ctx context.Context, commitCtx *CommitContext) error {
	// Mock implementation
	return nil
}

// GetProjectHistory retrieves the project history
func (m *MockContextualMemory) GetProjectHistory(ctx context.Context) (*ProjectHistory, error) {
	return &ProjectHistory{
		TotalCommits:     len(m.commitStore),
		CommitPatterns:   make(map[string]int),
		AuthorPatterns:   make(map[string][]string),
		FilePatterns:     make(map[string][]string),
		RecentCommits:    make([]*CommitContext, 0),
		SemanticClusters: make(map[string][]string),
	}, nil
}

// CacheEmbeddings caches embeddings
func (m *MockContextualMemory) CacheEmbeddings(key string, embeddings []float64) error {
	m.embeddings[key] = embeddings
	return nil
}

// GetCachedEmbeddings retrieves cached embeddings
func (m *MockContextualMemory) GetCachedEmbeddings(key string) ([]float64, bool) {
	embeddings, exists := m.embeddings[key]
	return embeddings, exists
}

// NewSemanticEmbeddingManager creates a new semantic embedding manager
func NewSemanticEmbeddingManager(config *Config) *SemanticEmbeddingManager {
	return &SemanticEmbeddingManager{
		config:             config,
		embeddingCache:     make(map[string][]float64),
		commitHistoryCache: make(map[string]*CommitContext),
		autonomyManager:    NewMockAdvancedAutonomyManager(),
		contextualMemory:   NewMockContextualMemory(),
		semanticThreshold:  0.7,
		maxHistorySize:     1000,
		projectHistory: &ProjectHistory{
			CommitPatterns:   make(map[string]int),
			AuthorPatterns:   make(map[string][]string),
			FilePatterns:     make(map[string][]string),
			RecentCommits:    make([]*CommitContext, 0),
			SemanticClusters: make(map[string][]string),
		},
	}
}

// CreateCommitContext creates a comprehensive commit context for semantic analysis
func (sem *SemanticEmbeddingManager) CreateCommitContext(ctx context.Context, data *CommitData) (*CommitContext, error) {
	// Generate context ID
	contextID := fmt.Sprintf("%x", md5.Sum([]byte(data.Message+data.Hash+data.Author)))

	// Create commit context
	commitContext := &CommitContext{
		Files:     data.Files,
		Message:   data.Message,
		Author:    data.Author,
		Timestamp: data.Timestamp,
		Hash:      data.Hash,
		ContextID: contextID,
		Keywords:  extractKeywords(data.Message),
		Metadata:  make(map[string]interface{}),
	}

	// Generate text for embedding
	embeddingText := fmt.Sprintf("%s %s", data.Message, strings.Join(data.Files, " "))

	// Check cache first
	if cached, exists := sem.embeddingCache[embeddingText]; exists {
		commitContext.Embeddings = cached
	} else {
		// Generate new embeddings
		embeddings, err := sem.autonomyManager.GenerateEmbeddings(ctx, embeddingText)
		if err != nil {
			return nil, fmt.Errorf("failed to generate embeddings: %w", err)
		}
		commitContext.Embeddings = embeddings

		// Cache the embeddings
		sem.embeddingCache[embeddingText] = embeddings
	}

	// Predict commit type
	if sem.projectHistory != nil {
		predictedType, confidence, err := sem.autonomyManager.PredictCommitType(ctx, commitContext.Embeddings, sem.projectHistory)
		if err == nil {
			commitContext.PredictedType = predictedType
			commitContext.Confidence = confidence
		}
	}

	// Calculate semantic score
	commitContext.SemanticScore = calculateSemanticScore(commitContext.Embeddings)

	// Detect potential conflicts
	conflictProb, err := sem.autonomyManager.DetectConflicts(ctx, data.Files, commitContext.Embeddings)
	if err == nil {
		commitContext.Metadata["conflict_probability"] = conflictProb
	}

	// Find related commits
	relatedCommits, err := sem.contextualMemory.RetrieveSimilarCommits(ctx, commitContext.Embeddings, 5)
	if err == nil && len(relatedCommits) > 0 {
		for _, related := range relatedCommits {
			commitContext.RelatedCommits = append(commitContext.RelatedCommits, related.Hash)
		}
	}

	// Store in contextual memory
	err = sem.contextualMemory.StoreCommitContext(ctx, commitContext)
	if err != nil {
		log.Printf("Warning: Failed to store commit context: %v", err)
	}

	return commitContext, nil
}

// extractKeywords extracts keywords from commit message
func extractKeywords(message string) []string {
	words := strings.Fields(strings.ToLower(message))
	keywords := []string{}

	// Common commit keywords to extract
	commitKeywords := map[string]bool{
		"fix": true, "feat": true, "feature": true, "add": true, "remove": true,
		"update": true, "refactor": true, "test": true, "docs": true, "style": true,
		"chore": true, "build": true, "ci": true, "perf": true, "revert": true,
		"merge": true, "hotfix": true, "bugfix": true, "improvement": true,
	}

	for _, word := range words {
		// Remove punctuation
		cleaned := strings.Trim(word, ".,!?:;()[]{}\"'")
		if commitKeywords[cleaned] {
			keywords = append(keywords, cleaned)
		}
	}

	return keywords
}

// calculateSemanticScore calculates a semantic score from embeddings
func calculateSemanticScore(embeddings []float64) float64 {
	if len(embeddings) == 0 {
		return 0.0
	}

	// Simple calculation: average of first 50 dimensions
	sum := 0.0
	count := minInt(50, len(embeddings))

	for i := 0; i < count; i++ {
		sum += embeddings[i]
	}

	return sum / float64(count)
}

// minInt returns the minimum of two integers
func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// TrainOnCommitHistory trains the semantic system on historical commits
func (sem *SemanticEmbeddingManager) TrainOnCommitHistory(ctx context.Context, commits []*CommitData) error {
	log.Printf("Training semantic system on %d commits", len(commits))

	var contexts []*CommitContext
	for _, commit := range commits {
		commitCtx, err := sem.CreateCommitContext(ctx, commit)
		if err != nil {
			log.Printf("Warning: Failed to create context for commit %s: %v", commit.Hash, err)
			continue
		}
		contexts = append(contexts, commitCtx)
	}

	// Train the autonomy manager
	err := sem.autonomyManager.TrainOnHistory(ctx, contexts)
	if err != nil {
		return fmt.Errorf("failed to train autonomy manager: %w", err)
	}

	log.Printf("Successfully trained semantic system on %d commits", len(contexts))
	return nil
}
