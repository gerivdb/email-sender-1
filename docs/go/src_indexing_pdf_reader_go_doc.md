# Package indexing

## Types

### BatchIndexer

BatchIndexer handles batch indexing of documents


#### Methods

##### BatchIndexer.IndexFiles

IndexFiles indexes multiple files in batches


```go
func (bi *BatchIndexer) IndexFiles(ctx context.Context, files []string) error
```

### BatchIndexerConfig

BatchIndexerConfig holds configuration for BatchIndexer


### ChunkMetadata

ChunkMetadata contains metadata about a chunk


### Chunker

Chunker handles the splitting of documents into overlapping chunks


#### Methods

##### Chunker.Chunk

Chunk splits text into overlapping chunks with metadata


```go
func (c *Chunker) Chunk(text string) []string
```

##### Chunker.ChunkWithMetadata

ChunkWithMetadata splits text into chunks and returns metadata for each chunk


```go
func (c *Chunker) ChunkWithMetadata(text string) ([]string, []ChunkMetadata)
```

### DocumentReader

DocumentReader interface defines methods for reading different document formats
Use IndexingDocument for local use


### EmbeddingManager

EmbeddingManager manages the generation of embeddings with batching and caching


#### Methods

##### EmbeddingManager.ClearCache

ClearCache clears the embedding cache


```go
func (em *EmbeddingManager) ClearCache()
```

##### EmbeddingManager.GenerateEmbeddings

GenerateEmbeddings generates embeddings for multiple texts in batches


```go
func (em *EmbeddingManager) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error)
```

##### EmbeddingManager.GetDimensions

GetDimensions returns the embedding dimensions


```go
func (em *EmbeddingManager) GetDimensions() int
```

### EmbeddingProvider

EmbeddingProvider interface for different embedding models


### EmbeddingQualityMetrics

EmbeddingQualityMetrics tracks metrics related to embedding quality


#### Methods

##### EmbeddingQualityMetrics.RecordClusterMetrics

RecordClusterMetrics records metrics about vector clustering


```go
func (m *EmbeddingQualityMetrics) RecordClusterMetrics(density float64, outlierScore float64)
```

##### EmbeddingQualityMetrics.RecordEmbeddingQuality

RecordEmbeddingQuality records quality metrics for an embedding vector


```go
func (m *EmbeddingQualityMetrics) RecordEmbeddingQuality(vector []float32)
```

##### EmbeddingQualityMetrics.RecordLatency

RecordLatency records latency metrics


```go
func (m *EmbeddingQualityMetrics) RecordLatency(p95, p99 float64)
```

##### EmbeddingQualityMetrics.RecordQueryMetrics

RecordQueryMetrics records metrics about query performance


```go
func (m *EmbeddingQualityMetrics) RecordQueryMetrics(similarityScore, relevance, recall float64)
```

##### EmbeddingQualityMetrics.RecordSystemHealth

RecordSystemHealth records system health metrics


```go
func (m *EmbeddingQualityMetrics) RecordSystemHealth(cpuUsage, memoryUsage, diskUsage float64, goroutines int)
```

### FileType

FileType represents supported document types


### IndexingConfig

IndexingConfig holds all configuration for the indexing system


#### Methods

##### IndexingConfig.SaveConfig

SaveConfig saves the configuration to a JSON file


```go
func (c *IndexingConfig) SaveConfig(path string) error
```

##### IndexingConfig.Validate

Validate checks if the configuration is valid


```go
func (c *IndexingConfig) Validate() error
```

### MarkdownReader

MarkdownReader implements DocumentReader for markdown files


#### Methods

##### MarkdownReader.GetSupportedExtensions

GetSupportedExtensions returns supported file extensions


```go
func (r *MarkdownReader) GetSupportedExtensions() []string
```

##### MarkdownReader.Read

Read implements DocumentReader interface


```go
func (r *MarkdownReader) Read(path string) (*Document, error)
```

### Metrics

Metrics holds all Prometheus metrics for the indexing system


#### Methods

##### Metrics.RecordChunking

RecordChunking records metrics for document chunking


```go
func (m *Metrics) RecordChunking(chunks []string, duration time.Duration)
```

##### Metrics.RecordDocumentProcessing

RecordDocumentProcessing records metrics for document processing


```go
func (m *Metrics) RecordDocumentProcessing(fileType string, size int, duration time.Duration, err error)
```

##### Metrics.RecordEmbeddingGeneration

RecordEmbeddingGeneration records metrics for embedding generation


```go
func (m *Metrics) RecordEmbeddingGeneration(numEmbeddings int, cached int, duration time.Duration, err error)
```

##### Metrics.RecordIndexingTime

RecordIndexingTime records the time taken for indexing


```go
func (m *Metrics) RecordIndexingTime(duration time.Duration)
```

##### Metrics.RecordQdrantOperation

RecordQdrantOperation records metrics for Qdrant operations


```go
func (m *Metrics) RecordQdrantOperation(batchSize int, duration time.Duration, err error)
```

##### Metrics.RecordVectorQualityStats

RecordVectorQualityStats records vector quality metrics


```go
func (m *Metrics) RecordVectorQualityStats(stats VectorQualityStats)
```

### PDFReader

PDFReader implements DocumentReader for PDF files


#### Methods

##### PDFReader.GetSupportedExtensions

GetSupportedExtensions returns supported file extensions


```go
func (r *PDFReader) GetSupportedExtensions() []string
```

##### PDFReader.Read

Read implements DocumentReader interface


```go
func (r *PDFReader) Read(path string) (*Document, error)
```

### ReaderFactory

ReaderFactory creates appropriate DocumentReader based on file extension


#### Methods

##### ReaderFactory.GetReader

GetReader returns appropriate reader for given file extension


```go
func (rf *ReaderFactory) GetReader(ext string) (DocumentReader, bool)
```

##### ReaderFactory.RegisterReader

RegisterReader registers a new document reader


```go
func (rf *ReaderFactory) RegisterReader(reader DocumentReader)
```

### ResourceMonitor

ResourceMonitor monitors system resource usage


#### Methods

##### ResourceMonitor.GetStats

GetStats returns the current resource statistics


```go
func (m *ResourceMonitor) GetStats() ResourceStats
```

##### ResourceMonitor.Start

Start begins monitoring system resources


```go
func (m *ResourceMonitor) Start()
```

##### ResourceMonitor.Stop

Stop stops the resource monitoring


```go
func (m *ResourceMonitor) Stop()
```

### ResourceStats

ResourceStats holds system resource usage statistics


### TextReader

TextReader implements DocumentReader for text files


#### Methods

##### TextReader.GetSupportedExtensions

GetSupportedExtensions returns supported file extensions


```go
func (r *TextReader) GetSupportedExtensions() []string
```

##### TextReader.Read

Read implements DocumentReader interface


```go
func (r *TextReader) Read(path string) (*Document, error)
```

### VectorQualityStats

VectorQualityStats contains quality metrics for vectors


