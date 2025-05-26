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

	"github.com/qdrant/go-client/qdrant"
	"google.golang.org/grpc"
)

// Document represents a document to be indexed
type Document struct {
	ID       string
	Content  string
	Metadata map[string]interface{}
}

// BatchIndexer handles batch indexing of documents
type BatchIndexer struct {
	config   BatchIndexerConfig
	metrics  *Metrics
	indexDir string
	client   *qdrant.Points
}

// BatchIndexerConfig holds configuration for BatchIndexer
type BatchIndexerConfig struct {
	BatchSize    int
	IndexDir     string
	Metrics      *Metrics
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
	if err := os.MkdirAll(config.IndexDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create index directory: %v", err)
	}

	// Connect to Qdrant
	addr := fmt.Sprintf("%s:%d", config.QdrantHost, config.QdrantPort)
	conn, err := grpc.Dial(addr, grpc.WithInsecure())
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Qdrant: %v", err)
	}

	// Create Qdrant API client
	qc := qdrant.NewQdrantClient(conn)
	pointsAPI := qc.GetPointsClient()

	return &BatchIndexer{
		config:   config,
		metrics:  config.Metrics,
		indexDir: config.IndexDir,
		client:   pointsAPI,
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
func (bi *BatchIndexer) indexFile(ctx context.Context, filePath string) error {
	// Read file content
	content, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %v", err)
	}

	// Generate file ID
	h := sha256.New()
	h.Write(content)
	id := hex.EncodeToString(h.Sum(nil))

	// Create document
	doc := Document{
		ID:      id,
		Content: string(content),
		Metadata: map[string]interface{}{
			"source": filePath,
			"size":   len(content),
			"type":   filepath.Ext(filePath),
		},
	}

	// Write the document to the index directory
	indexPath := filepath.Join(bi.indexDir, doc.ID)
	if err := os.WriteFile(indexPath, []byte(doc.Content), 0644); err != nil {
		return fmt.Errorf("failed to write indexed file: %v", err)
	}

	// Generate vector embedding (mock for now)
	vector := &qdrant.Vector{
		Data: make([]float32, 384), // Mock 384-dim vector
	}
	for i := range vector.Data {
		vector.Data[i] = float32(i) / 384.0
	}

	// Create Qdrant point
	point := &qdrant.Point{
		Id: &qdrant.PointId{
			PointIdOptions: &qdrant.PointId_String_{
				String_: doc.ID,
			},
		},
		Vectors: &qdrant.Vectors{
			VectorsOptions: &qdrant.Vectors_Vector{
				Vector: vector,
			},
		},
		Payload: make(map[string]*qdrant.Value),
	}

	// Convert metadata to Qdrant values
	for k, v := range doc.Metadata {
		switch val := v.(type) {
		case string:
			point.Payload[k] = &qdrant.Value{
				Kind: &qdrant.Value_StringValue{
					StringValue: val,
				},
			}
		case int:
			point.Payload[k] = &qdrant.Value{
				Kind: &qdrant.Value_IntegerValue{
					IntegerValue: int64(val),
				},
			}
		}
	}

	// Add content to payload
	point.Payload["content"] = &qdrant.Value{
		Kind: &qdrant.Value_StringValue{
			StringValue: doc.Content,
		},
	}

	// Upsert point to Qdrant
	upsertReq := &qdrant.UpsertPoints{
		CollectionName: bi.config.Collection,
		Points:         []*qdrant.Point{point},
	}

	if _, err := bi.client.Upsert(ctx, upsertReq); err != nil {
		return fmt.Errorf("failed to index in Qdrant: %v", err)
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
