package indexing

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	qdrantclient "github.com/gerivdb/email-sender-1/src/qdrant"
)

// BatchIndexer handles batch indexing of documents
type BatchIndexer struct {
	config   BatchIndexerConfig
	metrics  *Metrics
	indexDir string
	client   qdrantclient.QdrantInterface
}

// BatchIndexerConfig holds configuration for BatchIndexer
type BatchIndexerConfig struct {
	BatchSize int
	IndexDir  string
	Metrics   *Metrics
	// Client can be provided, otherwise auto client will be created
	Client qdrantclient.QdrantInterface
	// Legacy fields - will be ignored in favor of auto client if Client is not provided
	QdrantHost   string
	QdrantPort   int
	Collection   string
	ChunkSize    int
	ChunkOverlap int
}

// NewBatchIndexer creates a new BatchIndexer instance
func NewBatchIndexer(config BatchIndexerConfig) (*BatchIndexer, error) {
	if config.BatchSize <= 0 {
		config.BatchSize = 100 // default batch size
	}

	if config.IndexDir == "" {
		return nil, fmt.Errorf("index directory is required")
	}
	// Create index directory if it doesn't exist
	if err := os.MkdirAll(config.IndexDir, 0o755); err != nil {
		return nil, fmt.Errorf("failed to create index directory: %v", err)
	}

	// Use provided client or create auto client
	var client qdrantclient.QdrantInterface
	var err error

	if config.Client != nil {
		client = config.Client
	} else {
		// Use auto client factory instead of direct connection
		client, err = qdrantclient.NewAutoClient()
		if err != nil {
			return nil, fmt.Errorf("failed to create Qdrant client: %v", err)
		}
	}

	return &BatchIndexer{
		config:   config,
		metrics:  config.Metrics,
		indexDir: config.IndexDir,
		client:   client,
	}, nil
}

// IndexFiles indexes multiple files in batches
func (bi *BatchIndexer) IndexFiles(ctx context.Context, files []string) error {
	start := time.Now()
	defer func() {
		bi.recordMetrics(time.Since(start), len(files))
	}()

	// Process files in batches to prevent memory overuse
	batchSize := bi.config.BatchSize
	batches := make([][]string, 0, (len(files)+batchSize-1)/batchSize)

	for batchStart := 0; batchStart < len(files); batchStart += batchSize {
		batchEnd := batchStart + batchSize
		if batchEnd > len(files) {
			batchEnd = len(files)
		}
		batches = append(batches, files[batchStart:batchEnd])
	}

	// Process each batch concurrently
	var (
		wg     sync.WaitGroup
		mu     sync.Mutex
		errors []error
	)

	// Use semaphore to limit concurrent goroutines
	sem := make(chan struct{}, 4)

	for _, batch := range batches {
		wg.Add(1)
		go func(batchFiles []string) {
			defer wg.Done()

			// Acquire semaphore
			sem <- struct{}{}
			defer func() { <-sem }()

			for _, file := range batchFiles {
				if err := bi.indexFile(ctx, file); err != nil {
					mu.Lock()
					errors = append(errors, fmt.Errorf("error indexing %s: %v", file, err))
					mu.Unlock()
				}
			}
		}(batch)
	}

	wg.Wait()

	if len(errors) > 0 {
		return fmt.Errorf("encountered %d errors during indexing: %v", len(errors), errors[0])
	}

	return nil
}

// indexFile processes and indexes a single file
func (bi *BatchIndexer) indexFile(_ context.Context, filePath string) error {
	// Read file content
	content, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %v", err)
	}

	// Generate a unique ID for the document (hash of file path)
	h := sha256.New()
	h.Write([]byte(filePath))
	id := hex.EncodeToString(h.Sum(nil))

	// Create document
	doc := Document{
		Path:    filePath,
		Content: string(content),
		Metadata: map[string]interface{}{
			"source": filePath,
			"size":   len(content),
			"type":   filepath.Ext(filePath),
		},
		Encoding: "utf-8",
	}

	// Write the document to the index directory
	indexPath := filepath.Join(bi.indexDir, id)
	if err := os.WriteFile(indexPath, []byte(doc.Content), 0o644); err != nil {
		return fmt.Errorf("failed to write indexed file: %v", err)
	}

	// Generate a mock vector
	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = float32(i) / 384.0
	}

	// Create Qdrant point
	point := qdrantclient.Point{
		ID:      id,
		Vector:  vector,
		Payload: doc.Metadata,
	} // Upsert point to Qdrant
	if err := bi.client.UpsertPoints(bi.config.Collection, []qdrantclient.Point{point}); err != nil {
		return fmt.Errorf("failed to upsert point in Qdrant: %v", err)
	}

	return nil
}

// recordMetrics records metrics about the indexing process
func (bi *BatchIndexer) recordMetrics(duration time.Duration, numFiles int) {
	if bi.metrics != nil {
		bi.metrics.RecordIndexingTime(duration)

		// Record vector quality stats
		// TODO: These metrics will be calculated based on actual vector similarity in the future
		stats := VectorQualityStats{
			IntraClusterDistance: 0.8,
			InterClusterDistance: 2.0,
			SilhouetteScore:      0.7,
			TotalVectors:         numFiles,
		}
		bi.metrics.RecordVectorQualityStats(stats)
	}
}
