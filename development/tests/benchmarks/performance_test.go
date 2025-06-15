package benchmarks

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// === PHASE 5.2: VALIDATION DE PERFORMANCE ===

// === PHASE 5.2.1: BENCHMARKS ET MÉTRIQUES ===

// BenchmarkSuite structure pour les benchmarks
type BenchmarkSuite struct {
	vectorizationEngine VectorizationEngine
	qdrantClient        QdrantClient
	dependencyManager   DependencyManager
	ctx                 context.Context
}

// Interfaces pour les benchmarks
type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	GenerateMarkdownEmbedding(ctx context.Context, markdown string) ([]float32, error)
	ParseMarkdown(content string) (*MarkdownDocument, error)
	CacheEmbedding(key string, embedding []float32) error
	GetCachedEmbedding(key string) ([]float32, bool)
	ClearCache() error
}

type QdrantClient interface {
	UpsertPoints(ctx context.Context, collection string, points []Point) error
	SearchPoints(ctx context.Context, collection string, vector []float32, limit int) ([]SearchResult, error)
	DeletePoints(ctx context.Context, collection string, ids []string) error
	GetPoint(ctx context.Context, collection string, id string) (*Point, error)
	CountPoints(ctx context.Context, collection string) (int64, error)
}

type DependencyManager interface {
	AutoVectorize(ctx context.Context, deps []Dependency) error
	SearchSemantic(ctx context.Context, query string, limit int) ([]SemanticResult, error)
}

// Types pour les benchmarks
type Point struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

type SearchResult struct {
	ID      string                 `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
}

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

type MarkdownDocument struct {
	Title      string            `json:"title"`
	Headers    []string          `json:"headers"`
	Paragraphs []string          `json:"paragraphs"`
	Metadata   map[string]string `json:"metadata"`
}

// PerformanceMetrics métriques de performance
type PerformanceMetrics struct {
	ExecutionTime    time.Duration `json:"execution_time"`
	MemoryUsage      uint64        `json:"memory_usage"`
	AllocationsCount uint64        `json:"allocations_count"`
	GoroutinesCount  int           `json:"goroutines_count"`
	OperationsPerSec float64       `json:"operations_per_sec"`
	Latency          time.Duration `json:"latency"`
	Throughput       float64       `json:"throughput"`
	ErrorRate        float64       `json:"error_rate"`
}

// ComparisonResult résultat de comparaison Python vs Go
type ComparisonResult struct {
	PythonMetrics PerformanceMetrics `json:"python_metrics"`
	GoMetrics     PerformanceMetrics `json:"go_metrics"`
	Improvement   map[string]float64 `json:"improvement"`
	Summary       string             `json:"summary"`
}

// NewBenchmarkSuite crée une nouvelle suite de benchmarks
func NewBenchmarkSuite() *BenchmarkSuite {
	return &BenchmarkSuite{
		vectorizationEngine: NewMockVectorizationEngine(),
		qdrantClient:        NewMockQdrantClient(),
		dependencyManager:   NewMockDependencyManager(),
		ctx:                 context.Background(),
	}
}

// === MICRO-ÉTAPE 5.2.1.1: BENCHMARK TEMPS D'EXÉCUTION VECTORISATION ===

// BenchmarkVectorizationExecution benchmark du temps d'exécution de vectorisation
func BenchmarkVectorizationExecution(b *testing.B) {
	suite := NewBenchmarkSuite()

	testTexts := []string{
		"Simple dependency for testing vectorization performance",
		"Complex multi-line dependency description with various technical details and specifications that should provide a comprehensive test case for vectorization algorithms",
		"Medium length dependency description with moderate complexity for baseline testing",
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		text := testTexts[i%len(testTexts)]
		_, err := suite.vectorizationEngine.GenerateEmbedding(suite.ctx, text)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkMarkdownVectorization benchmark de vectorisation Markdown
func BenchmarkMarkdownVectorization(b *testing.B) {
	suite := NewBenchmarkSuite()

	markdownContent := `
# Test Document
This is a comprehensive test document for benchmarking markdown vectorization performance.

## Section 1: Introduction
This section contains detailed information about the testing methodology.

### Subsection 1.1
Additional content with code blocks and technical specifications.

` + "```go\nfunc main() {\n    fmt.Println(\"Hello, World!\")\n}\n```" + `

## Section 2: Performance Metrics
- Execution time measurement
- Memory usage analysis
- Throughput evaluation
`

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, err := suite.vectorizationEngine.GenerateMarkdownEmbedding(suite.ctx, markdownContent)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkDependencyAutoVectorization benchmark d'auto-vectorisation des dépendances
func BenchmarkDependencyAutoVectorization(b *testing.B) {
	suite := NewBenchmarkSuite()

	testDeps := generateTestDependencies(100)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		err := suite.dependencyManager.AutoVectorize(suite.ctx, testDeps)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// === MICRO-ÉTAPE 5.2.1.2: MESURER CONSOMMATION MÉMOIRE ===

// BenchmarkMemoryUsageVectorization benchmark de consommation mémoire pour vectorisation
func BenchmarkMemoryUsageVectorization(b *testing.B) {
	suite := NewBenchmarkSuite()

	var m1, m2 runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&m1)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		text := fmt.Sprintf("Test dependency %d with description for memory benchmarking", i)
		_, err := suite.vectorizationEngine.GenerateEmbedding(suite.ctx, text)
		if err != nil {
			b.Fatal(err)
		}
	}

	runtime.GC()
	runtime.ReadMemStats(&m2)

	b.ReportMetric(float64(m2.TotalAlloc-m1.TotalAlloc)/float64(b.N), "bytes/op")
	b.ReportMetric(float64(m2.Mallocs-m1.Mallocs)/float64(b.N), "allocs/op")
}

// BenchmarkMemoryUsageQdrant benchmark de consommation mémoire pour Qdrant
func BenchmarkMemoryUsageQdrant(b *testing.B) {
	suite := NewBenchmarkSuite()
	collection := "test_memory_collection"

	var m1, m2 runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&m1)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		points := []Point{
			{
				ID:      fmt.Sprintf("point_%d", i),
				Vector:  generateTestVector(384),
				Payload: map[string]interface{}{"index": i, "type": "test"},
			},
		}

		err := suite.qdrantClient.UpsertPoints(suite.ctx, collection, points)
		if err != nil {
			b.Fatal(err)
		}
	}

	runtime.GC()
	runtime.ReadMemStats(&m2)

	b.ReportMetric(float64(m2.TotalAlloc-m1.TotalAlloc)/float64(b.N), "bytes/op")
	b.ReportMetric(float64(m2.Mallocs-m1.Mallocs)/float64(b.N), "allocs/op")
}

// === MICRO-ÉTAPE 5.2.1.3: VALIDER LATENCE OPÉRATIONS QDRANT ===

// BenchmarkQdrantLatency benchmark de latence des opérations Qdrant
func BenchmarkQdrantLatency(b *testing.B) {
	suite := NewBenchmarkSuite()
	collection := "test_latency_collection"

	// Setup test data
	points := make([]Point, 1000)
	for i := 0; i < 1000; i++ {
		points[i] = Point{
			ID:      fmt.Sprintf("point_%d", i),
			Vector:  generateTestVector(384),
			Payload: map[string]interface{}{"index": i},
		}
	}

	// Upsert test data
	err := suite.qdrantClient.UpsertPoints(suite.ctx, collection, points)
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()

	b.Run("Search", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			vector := generateTestVector(384)
			_, err := suite.qdrantClient.SearchPoints(suite.ctx, collection, vector, 10)
			if err != nil {
				b.Fatal(err)
			}
		}
	})

	b.Run("Get", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			id := fmt.Sprintf("point_%d", i%1000)
			_, err := suite.qdrantClient.GetPoint(suite.ctx, collection, id)
			if err != nil {
				b.Fatal(err)
			}
		}
	})

	b.Run("Upsert", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			point := Point{
				ID:      fmt.Sprintf("new_point_%d", i),
				Vector:  generateTestVector(384),
				Payload: map[string]interface{}{"index": i},
			}

			err := suite.qdrantClient.UpsertPoints(suite.ctx, collection, []Point{point})
			if err != nil {
				b.Fatal(err)
			}
		}
	})
}

// === PHASE 5.2.1.2: TESTS DE CHARGE ===

// TestLoadWith100kTasks teste avec 100,000+ tâches
func TestLoadWith100kTasks(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping load test in short mode")
	}

	suite := NewBenchmarkSuite()

	t.Log("=== MICRO-ÉTAPE 5.2.1.2.1: Test avec 100,000+ tâches ===")

	const numTasks = 100000
	startTime := time.Now()

	// Generate large dataset
	dependencies := generateTestDependencies(numTasks)

	// Measure vectorization performance
	vectorizationStart := time.Now()
	err := suite.dependencyManager.AutoVectorize(suite.ctx, dependencies)
	require.NoError(t, err, "Auto-vectorization should succeed")
	vectorizationDuration := time.Since(vectorizationStart)

	// Measure memory usage
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	totalDuration := time.Since(startTime)

	// Performance assertions
	assert.Less(t, vectorizationDuration.Seconds(), 300.0, "Vectorization should complete within 5 minutes")
	assert.Less(t, memStats.Alloc, uint64(2*1024*1024*1024), "Memory usage should be less than 2GB")

	// Log performance metrics
	t.Logf("100k Tasks Performance Metrics:")
	t.Logf("- Total Duration: %v", totalDuration)
	t.Logf("- Vectorization Duration: %v", vectorizationDuration)
	t.Logf("- Tasks per second: %.2f", float64(numTasks)/vectorizationDuration.Seconds())
	t.Logf("- Memory usage: %d MB", memStats.Alloc/(1024*1024))
	t.Logf("- Number of GC cycles: %d", memStats.NumGC)
}

// TestConcurrencyMultipleGoroutines teste la concurrence avec multiples goroutines
func TestConcurrencyMultipleGoroutines(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping concurrency test in short mode")
	}

	suite := NewBenchmarkSuite()

	t.Log("=== MICRO-ÉTAPE 5.2.1.2.2: Test de concurrence (multiple goroutines) ===")

	const numGoroutines = 50
	const operationsPerGoroutine = 1000
	const totalOperations = numGoroutines * operationsPerGoroutine

	startTime := time.Now()
	var wg sync.WaitGroup
	errorsChan := make(chan error, totalOperations)
	metricsChan := make(chan time.Duration, totalOperations)

	// Start concurrent operations
	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(goroutineID int) {
			defer wg.Done()

			for j := 0; j < operationsPerGoroutine; j++ {
				opStart := time.Now()

				// Generate test dependency
				dep := Dependency{
					Name:        fmt.Sprintf("concurrent-dep-%d-%d", goroutineID, j),
					Version:     "1.0.0",
					Type:        "go",
					Description: fmt.Sprintf("Concurrent test dependency for goroutine %d operation %d", goroutineID, j),
				}

				// Perform vectorization
				err := suite.dependencyManager.AutoVectorize(suite.ctx, []Dependency{dep})
				if err != nil {
					errorsChan <- err
					return
				}

				opDuration := time.Since(opStart)
				metricsChan <- opDuration
			}
		}(i)
	}

	wg.Wait()
	close(errorsChan)
	close(metricsChan)

	totalDuration := time.Since(startTime)

	// Collect errors
	var errors []error
	for err := range errorsChan {
		errors = append(errors, err)
	}

	// Collect metrics
	var latencies []time.Duration
	for duration := range metricsChan {
		latencies = append(latencies, duration)
	}

	// Assertions
	assert.Empty(t, errors, "Concurrent operations should not produce errors")
	assert.Equal(t, totalOperations, len(latencies), "Should have metrics for all operations")

	// Calculate statistics
	var totalLatency time.Duration
	minLatency := latencies[0]
	maxLatency := latencies[0]

	for _, latency := range latencies {
		totalLatency += latency
		if latency < minLatency {
			minLatency = latency
		}
		if latency > maxLatency {
			maxLatency = latency
		}
	}

	avgLatency := totalLatency / time.Duration(len(latencies))
	operationsPerSec := float64(totalOperations) / totalDuration.Seconds()

	// Performance assertions
	assert.Less(t, avgLatency.Milliseconds(), int64(100), "Average latency should be less than 100ms")
	assert.Greater(t, operationsPerSec, 1000.0, "Should process at least 1000 operations per second")

	// Log performance metrics
	t.Logf("Concurrency Performance Metrics:")
	t.Logf("- Goroutines: %d", numGoroutines)
	t.Logf("- Operations per goroutine: %d", operationsPerGoroutine)
	t.Logf("- Total operations: %d", totalOperations)
	t.Logf("- Total duration: %v", totalDuration)
	t.Logf("- Operations per second: %.2f", operationsPerSec)
	t.Logf("- Average latency: %v", avgLatency)
	t.Logf("- Min latency: %v", minLatency)
	t.Logf("- Max latency: %v", maxLatency)
	t.Logf("- Error rate: %.2f%%", float64(len(errors))/float64(totalOperations)*100)
}

// TestRecoveryAfterFailure teste la récupération après panne
func TestRecoveryAfterFailure(t *testing.T) {
	suite := NewBenchmarkSuite()

	t.Log("=== MICRO-ÉTAPE 5.2.1.2.3: Test de récupération après panne ===")

	// Phase 1: Normal operations
	normalDeps := generateTestDependencies(100)
	err := suite.dependencyManager.AutoVectorize(suite.ctx, normalDeps)
	require.NoError(t, err, "Normal operations should succeed")

	// Phase 2: Simulate failure with invalid data
	invalidDep := Dependency{
		Name:        "", // Invalid empty name
		Version:     "invalid",
		Type:        "unknown",
		Description: "",
	}

	err = suite.dependencyManager.AutoVectorize(suite.ctx, []Dependency{invalidDep})
	assert.Error(t, err, "Should fail with invalid dependency")

	// Phase 3: Test recovery
	recoveryStart := time.Now()
	recoveryDeps := generateTestDependencies(50)
	err = suite.dependencyManager.AutoVectorize(suite.ctx, recoveryDeps)
	require.NoError(t, err, "Should recover after failure")
	recoveryDuration := time.Since(recoveryStart)

	// Phase 4: Verify system stability
	stabilityDeps := generateTestDependencies(100)
	err = suite.dependencyManager.AutoVectorize(suite.ctx, stabilityDeps)
	require.NoError(t, err, "System should be stable after recovery")

	t.Logf("Recovery Performance:")
	t.Logf("- Recovery duration: %v", recoveryDuration)
	t.Logf("- Recovery should be fast: %v", recoveryDuration < time.Second*5)

	assert.Less(t, recoveryDuration.Seconds(), 5.0, "Recovery should complete within 5 seconds")
}

// === HELPER FUNCTIONS ===

// generateTestDependencies génère des dépendances de test
func generateTestDependencies(count int) []Dependency {
	deps := make([]Dependency, count)

	types := []string{"go", "npm", "pip", "maven", "gem"}
	categories := []string{"web", "cli", "library", "framework", "tool"}

	for i := 0; i < count; i++ {
		deps[i] = Dependency{
			Name:        fmt.Sprintf("test-library-%d", i),
			Version:     fmt.Sprintf("1.%d.0", i%10),
			Type:        types[i%len(types)],
			Description: fmt.Sprintf("Test library %d for %s applications with comprehensive functionality", i, categories[i%len(categories)]),
			Metadata: map[string]string{
				"category": categories[i%len(categories)],
				"priority": fmt.Sprintf("%d", i%5),
			},
		}
	}

	return deps
}

// generateTestVector génère un vecteur de test
func generateTestVector(size int) []float32 {
	vector := make([]float32, size)
	for i := range vector {
		vector[i] = float32(i%100) / 100.0
	}
	return vector
}

// === MOCK IMPLEMENTATIONS ===

type MockVectorizationEngine struct {
	cache map[string][]float32
}

func NewMockVectorizationEngine() *MockVectorizationEngine {
	return &MockVectorizationEngine{
		cache: make(map[string][]float32),
	}
}

func (m *MockVectorizationEngine) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	// Simulate processing time
	time.Sleep(time.Microsecond * 100)

	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = float32(len(text)+i) / 1000.0
	}
	return vector, nil
}

func (m *MockVectorizationEngine) GenerateMarkdownEmbedding(ctx context.Context, markdown string) ([]float32, error) {
	// Simulate more complex processing for markdown
	time.Sleep(time.Microsecond * 200)

	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = float32(len(markdown)+i*2) / 1000.0
	}
	return vector, nil
}

func (m *MockVectorizationEngine) ParseMarkdown(content string) (*MarkdownDocument, error) {
	return &MarkdownDocument{
		Title:      "Mock Document",
		Headers:    []string{"Header 1", "Header 2"},
		Paragraphs: []string{content},
		Metadata:   map[string]string{"type": "mock"},
	}, nil
}

func (m *MockVectorizationEngine) CacheEmbedding(key string, embedding []float32) error {
	m.cache[key] = embedding
	return nil
}

func (m *MockVectorizationEngine) GetCachedEmbedding(key string) ([]float32, bool) {
	embedding, exists := m.cache[key]
	return embedding, exists
}

func (m *MockVectorizationEngine) ClearCache() error {
	m.cache = make(map[string][]float32)
	return nil
}

type MockQdrantClient struct {
	points map[string]map[string]Point
}

func NewMockQdrantClient() *MockQdrantClient {
	return &MockQdrantClient{
		points: make(map[string]map[string]Point),
	}
}

func (m *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	if m.points[collection] == nil {
		m.points[collection] = make(map[string]Point)
	}

	for _, point := range points {
		m.points[collection][point.ID] = point
	}

	// Simulate network latency
	time.Sleep(time.Microsecond * 50)
	return nil
}

func (m *MockQdrantClient) SearchPoints(ctx context.Context, collection string, vector []float32, limit int) ([]SearchResult, error) {
	// Simulate search latency
	time.Sleep(time.Microsecond * 150)

	results := make([]SearchResult, 0, limit)
	count := 0

	for id, point := range m.points[collection] {
		if count >= limit {
			break
		}

		results = append(results, SearchResult{
			ID:      id,
			Score:   0.85,
			Payload: point.Payload,
		})
		count++
	}

	return results, nil
}

func (m *MockQdrantClient) DeletePoints(ctx context.Context, collection string, ids []string) error {
	if m.points[collection] == nil {
		return nil
	}

	for _, id := range ids {
		delete(m.points[collection], id)
	}

	return nil
}

func (m *MockQdrantClient) GetPoint(ctx context.Context, collection string, id string) (*Point, error) {
	// Simulate get latency
	time.Sleep(time.Microsecond * 25)

	if m.points[collection] == nil {
		return nil, fmt.Errorf("collection not found")
	}

	point, exists := m.points[collection][id]
	if !exists {
		return nil, fmt.Errorf("point not found")
	}

	return &point, nil
}

func (m *MockQdrantClient) CountPoints(ctx context.Context, collection string) (int64, error) {
	if m.points[collection] == nil {
		return 0, nil
	}

	return int64(len(m.points[collection])), nil
}

type MockDependencyManager struct {
	vectorizationEnabled bool
}

func NewMockDependencyManager() *MockDependencyManager {
	return &MockDependencyManager{
		vectorizationEnabled: true,
	}
}

func (m *MockDependencyManager) AutoVectorize(ctx context.Context, deps []Dependency) error {
	if !m.vectorizationEnabled {
		return fmt.Errorf("vectorization not enabled")
	}

	for _, dep := range deps {
		if dep.Name == "" {
			return fmt.Errorf("invalid dependency: name cannot be empty")
		}

		// Simulate vectorization processing
		time.Sleep(time.Microsecond * 50)
	}

	return nil
}

func (m *MockDependencyManager) SearchSemantic(ctx context.Context, query string, limit int) ([]SemanticResult, error) {
	// Simulate search processing
	time.Sleep(time.Microsecond * 100)

	results := make([]SemanticResult, 0, limit)
	for i := 0; i < limit && i < 10; i++ {
		results = append(results, SemanticResult{
			ID:      fmt.Sprintf("result_%d", i),
			Score:   0.8,
			Content: fmt.Sprintf("Result %d for query: %s", i, query),
		})
	}

	return results, nil
}
