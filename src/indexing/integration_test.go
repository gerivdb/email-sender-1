package indexing

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/qdrant/go-client/qdrant"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/grpc"
)

// IntegrationTestSuite for testing the indexing system
type IntegrationTestSuite struct {
	suite.Suite
	client      *qdrant.Collections
	pointsAPI   *qdrant.Points
	config      *IndexingConfig
	collection  string
	testDataDir string
	metrics     *Metrics
}

func (s *IntegrationTestSuite) SetupSuite() {
	// Initialize metrics
	s.metrics = NewMetrics("test")

	// Connect to Qdrant
	addr := fmt.Sprintf("%s:%d", "localhost", 6334)
	conn, err := grpc.Dial(addr, grpc.WithInsecure())
	require.NoError(s.T(), err)

	// Create Qdrant API clients
	qc := qdrant.NewQdrantClient(conn)
	s.client = qc.GetCollectionsClient()
	s.pointsAPI = qc.GetPointsClient()

	// Create test configuration
	s.config = &IndexingConfig{}
	s.config.Qdrant.Host = "localhost"
	s.config.Qdrant.Port = 6334
	s.collection = fmt.Sprintf("test_collection_%d", time.Now().Unix())
	s.config.Qdrant.Collection = s.collection

	// Create test collection
	err = s.createTestCollection()
	require.NoError(s.T(), err)

	// Create test data directory
	s.testDataDir = s.T().TempDir()
	s.createTestFiles()
}

func (s *IntegrationTestSuite) TearDownSuite() {
	// Delete test collection
	req := &qdrant.DeleteCollection{
		CollectionName: s.collection,
	}
	_, err := s.client.Delete(context.Background(), req)
	s.NoError(err)
}

func (s *IntegrationTestSuite) createTestCollection() error {
	req := &qdrant.CreateCollection{
		CollectionName: s.collection,
		VectorsConfig: &qdrant.VectorsConfig{
			Config: &qdrant.VectorsConfig_Params{
				Params: &qdrant.VectorParams{
					Size:     384,
					Distance: qdrant.Distance_Cosine,
				},
			},
		},
	}
	_, err := s.client.Create(context.Background(), req)
	return err
}

func (s *IntegrationTestSuite) createTestFiles() {
	testFiles := []struct {
		name    string
		content string
	}{
		{"doc1.txt", "This is a test document 1"},
		{"doc2.txt", "This is a test document 2"},
		{"doc3.md", "# Test Document 3\nThis is a markdown file."},
	}

	for _, tf := range testFiles {
		path := filepath.Join(s.testDataDir, tf.name)
		err := os.WriteFile(path, []byte(tf.content), 0644)
		s.NoError(err)
	}
}

// TestBasicIndexing tests basic document indexing functionality
func (s *IntegrationTestSuite) TestBasicIndexing() {
	indexer, err := NewBatchIndexer(BatchIndexerConfig{
		BatchSize:    10,
		IndexDir:     s.testDataDir,
		Metrics:      s.metrics,
		QdrantHost:   s.config.Qdrant.Host,
		QdrantPort:   s.config.Qdrant.Port,
		Collection:   s.collection,
		ChunkSize:    100,
		ChunkOverlap: 20,
	})
	s.NoError(err)

	files, err := filepath.Glob(filepath.Join(s.testDataDir, "*.txt"))
	s.NoError(err)

	err = indexer.IndexFiles(context.Background(), files)
	s.NoError(err)

	// Verify documents were indexed
	count, err := s.getCollectionCount()
	s.NoError(err)
	s.Greater(count, int64(0))
}

// TestErrorRecovery tests system recovery from various error conditions
func (s *IntegrationTestSuite) TestErrorRecovery() {
	indexer, err := NewBatchIndexer(BatchIndexerConfig{
		BatchSize:    10,
		IndexDir:     s.testDataDir,
		QdrantHost:   s.config.Qdrant.Host,
		QdrantPort:   s.config.Qdrant.Port,
		Collection:   s.collection,
		ChunkSize:    100,
		ChunkOverlap: 20,
		Metrics:      s.metrics,
	})
	s.NoError(err)

	// Test invalid files
	s.Run("InvalidFiles", func() {
		invalidPath := filepath.Join(s.testDataDir, "nonexistent.txt")
		validPath := filepath.Join(s.testDataDir, "doc1.txt")

		files := []string{invalidPath, validPath}
		err := indexer.IndexFiles(context.Background(), files)
		s.Error(err) // Should fail for nonexistent file

		// Valid file should still be indexed
		count, err := s.getCollectionCount()
		s.NoError(err)
		s.Greater(count, int64(0))
	})
}

// TestSystemLimits tests system behavior under various load conditions
func (s *IntegrationTestSuite) TestSystemLimits() {
	indexer, err := NewBatchIndexer(BatchIndexerConfig{
		BatchSize:    100,
		IndexDir:     s.testDataDir,
		QdrantHost:   s.config.Qdrant.Host,
		QdrantPort:   s.config.Qdrant.Port,
		Collection:   s.collection,
		ChunkSize:    1000,
		ChunkOverlap: 200,
		Metrics:      s.metrics,
	})
	s.NoError(err)
	// Initialize metrics collection
	s.metrics = NewMetrics("test")

	// Test large file handling
	s.Run("LargeFile", func() {
		largePath := filepath.Join(s.testDataDir, "large.txt")
		content := make([]byte, 10*1024*1024) // 10MB file
		err := os.WriteFile(largePath, content, 0644)
		s.NoError(err)

		startTime := time.Now()
		err = indexer.IndexFiles(context.Background(), []string{largePath})
		s.NoError(err)

		processingTime := time.Since(startTime)
		s.Less(processingTime, 30*time.Second, "Large file processing should complete in reasonable time")
	})

	// Test memory management and resource limits
	s.Run("ResourceLimits", func() {
		monitor := NewResourceMonitor()
		monitor.Start()
		defer monitor.Stop()

		// Create and process large batch of small files with monitoring
		files := make([]string, 100)
		for i := 0; i < 100; i++ {
			path := filepath.Join(s.testDataDir, fmt.Sprintf("memory_%d.txt", i))
			err := os.WriteFile(path, []byte(fmt.Sprintf("Small test document %d", i)), 0644)
			s.NoError(err)
			files[i] = path
		}

		// Monitor system metrics during processing
		done := make(chan struct{})
		go func() {
			ticker := time.NewTicker(100 * time.Millisecond)
			defer ticker.Stop()

			for {
				select {
				case <-done:
					return
				case <-ticker.C:
					stats := monitor.GetStats()
					s.GreaterOrEqual(stats.MemoryUsageMB, 0.0)
					s.GreaterOrEqual(stats.GoroutineCount, 1)
					s.metrics.DocumentsProcessed.Inc()
				}
			}
		}()

		err = indexer.IndexFiles(context.Background(), files)
		s.NoError(err)
		close(done)

		finalStats := monitor.GetStats()
		s.Less(finalStats.PeakMemoryMB, int64(1000), "Memory usage should be reasonable")
	})
}

// Helper functions

func (s *IntegrationTestSuite) getCollectionCount() (int64, error) {
	req := &qdrant.CountPoints{
		CollectionName: s.collection,
	}
	resp, err := s.pointsAPI.Count(context.Background(), req)
	if err != nil {
		return 0, err
	}
	return resp.GetResult().GetCount(), nil
}

func generateNormalizedVector(dim int) []float32 {
	vector := make([]float32, dim)
	var sum float32
	for i := 0; i < dim; i++ {
		vector[i] = float32(i) / float32(dim)
		sum += vector[i] * vector[i]
	}

	// Normalize the vector
	norm := float32(1.0 / float32(sum))
	for i := 0; i < dim; i++ {
		vector[i] *= norm
	}
	return vector
}

func generateEmbeddingForText(text string) []float32 {
	// Simple mock implementation - in real code this would use an embedding model
	vector := make([]float32, 384)
	for i := 0; i < 384; i++ {
		vector[i] = float32(i) / 384.0
	}
	return vector
}

func TestIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration tests in short mode")
	}
	suite.Run(t, new(IntegrationTestSuite))
}
