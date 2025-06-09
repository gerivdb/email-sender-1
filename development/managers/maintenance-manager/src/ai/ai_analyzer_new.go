// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\maintenance-manager\src\ai\ai_analyzer.go
package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"maintenance-manager/src/core"
	"maintenance-manager/src/vector"
)

// AIAnalyzer provides AI-driven analysis and optimization capabilities
type AIAnalyzer struct {
	config       *core.AIConfig
	vectorDB     *vector.QdrantManager
	httpClient   *http.Client
	apiKey       string
	endpoint     string
	learningData *LearningData
	patternCache map[string]*AnalysisPattern
}

// LearningData contains accumulated learning information
type LearningData struct {
	FileClassifications map[string]string         `json:"file_classifications"`
	OptimizationHistory []core.OptimizationRecord `json:"optimization_history"`
	UserPreferences     map[string]interface{}    `json:"user_preferences"`
	SuccessfulPatterns  []PatternSuccess          `json:"successful_patterns"`
	LastUpdated         time.Time                 `json:"last_updated"`
}

// PatternSuccess records successful pattern applications
type PatternSuccess struct {
	Pattern    string    `json:"pattern"`
	Context    string    `json:"context"`
	Success    bool      `json:"success"`
	Timestamp  time.Time `json:"timestamp"`
	Confidence float64   `json:"confidence"`
}

// AnalysisPattern represents a recognized file organization pattern
type AnalysisPattern struct {
	ID              string                 `json:"id"`
	Name            string                 `json:"name"`
	Description     string                 `json:"description"`
	FileTypes       []string               `json:"file_types"`
	FolderStructure map[string]interface{} `json:"folder_structure"`
	Conditions      []string               `json:"conditions"`
	Actions         []string               `json:"actions"`
	Confidence      float64                `json:"confidence"`
	UsageCount      int                    `json:"usage_count"`
	SuccessRate     float64                `json:"success_rate"`
}

// AIRequest represents a request to the AI service
type AIRequest struct {
	Model       string      `json:"model"`
	Messages    []AIMessage `json:"messages"`
	MaxTokens   int         `json:"max_tokens,omitempty"`
	Temperature float64     `json:"temperature,omitempty"`
}

// AIMessage represents a message in the AI conversation
type AIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// AIResponse represents the response from the AI service
type AIResponse struct {
	Choices []AIChoice `json:"choices"`
	Usage   AIUsage    `json:"usage"`
}

// AIChoice represents a choice in the AI response
type AIChoice struct {
	Message      AIMessage `json:"message"`
	FinishReason string    `json:"finish_reason"`
}

// AIUsage represents token usage information
type AIUsage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// NewAIAnalyzer creates a new AI analyzer instance
func NewAIAnalyzer(config *core.AIConfig, vectorDB *vector.QdrantManager) (*AIAnalyzer, error) {
	analyzer := &AIAnalyzer{
		config:   config,
		vectorDB: vectorDB,
		httpClient: &http.Client{
			Timeout: time.Duration(config.Timeout) * time.Second,
		},
		apiKey:       config.APIKey,
		endpoint:     config.Endpoint,
		patternCache: make(map[string]*AnalysisPattern),
		learningData: &LearningData{
			FileClassifications: make(map[string]string),
			OptimizationHistory: make([]core.OptimizationRecord, 0),
			UserPreferences:     make(map[string]interface{}),
			SuccessfulPatterns:  make([]PatternSuccess, 0),
			LastUpdated:         time.Now(),
		},
	}

	// Load existing learning data if available
	if err := analyzer.loadLearningData(); err != nil {
		// Log warning but continue - missing learning data is not critical
		fmt.Printf("Warning: Failed to load existing learning data: %v\n", err)
	}

	// Initialize built-in patterns
	analyzer.initializeBuiltInPatterns()

	return analyzer, nil
}

// AnalyzeFiles performs AI-driven analysis of files and directories
func (ai *AIAnalyzer) AnalyzeFiles(ctx context.Context, files []core.FileInfo) (*core.AnalysisResult, error) {
	result := &core.AnalysisResult{
		Timestamp:   time.Now(),
		TotalFiles:  len(files),
		Suggestions: make([]core.OptimizationSuggestion, 0),
		Issues:      make([]string, 0),
		Confidence:  0.0,
	}

	// Classify files using AI
	classifications, err := ai.classifyFiles(ctx, files)
	if err != nil {
		return nil, fmt.Errorf("failed to classify files: %w", err)
	}

	// Detect patterns and generate suggestions
	patterns := ai.detectPatterns(files, classifications)
	suggestions := ai.generateSuggestions(patterns, files)

	result.Suggestions = suggestions
	result.Confidence = ai.calculateOverallConfidence(suggestions)

	// Store results in vector database for future learning
	if err := ai.storeAnalysisResults(ctx, result); err != nil {
		fmt.Printf("Warning: Failed to store analysis results: %v\n", err)
	}

	return result, nil
}

// classifyFiles uses AI to classify files based on content and metadata
func (ai *AIAnalyzer) classifyFiles(ctx context.Context, files []core.FileInfo) (map[string]string, error) {
	classifications := make(map[string]string)

	// Batch files for efficient processing
	batchSize := 10
	for i := 0; i < len(files); i += batchSize {
		end := i + batchSize
		if end > len(files) {
			end = len(files)
		}

		batch := files[i:end]
		batchClassifications, err := ai.classifyFileBatch(ctx, batch)
		if err != nil {
			return nil, fmt.Errorf("failed to classify batch: %w", err)
		}

		for path, classification := range batchClassifications {
			classifications[path] = classification
		}
	}

	return classifications, nil
}

// classifyFileBatch classifies a batch of files using AI
func (ai *AIAnalyzer) classifyFileBatch(ctx context.Context, files []core.FileInfo) (map[string]string, error) {
	if ai.apiKey == "" {
		// Fallback to heuristic classification if no AI service available
		return ai.heuristicClassification(files), nil
	}

	// Prepare file information for AI analysis
	fileInfos := make([]string, len(files))
	for i, file := range files {
		fileInfos[i] = fmt.Sprintf("Path: %s, Size: %d, Type: %s, Modified: %s",
			file.Path, file.Size, file.Type, file.ModTime.Format(time.RFC3339))
	}

	prompt := fmt.Sprintf(`Analyze the following files and classify each one into categories like:
- source_code (programming files)
- documentation (docs, readme, etc.)
- configuration (config files)
- data (json, csv, xml, etc.)
- media (images, videos, audio)
- temporary (cache, logs, tmp)
- build_artifacts (compiled files, dist)
- test_files (test code, fixtures)

Files to classify:
%s

Respond with JSON format: {"file_path": "category"}`, strings.Join(fileInfos, "\n"))

	response, err := ai.callAI(ctx, prompt)
	if err != nil {
		// Fallback to heuristic classification
		return ai.heuristicClassification(files), nil
	}

	// Parse AI response
	var classifications map[string]string
	if err := json.Unmarshal([]byte(response), &classifications); err != nil {
		// Fallback to heuristic classification
		return ai.heuristicClassification(files), nil
	}

	return classifications, nil
}

// heuristicClassification provides fallback classification without AI
func (ai *AIAnalyzer) heuristicClassification(files []core.FileInfo) map[string]string {
	classifications := make(map[string]string)

	for _, file := range files {
		ext := strings.ToLower(filepath.Ext(file.Path))
		basename := strings.ToLower(filepath.Base(file.Path))

		switch {
		case strings.Contains(ext, ".go") || strings.Contains(ext, ".js") || strings.Contains(ext, ".py") || strings.Contains(ext, ".java"):
			classifications[file.Path] = "source_code"
		case strings.Contains(basename, "readme") || strings.Contains(ext, ".md") || strings.Contains(ext, ".txt"):
			classifications[file.Path] = "documentation"
		case strings.Contains(ext, ".json") || strings.Contains(ext, ".yaml") || strings.Contains(ext, ".yml") || strings.Contains(ext, ".toml"):
			classifications[file.Path] = "configuration"
		case strings.Contains(ext, ".csv") || strings.Contains(ext, ".xml"):
			classifications[file.Path] = "data"
		case strings.Contains(ext, ".jpg") || strings.Contains(ext, ".png") || strings.Contains(ext, ".mp4"):
			classifications[file.Path] = "media"
		case strings.Contains(basename, "test") || strings.Contains(file.Path, "/test/"):
			classifications[file.Path] = "test_files"
		case strings.Contains(ext, ".log") || strings.Contains(basename, "cache") || strings.Contains(basename, "tmp"):
			classifications[file.Path] = "temporary"
		default:
			classifications[file.Path] = "unknown"
		}
	}

	return classifications
}

// detectPatterns identifies organizational patterns in the file structure
func (ai *AIAnalyzer) detectPatterns(files []core.FileInfo, classifications map[string]string) []*AnalysisPattern {
	patterns := make([]*AnalysisPattern, 0)

	// Group files by directory
	dirGroups := make(map[string][]core.FileInfo)
	for _, file := range files {
		dir := filepath.Dir(file.Path)
		dirGroups[dir] = append(dirGroups[dir], file)
	}

	// Analyze each directory for patterns
	for dir, dirFiles := range dirGroups {
		if len(dirFiles) > 5 { // Only analyze directories with sufficient files
			pattern := ai.analyzeDirectoryPattern(dir, dirFiles, classifications)
			if pattern != nil {
				patterns = append(patterns, pattern)
			}
		}
	}

	return patterns
}

// analyzeDirectoryPattern analyzes a directory for organizational patterns
func (ai *AIAnalyzer) analyzeDirectoryPattern(dir string, files []core.FileInfo, classifications map[string]string) *AnalysisPattern {
	// Count file types in this directory
	typeCount := make(map[string]int)
	for _, file := range files {
		if classification, exists := classifications[file.Path]; exists {
			typeCount[classification]++
		}
	}

	// Find dominant type
	var dominantType string
	maxCount := 0
	for fileType, count := range typeCount {
		if count > maxCount {
			maxCount = count
			dominantType = fileType
		}
	}

	// Calculate confidence based on type concentration
	confidence := float64(maxCount) / float64(len(files))

	if confidence > 0.7 { // High confidence threshold
		return &AnalysisPattern{
			ID:          fmt.Sprintf("pattern-%s-%d", strings.ReplaceAll(dir, "/", "-"), time.Now().Unix()),
			Name:        fmt.Sprintf("%s directory pattern", dominantType),
			Description: fmt.Sprintf("Directory %s contains primarily %s files", dir, dominantType),
			FileTypes:   []string{dominantType},
			Confidence:  confidence,
			UsageCount:  1,
			SuccessRate: 0.0, // Will be updated based on user feedback
		}
	}

	return nil
}

// generateSuggestions creates optimization suggestions based on patterns
func (ai *AIAnalyzer) generateSuggestions(patterns []*AnalysisPattern, files []core.FileInfo) []core.OptimizationSuggestion {
	suggestions := make([]core.OptimizationSuggestion, 0)

	// Generate suggestions based on detected patterns
	for _, pattern := range patterns {
		if pattern.Confidence > 0.8 {
			suggestion := core.OptimizationSuggestion{
				Type:        "reorganize",
				Description: fmt.Sprintf("Consider reorganizing files in %s based on detected %s pattern", pattern.Description, pattern.Name),
				Priority:    ai.calculatePriority(pattern.Confidence),
				Confidence:  pattern.Confidence,
				Impact:      "medium",
			}
			suggestions = append(suggestions, suggestion)
		}
	}

	// Add suggestions for large directories
	dirSizes := ai.calculateDirectorySizes(files)
	for dir, size := range dirSizes {
		if size > 50 { // More than 50 files in one directory
			suggestion := core.OptimizationSuggestion{
				Type:        "subdivide",
				Description: fmt.Sprintf("Directory %s contains %d files and could benefit from subdivision", dir, size),
				Priority:    ai.calculatePriority(0.7),
				Confidence:  0.7,
				Impact:      "high",
			}
			suggestions = append(suggestions, suggestion)
		}
	}

	return suggestions
}

// calculateDirectorySizes counts files per directory
func (ai *AIAnalyzer) calculateDirectorySizes(files []core.FileInfo) map[string]int {
	sizes := make(map[string]int)
	for _, file := range files {
		dir := filepath.Dir(file.Path)
		sizes[dir]++
	}
	return sizes
}

// calculatePriority determines priority based on confidence
func (ai *AIAnalyzer) calculatePriority(confidence float64) int {
	switch {
	case confidence > 0.9:
		return 5 // High priority
	case confidence > 0.7:
		return 3 // Medium priority
	default:
		return 1 // Low priority
	}
}

// calculateOverallConfidence calculates overall confidence from suggestions
func (ai *AIAnalyzer) calculateOverallConfidence(suggestions []core.OptimizationSuggestion) float64 {
	if len(suggestions) == 0 {
		return 0.0
	}

	total := 0.0
	for _, suggestion := range suggestions {
		total += suggestion.Confidence
	}

	return total / float64(len(suggestions))
}

// callAI makes a request to the AI service
func (ai *AIAnalyzer) callAI(ctx context.Context, prompt string) (string, error) {
	request := AIRequest{
		Model: ai.config.Model,
		Messages: []AIMessage{
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens:   ai.config.MaxTokens,
		Temperature: 0.3, // Lower temperature for more consistent results
	}

	jsonData, err := json.Marshal(request)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", ai.endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+ai.apiKey)

	resp, err := ai.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	var response AIResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(response.Choices) == 0 {
		return "", fmt.Errorf("no choices in response")
	}

	return response.Choices[0].Message.Content, nil
}

// storeAnalysisResults stores analysis results in vector database
func (ai *AIAnalyzer) storeAnalysisResults(ctx context.Context, result *core.AnalysisResult) error {
	if ai.vectorDB == nil {
		return nil // No vector database available
	}

	// Convert analysis result to vector format
	resultJSON, err := json.Marshal(result)
	if err != nil {
		return fmt.Errorf("failed to marshal result: %w", err)
	}

	// Store in vector database for future similarity searches
	_, err = ai.vectorDB.StoreVector(ctx, "analysis_results", string(resultJSON), nil)
	return err
}

// loadLearningData loads existing learning data from file
func (ai *AIAnalyzer) loadLearningData() error {
	dataPath := "data/learning_data.json"
	if _, err := os.Stat(dataPath); os.IsNotExist(err) {
		return nil // No existing data to load
	}

	data, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read learning data: %w", err)
	}

	return json.Unmarshal(data, ai.learningData)
}

// saveLearningData saves learning data to file
func (ai *AIAnalyzer) saveLearningData() error {
	dataPath := "data/learning_data.json"

	// Ensure data directory exists
	if err := os.MkdirAll(filepath.Dir(dataPath), 0755); err != nil {
		return fmt.Errorf("failed to create data directory: %w", err)
	}

	ai.learningData.LastUpdated = time.Now()

	data, err := json.MarshalIndent(ai.learningData, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal learning data: %w", err)
	}

	return os.WriteFile(dataPath, data, 0644)
}

// initializeBuiltInPatterns initializes common file organization patterns
func (ai *AIAnalyzer) initializeBuiltInPatterns() {
	patterns := []*AnalysisPattern{
		{
			ID:          "source-code-pattern",
			Name:        "Source Code Organization",
			Description: "Groups source code files by language or module",
			FileTypes:   []string{"source_code"},
			Confidence:  0.9,
			SuccessRate: 0.85,
		},
		{
			ID:          "documentation-pattern",
			Name:        "Documentation Organization",
			Description: "Groups documentation files in dedicated directories",
			FileTypes:   []string{"documentation"},
			Confidence:  0.8,
			SuccessRate: 0.9,
		},
		{
			ID:          "config-pattern",
			Name:        "Configuration Organization",
			Description: "Groups configuration files together",
			FileTypes:   []string{"configuration"},
			Confidence:  0.7,
			SuccessRate: 0.8,
		},
	}

	for _, pattern := range patterns {
		ai.patternCache[pattern.ID] = pattern
	}
}

// RecordFeedback records user feedback for learning
func (ai *AIAnalyzer) RecordFeedback(suggestionID string, success bool, feedback string) error {
	record := core.OptimizationRecord{
		Timestamp:        time.Now(),
		OptimizationType: "ai_suggestion",
		Success:          success,
		UserFeedback:     feedback,
		AIConfidence:     0.0, // Will be filled from suggestion data
	}

	ai.learningData.OptimizationHistory = append(ai.learningData.OptimizationHistory, record)

	return ai.saveLearningData()
}

// GetHealthStatus returns the health status of the AI analyzer
func (ai *AIAnalyzer) GetHealthStatus(ctx context.Context) core.HealthStatus {
	status := core.HealthStatus{
		Status:  "healthy",
		Details: make(map[string]interface{}),
	}

	// Check API connectivity if configured
	if ai.apiKey != "" && ai.endpoint != "" {
		if err := ai.testAPIConnection(ctx); err != nil {
			status.Status = "degraded"
			status.Details["api_error"] = err.Error()
		}
	}

	// Check vector database connectivity
	if ai.vectorDB != nil {
		vectorStatus := ai.vectorDB.GetHealthStatus(ctx)
		if vectorStatus.Status != "healthy" {
			status.Status = "degraded"
			status.Details["vector_db"] = vectorStatus
		}
	}

	// Add learning data statistics
	status.Details["learning_data"] = map[string]interface{}{
		"classification_count": len(ai.learningData.FileClassifications),
		"optimization_history": len(ai.learningData.OptimizationHistory),
		"last_updated":         ai.learningData.LastUpdated,
	}

	return status
}

// testAPIConnection tests connectivity to the AI service
func (ai *AIAnalyzer) testAPIConnection(ctx context.Context) error {
	// Create a simple test request
	request := AIRequest{
		Model: ai.config.Model,
		Messages: []AIMessage{
			{
				Role:    "user",
				Content: "Test connection",
			},
		},
		MaxTokens: 10,
	}

	jsonData, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal test request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", ai.endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create test request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+ai.apiKey)

	resp, err := ai.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to connect to AI service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("AI service returned error status: %d", resp.StatusCode)
	}

	return nil
}
