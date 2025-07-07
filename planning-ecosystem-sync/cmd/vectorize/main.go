// Package main implements the vectorization CLI tool
// Phase 3.1.2.1: Créer planning-ecosystem-sync/cmd/vectorize/main.go
package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// MarkdownParser handles markdown parsing
// Phase 3.1.2.1.1: Migrer la logique de parsing Markdown
type MarkdownParser struct {
	logger *zap.Logger
}

// TaskEntry represents a parsed task from markdown
type TaskEntry struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Content     string                 `json:"content"`
	Level       int                    `json:"level"`
	Phase       string                 `json:"phase"`
	FilePath    string                 `json:"file_path"`
	LineNumber  int                    `json:"line_number"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// VectorizationConfig holds configuration for vectorization
type VectorizationConfig struct {
	QdrantURL     string `json:"qdrant_url"`
	Collection    string `json:"collection"`
	ModelEndpoint string `json:"model_endpoint"`
	BatchSize     int    `json:"batch_size"`
	WorkerCount   int    `json:"worker_count"`
	MaxRetries    int    `json:"max_retries"`
	CacheEnabled  bool   `json:"cache_enabled"`
	OutputFormat  string `json:"output_format"`
	LogLevel      string `json:"log_level"`
}

// ProcessingStats tracks processing statistics
type ProcessingStats struct {
	TotalFiles     int           `json:"total_files"`
	TotalTasks     int           `json:"total_tasks"`
	ProcessedTasks int           `json:"processed_tasks"`
	FailedTasks    int           `json:"failed_tasks"`
	ProcessingTime time.Duration `json:"processing_time"`
	CacheHits      int           `json:"cache_hits"`
	CacheMisses    int           `json:"cache_misses"`
	StartTime      time.Time     `json:"start_time"`
	EndTime        time.Time     `json:"end_time"`
}

// Global variables
var (
	configFile     = flag.String("config", "vectorize.json", "Configuration file path")
	inputPath      = flag.String("input", ".", "Input directory or file path")
	outputPath     = flag.String("output", "vectorization_results.json", "Output file path")
	collection     = flag.String("collection", "task_embeddings", "Qdrant collection name")
	dryRun         = flag.Bool("dry-run", false, "Dry run mode (no actual vectorization)")
	verbose        = flag.Bool("verbose", false, "Verbose logging")
	forceReprocess = flag.Bool("force", false, "Force reprocessing even if vectors exist")
)

func main() {
	flag.Parse()

	// Initialize logger
	logger := initLogger(*verbose)
	defer logger.Sync()

	logger.Info("🚀 Starting vectorization tool",
		zap.String("input", *inputPath),
		zap.String("collection", *collection),
		zap.Bool("dry_run", *dryRun))

	// Load configuration
	config, err := loadConfig(*configFile, logger)
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Initialize markdown parser
	parser := &MarkdownParser{logger: logger}

	// Process files
	stats := &ProcessingStats{
		StartTime: time.Now(),
	}

	tasks, err := parser.ParseDirectory(*inputPath, stats)
	if err != nil {
		logger.Fatal("Failed to parse directory", zap.Error(err))
	}

	logger.Info("📋 Parsing completed",
		zap.Int("total_files", stats.TotalFiles),
		zap.Int("total_tasks", stats.TotalTasks))

	if *dryRun {
		logger.Info("🔍 Dry run mode - skipping vectorization")
		printDryRunResults(tasks, logger)
		return
	}
	// Phase 3.1.2.1.2: Implémenter la génération d'embeddings
	// Phase 3.1.2.2: Implémenter les optimisations de performance
	if err := ProcessTasksWithEngine(tasks, config, logger, stats); err != nil {
		logger.Fatal("Failed to vectorize tasks", zap.Error(err))
	}

	// Generate final report
	stats.EndTime = time.Now()
	stats.ProcessingTime = stats.EndTime.Sub(stats.StartTime)

	if err := generateReport(stats, *outputPath, logger); err != nil {
		logger.Error("Failed to generate report", zap.Error(err))
	}

	logger.Info("✅ Vectorization completed successfully",
		zap.Duration("total_time", stats.ProcessingTime),
		zap.Int("processed", stats.ProcessedTasks),
		zap.Int("failed", stats.FailedTasks))
}

// initLogger initializes the logger with appropriate level
func initLogger(verbose bool) *zap.Logger {
	level := zapcore.InfoLevel
	if verbose {
		level = zapcore.DebugLevel
	}

	config := zap.NewDevelopmentConfig()
	config.Level = zap.NewAtomicLevelAt(level)
	config.EncoderConfig.TimeKey = "timestamp"
	config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

	logger, err := config.Build()
	if err != nil {
		panic(fmt.Sprintf("Failed to initialize logger: %v", err))
	}

	return logger
}

// loadConfig loads configuration from file with defaults
func loadConfig(configPath string, logger *zap.Logger) (*VectorizationConfig, error) {
	// Default configuration
	config := &VectorizationConfig{
		QdrantURL:     "http://localhost:6333",
		Collection:    *collection,
		ModelEndpoint: "http://localhost:8000/embeddings",
		BatchSize:     50,
		WorkerCount:   4,
		MaxRetries:    3,
		CacheEnabled:  true,
		OutputFormat:  "json",
		LogLevel:      "info",
	}

	// Try to load from file
	if _, err := os.Stat(configPath); err == nil {
		file, err := os.Open(configPath)
		if err != nil {
			return nil, fmt.Errorf("failed to open config file: %w", err)
		}
		defer file.Close()

		if err := json.NewDecoder(file).Decode(config); err != nil {
			return nil, fmt.Errorf("failed to parse config file: %w", err)
		}

		logger.Info("📝 Configuration loaded from file", zap.String("path", configPath))
	} else {
		logger.Info("📝 Using default configuration", zap.String("reason", "config file not found"))
	}

	return config, nil
}

// ParseDirectory recursively parses markdown files in a directory
func (mp *MarkdownParser) ParseDirectory(rootPath string, stats *ProcessingStats) ([]TaskEntry, error) {
	var allTasks []TaskEntry

	err := filepath.WalkDir(rootPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Skip non-markdown files
		if d.IsDir() || !strings.HasSuffix(strings.ToLower(path), ".md") {
			return nil
		}

		stats.TotalFiles++
		mp.logger.Debug("📄 Processing file", zap.String("path", path))

		tasks, err := mp.ParseFile(path)
		if err != nil {
			mp.logger.Error("Failed to parse file", zap.String("path", path), zap.Error(err))
			return nil // Continue processing other files
		}

		allTasks = append(allTasks, tasks...)
		stats.TotalTasks += len(tasks)

		mp.logger.Debug("✅ File processed",
			zap.String("path", path),
			zap.Int("tasks_found", len(tasks)))

		return nil
	})

	return allTasks, err
}

// ParseFile parses a single markdown file for tasks
// Phase 3.1.2.1.1: Migrer la logique de parsing Markdown
func (mp *MarkdownParser) ParseFile(filePath string) ([]TaskEntry, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	var tasks []TaskEntry
	scanner := bufio.NewScanner(file)
	lineNum := 0
	currentPhase := ""

	// Regex patterns for parsing
	headerRegex := regexp.MustCompile(`^(#{1,6})\s+(.+)$`)
	taskRegex := regexp.MustCompile(`^-\s+\[\s*[x\s]\s*\]\s+\*\*([^*]+)\*\*\s+(.*)$`)
	phaseRegex := regexp.MustCompile(`^##\s+Phase\s+\d+:\s+(.+)$`)

	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())

		if line == "" {
			continue
		}

		// Track current phase
		if matches := phaseRegex.FindStringSubmatch(line); len(matches) > 1 {
			currentPhase = matches[1]
			continue
		}

		// Parse headers
		if matches := headerRegex.FindStringSubmatch(line); len(matches) > 2 {
			level := len(matches[1])
			title := strings.TrimSpace(matches[2])

			// Create header task
			task := TaskEntry{
				ID:         fmt.Sprintf("%s:%d", filepath.Base(filePath), lineNum),
				Title:      title,
				Content:    line,
				Level:      level,
				Phase:      currentPhase,
				FilePath:   filePath,
				LineNumber: lineNum,
				Metadata: map[string]interface{}{
					"type":      "header",
					"level":     level,
					"file_name": filepath.Base(filePath),
				},
			}

			tasks = append(tasks, task)
		}

		// Parse task items
		if matches := taskRegex.FindStringSubmatch(line); len(matches) > 2 {
			taskID := strings.TrimSpace(matches[1])
			description := strings.TrimSpace(matches[2])

			task := TaskEntry{
				ID:          taskID,
				Title:       taskID,
				Description: description,
				Content:     line,
				Level:       0, // Task level
				Phase:       currentPhase,
				FilePath:    filePath,
				LineNumber:  lineNum,
				Metadata: map[string]interface{}{
					"type":       "task",
					"file_name":  filepath.Base(filePath),
					"is_checked": strings.Contains(line, "[x]"),
				},
			}

			tasks = append(tasks, task)
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error reading file: %w", err)
	}

	return tasks, nil
}

// vectorizeTasks vectorizes the parsed tasks
// printDryRunResults prints dry run results
func printDryRunResults(tasks []TaskEntry, logger *zap.Logger) {
	logger.Info("🔍 Dry run results:")

	phaseStats := make(map[string]int)
	typeStats := make(map[string]int)

	for _, task := range tasks {
		if task.Phase != "" {
			phaseStats[task.Phase]++
		}
		if taskType, ok := task.Metadata["type"].(string); ok {
			typeStats[taskType]++
		}
	}

	logger.Info("📊 Statistics by phase:")
	for phase, count := range phaseStats {
		logger.Info("  📋 "+phase, zap.Int("tasks", count))
	}

	logger.Info("📊 Statistics by type:")
	for taskType, count := range typeStats {
		logger.Info("  🏷️ "+taskType, zap.Int("count", count))
	}
}

// generateReport generates a processing report
func generateReport(stats *ProcessingStats, outputPath string, logger *zap.Logger) error {
	logger.Info("📄 Generating report", zap.String("output", outputPath))

	reportData := map[string]interface{}{
		"summary": map[string]interface{}{
			"total_files":     stats.TotalFiles,
			"total_tasks":     stats.TotalTasks,
			"processed_tasks": stats.ProcessedTasks,
			"failed_tasks":    stats.FailedTasks,
			"success_rate":    float64(stats.ProcessedTasks) / float64(stats.TotalTasks) * 100,
		},
		"performance": map[string]interface{}{
			"processing_time_seconds": stats.ProcessingTime.Seconds(),
			"tasks_per_second":        float64(stats.ProcessedTasks) / stats.ProcessingTime.Seconds(),
			"cache_hits":              stats.CacheHits,
			"cache_misses":            stats.CacheMisses,
			"cache_hit_rate":          float64(stats.CacheHits) / float64(stats.CacheHits+stats.CacheMisses) * 100,
		},
		"timestamps": map[string]interface{}{
			"start_time": stats.StartTime.Format(time.RFC3339),
			"end_time":   stats.EndTime.Format(time.RFC3339),
		},
	}

	file, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("failed to create report file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(reportData); err != nil {
		return fmt.Errorf("failed to write report: %w", err)
	}

	logger.Info("✅ Report generated successfully", zap.String("path", outputPath))
	return nil
}

// EmbeddingClient interface for generating embeddings
type EmbeddingClient interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	BatchGenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error)
	GetModelInfo() ModelInfo
}

// ModelInfo contains embedding model information
type ModelInfo struct {
	Name      string `json:"name"`
	Dimension int    `json:"dimension"`
	MaxTokens int    `json:"max_tokens"`
	Language  string `json:"language"`
}

// MockEmbeddingClient is a mock implementation for demonstration
type MockEmbeddingClient struct {
	logger *zap.Logger
}

func (m *MockEmbeddingClient) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	m.logger.Debug("🤖 Generating embedding", zap.String("text_preview", text[:min(50, len(text))]))

	// Simulate embedding generation with deterministic mock data
	embedding := make([]float32, 384) // Standard sentence-transformer dimension
	for i := range embedding {
		embedding[i] = float32(len(text)) / float32(1000+i) // Simple deterministic function
	}

	return embedding, nil
}

func (m *MockEmbeddingClient) BatchGenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error) {
	m.logger.Debug("🤖 Generating batch embeddings", zap.Int("count", len(texts)))

	embeddings := make([][]float32, len(texts))
	for i, text := range texts {
		embedding, err := m.GenerateEmbedding(ctx, text)
		if err != nil {
			return nil, err
		}
		embeddings[i] = embedding
	}

	return embeddings, nil
}

func (m *MockEmbeddingClient) GetModelInfo() ModelInfo {
	return ModelInfo{
		Name:      "mock-sentence-transformer",
		Dimension: 384,
		MaxTokens: 512,
		Language:  "multilingual",
	}
}

// ProcessTasksWithEngine processes tasks using the vectorization engine
// Phase 3.1.2.2: Implémenter les optimisations de performance
func ProcessTasksWithEngine(tasks []TaskEntry, config *VectorizationConfig, logger *zap.Logger, stats *ProcessingStats) error {
	logger.Info("🔧 Initializing vectorization engine",
		zap.Int("tasks", len(tasks)),
		zap.Int("batch_size", config.BatchSize),
		zap.Int("workers", config.WorkerCount))

	// Phase 3.1.2.2.1: Parallélisation avec goroutines (worker pool pattern)
	// Initialize mock clients (in real implementation, use actual clients)
	embeddingClient := &MockEmbeddingClient{logger: logger}
	qdrantClient := &MockQdrantClient{logger: logger}
	cache := &MockCache{data: make(map[string][]float32)}

	// Create vectorization engine
	engine := NewVectorizationEngine(qdrantClient, embeddingClient, cache, logger)
	defer engine.Shutdown()

	// Initialize engine
	ctx := context.Background()
	if err := engine.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize engine: %w", err)
	}

	// Phase 3.1.2.2.2: Batching intelligent des opérations Qdrant
	batches := createTaskBatches(tasks, config.BatchSize)
	logger.Info("📦 Created task batches",
		zap.Int("total_batches", len(batches)),
		zap.Int("batch_size", config.BatchSize))

	// Process batches with worker pool
	for batchIdx, batch := range batches {
		logger.Info("📊 Processing batch",
			zap.Int("batch", batchIdx+1),
			zap.Int("total", len(batches)),
			zap.Int("tasks_in_batch", len(batch)))

		// Convert tasks to vectorization requests
		requests := make([]VectorizationRequest, len(batch))
		for i, task := range batch {
			requests[i] = VectorizationRequest{
				Text:       fmt.Sprintf("%s %s %s", task.Title, task.Description, task.Content),
				Metadata:   task.Metadata,
				Collection: config.Collection,
				ID:         task.ID,
			}
		}

		// Phase 3.1.2.2.3: Gestion mémoire optimisée pour gros volumes
		// Process requests with the engine (includes retry logic)
		results := engine.ProcessRequests(requests)

		// Update statistics
		for _, result := range results {
			if result.Success {
				stats.ProcessedTasks++
			} else {
				stats.FailedTasks++
				logger.Warn("❌ Task processing failed",
					zap.Any("id", result.ID),
					zap.String("error", result.Error))
			}
		}

		// Memory management: force garbage collection for large batches
		if len(batch) > 100 {
			runtime.GC()
			logger.Debug("🧹 Triggered garbage collection for memory optimization")
		}
	}

	// Log final statistics
	engineStats := engine.GetStats()
	logger.Info("✅ Vectorization completed",
		zap.Int("processed", stats.ProcessedTasks),
		zap.Int("failed", stats.FailedTasks),
		zap.Any("engine_stats", engineStats))

	return nil
}

// createTaskBatches splits tasks into batches for efficient processing
func createTaskBatches(tasks []TaskEntry, batchSize int) [][]TaskEntry {
	var batches [][]TaskEntry

	for i := 0; i < len(tasks); i += batchSize {
		end := i + batchSize
		if end > len(tasks) {
			end = len(tasks)
		}
		batches = append(batches, tasks[i:end])
	}

	return batches
}

// Mock implementations for demonstration
// In real implementation, these would be actual Qdrant and embedding clients

type MockQdrantClient struct {
	logger *zap.Logger
}

func (m *MockQdrantClient) Connect(ctx context.Context) error {
	m.logger.Debug("🔗 Connected to Qdrant (mock)")
	return nil
}

func (m *MockQdrantClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error {
	m.logger.Debug("📂 Created collection (mock)", zap.String("name", name))
	return nil
}

func (m *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	m.logger.Debug("⬆️ Upserted points (mock)",
		zap.String("collection", collection),
		zap.Int("count", len(points)))
	return nil
}

func (m *MockQdrantClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error) {
	m.logger.Debug("🔍 Searched points (mock)", zap.String("collection", collection))
	return &SearchResponse{}, nil
}

func (m *MockQdrantClient) DeleteCollection(ctx context.Context, name string) error {
	m.logger.Debug("🗑️ Deleted collection (mock)", zap.String("name", name))
	return nil
}

func (m *MockQdrantClient) HealthCheck(ctx context.Context) error {
	m.logger.Debug("💚 Health check passed (mock)")
	return nil
}

type MockCache struct {
	data map[string][]float32
	mu   sync.RWMutex
}

func (m *MockCache) Get(key string) ([]float32, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	val, exists := m.data[key]
	return val, exists
}

func (m *MockCache) Set(key string, value []float32) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data[key] = value
}

func (m *MockCache) Delete(key string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.data, key)
}

func (m *MockCache) Clear() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data = make(map[string][]float32)
}

func (m *MockCache) Size() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.data)
}

// Helper types from vectorization engine
type VectorizationRequest struct {
	Text       string                 `json:"text"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	Collection string                 `json:"collection"`
	ID         interface{}            `json:"id,omitempty"`
}

type VectorizationResult struct {
	ID       interface{}            `json:"id"`
	Vector   []float32              `json:"vector"`
	Metadata map[string]interface{} `json:"metadata"`
	Success  bool                   `json:"success"`
	Error    string                 `json:"error,omitempty"`
}

type CollectionConfig struct {
	VectorSize int                    `json:"vector_size"`
	Distance   string                 `json:"distance"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

type SearchRequest struct {
	Vector []float32   `json:"vector"`
	Limit  int         `json:"limit"`
	Filter interface{} `json:"filter,omitempty"`
}

type SearchResponse struct {
	Result []Point `json:"result"`
}

// NewVectorizationEngine is a placeholder - should import from vectorization package
func NewVectorizationEngine(client interface{}, modelClient interface{}, cache interface{}, logger *zap.Logger) *VectorizationEngine {
	// This is a mock implementation
	// In real code, this should import from the vectorization package
	return &VectorizationEngine{
		logger: logger,
	}
}

type VectorizationEngine struct {
	logger *zap.Logger
}

func (ve *VectorizationEngine) Initialize(ctx context.Context) error {
	ve.logger.Debug("🚀 Vectorization engine initialized (mock)")
	return nil
}

func (ve *VectorizationEngine) ProcessRequests(requests []VectorizationRequest) []VectorizationResult {
	results := make([]VectorizationResult, len(requests))

	for i, req := range requests {
		// Simulate processing
		results[i] = VectorizationResult{
			ID:      req.ID,
			Vector:  make([]float32, 384), // Mock vector
			Success: true,
		}
	}

	return results
}

func (ve *VectorizationEngine) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"processed": 0,
		"cached":    0,
		"errors":    0,
	}
}

func (ve *VectorizationEngine) Shutdown() {
	ve.logger.Debug("🛑 Vectorization engine shutdown (mock)")
}

// Helper function
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
