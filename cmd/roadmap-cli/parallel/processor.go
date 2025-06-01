// Package parallel provides concurrent processing capabilities for massive plan ingestion
package parallel

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"time"

	"email_sender/cmd/roadmap-cli/ingestion"
	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"
)

// ProcessorConfig contains configuration for parallel processing
type ProcessorConfig struct {
	Workers   int           // Number of worker goroutines
	BatchSize int           // Size of each processing batch
	Timeout   time.Duration // Timeout for individual operations
}

// DefaultConfig returns a sensible default configuration
func DefaultConfig() ProcessorConfig {
	return ProcessorConfig{
		Workers:   runtime.NumCPU(),
		BatchSize: 5, // Process 5 files per batch
		Timeout:   30 * time.Second,
	}
}

// PlanProcessor handles parallel processing of plan files
type PlanProcessor struct {
	config  ProcessorConfig
	metrics ProcessingMetrics
	mu      sync.RWMutex
}

// ProcessingMetrics tracks processing statistics
type ProcessingMetrics struct {
	FilesProcessed int           `json:"files_processed"`
	TotalFiles     int           `json:"total_files"`
	Batches        int           `json:"batches"`
	Errors         []string      `json:"errors"`
	StartTime      time.Time     `json:"start_time"`
	Duration       time.Duration `json:"duration"`
	ItemsCreated   int           `json:"items_created"`
}

// BatchJob represents a batch of files to process
type BatchJob struct {
	ID    int      `json:"id"`
	Files []string `json:"files"`
}

// BatchResult contains the result of processing a batch
type BatchResult struct {
	BatchID      int                   `json:"batch_id"`
	ItemsCreated []types.RoadmapItem   `json:"items_created"`
	FilesOK      []string              `json:"files_ok"`
	Errors       []string              `json:"errors"`
	Duration     time.Duration         `json:"duration"`
}

// NewPlanProcessor creates a new parallel plan processor
func NewPlanProcessor(config ProcessorConfig) *PlanProcessor {
	return &PlanProcessor{
		config: config,
		metrics: ProcessingMetrics{
			StartTime: time.Now(),
		},
	}
}

// ProcessPlansParallel processes plan files in parallel using worker pools
func (p *PlanProcessor) ProcessPlansParallel(
	ctx context.Context,
	planFiles []string,
	ingester *ingestion.PlanIngester,
	roadmapStorage *storage.JSONStorage,
) ([]types.RoadmapItem, ProcessingMetrics, error) {
	p.mu.Lock()
	p.metrics.TotalFiles = len(planFiles)
	p.metrics.StartTime = time.Now()
	p.mu.Unlock()

	fmt.Printf("🚀 Starting parallel processing with %d workers, batch size %d\n", 
		p.config.Workers, p.config.BatchSize)

	// Create batches
	batches := p.createBatches(planFiles)
	p.mu.Lock()
	p.metrics.Batches = len(batches)
	p.mu.Unlock()

	fmt.Printf("📦 Created %d batches for %d files\n", len(batches), len(planFiles))

	// Create channels for work distribution
	jobChan := make(chan BatchJob, len(batches))
	resultChan := make(chan BatchResult, len(batches))
	
	// Start worker pool
	var wg sync.WaitGroup
	for i := 0; i < p.config.Workers; i++ {
		wg.Add(1)
		go p.worker(ctx, i, ingester, roadmapStorage, jobChan, resultChan, &wg)
	}

	// Send work to workers
	go func() {
		defer close(jobChan)
		for _, batch := range batches {
			select {
			case jobChan <- batch:
			case <-ctx.Done():
				return
			}
		}
	}()

	// Collect results
	go func() {
		wg.Wait()
		close(resultChan)
	}()
	// Aggregate results
	var allItems []types.RoadmapItem
	var allErrors []string

	for result := range resultChan {
		allItems = append(allItems, result.ItemsCreated...)
		allErrors = append(allErrors, result.Errors...)
		
		p.mu.Lock()
		p.metrics.FilesProcessed += len(result.FilesOK)
		p.metrics.ItemsCreated += len(result.ItemsCreated)
		p.mu.Unlock()

		fmt.Printf("✅ Batch %d completed: %d items, %d files, %d errors (took %v)\n",
			result.BatchID, len(result.ItemsCreated), len(result.FilesOK), len(result.Errors), result.Duration)
	}

	// Finalize metrics
	p.mu.Lock()
	p.metrics.Duration = time.Since(p.metrics.StartTime)
	p.metrics.Errors = allErrors
	finalMetrics := p.metrics
	p.mu.Unlock()

	fmt.Printf("🎉 Parallel processing completed: %d items from %d files in %v\n",
		len(allItems), finalMetrics.FilesProcessed, finalMetrics.Duration)

	return allItems, finalMetrics, nil
}

// worker processes batches of files
func (p *PlanProcessor) worker(
	ctx context.Context,
	workerID int,
	ingester *ingestion.PlanIngester,
	roadmapStorage *storage.JSONStorage,
	jobChan <-chan BatchJob,
	resultChan chan<- BatchResult,
	wg *sync.WaitGroup,
) {
	defer wg.Done()

	for job := range jobChan {
		select {
		case <-ctx.Done():
			return
		default:
			result := p.processBatch(ctx, workerID, job, ingester, roadmapStorage)
			resultChan <- result
		}
	}
}

// processBatch processes a single batch of files
func (p *PlanProcessor) processBatch(
	ctx context.Context,
	workerID int,
	job BatchJob,
	ingester *ingestion.PlanIngester,
	roadmapStorage *storage.JSONStorage,
) BatchResult {
	startTime := time.Now()
	result := BatchResult{
		BatchID: job.ID,
	}
	fmt.Printf("🔄 Worker %d processing batch %d (%d files)\n", workerID, job.ID, len(job.Files))

	// Process files in the batch
	items, err := ingester.IngestAndStoreEnrichedPlans(roadmapStorage, job.Files)
	if err != nil {
		result.Errors = append(result.Errors, fmt.Sprintf("batch %d error: %v", job.ID, err))
	} else {
		result.ItemsCreated = items
		result.FilesOK = job.Files
	}

	result.Duration = time.Since(startTime)
	return result
}

// createBatches splits plan files into batches for parallel processing
func (p *PlanProcessor) createBatches(planFiles []string) []BatchJob {
	var batches []BatchJob
	batchID := 0

	for i := 0; i < len(planFiles); i += p.config.BatchSize {
		end := i + p.config.BatchSize
		if end > len(planFiles) {
			end = len(planFiles)
		}

		batches = append(batches, BatchJob{
			ID:    batchID,
			Files: planFiles[i:end],
		})
		batchID++
	}

	return batches
}

// GetMetrics returns current processing metrics (thread-safe)
func (p *PlanProcessor) GetMetrics() ProcessingMetrics {
	p.mu.RLock()
	defer p.mu.RUnlock()
	return p.metrics
}
