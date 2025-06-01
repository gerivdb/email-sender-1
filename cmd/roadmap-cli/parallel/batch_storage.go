// Package parallel provides batch storage optimization for massive data ingestion
package parallel

import (
	"fmt"
	"sync"
	"time"

	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"
)

// BatchStorageConfig contains configuration for batch storage operations
type BatchStorageConfig struct {
	BatchSize     int           // Number of items to batch before writing
	FlushInterval time.Duration // Maximum time to wait before flushing
	MaxMemory     int           // Maximum items to keep in memory before forced flush
}

// DefaultBatchStorageConfig returns sensible defaults for batch storage
func DefaultBatchStorageConfig() BatchStorageConfig {
	return BatchStorageConfig{
		BatchSize:     100, // Write in batches of 100 items
		FlushInterval: 5 * time.Second,
		MaxMemory:     500, // Force flush at 500 items
	}
}

// BatchStorage provides optimized batch storage operations
type BatchStorage struct {
	storage       *storage.JSONStorage
	config        BatchStorageConfig
	buffer        []types.RoadmapItem
	mu            sync.Mutex
	flushTimer    *time.Timer
	closed        bool
	flushChan     chan struct{}
	closeChan     chan struct{}
	storageMetrics BatchStorageMetrics
}

// BatchStorageMetrics tracks batch storage performance
type BatchStorageMetrics struct {
	TotalItems     int           `json:"total_items"`
	BatchesWritten int           `json:"batches_written"`
	FlushCount     int           `json:"flush_count"`
	MemoryFlushes  int           `json:"memory_flushes"`
	TimerFlushes   int           `json:"timer_flushes"`
	Errors         []string      `json:"errors"`
	TotalDuration  time.Duration `json:"total_duration"`
	AvgBatchTime   time.Duration `json:"avg_batch_time"`
}

// NewBatchStorage creates a new batch storage processor
func NewBatchStorage(jsonStorage *storage.JSONStorage, config BatchStorageConfig) *BatchStorage {
	bs := &BatchStorage{
		storage:   jsonStorage,
		config:    config,
		buffer:    make([]types.RoadmapItem, 0, config.BatchSize),
		flushChan: make(chan struct{}, 1),
		closeChan: make(chan struct{}),
	}

	// Start background flush goroutine
	go bs.flushWorker()

	return bs
}

// AddItem adds an item to the batch buffer
func (bs *BatchStorage) AddItem(item types.RoadmapItem) error {
	bs.mu.Lock()
	defer bs.mu.Unlock()

	if bs.closed {
		return fmt.Errorf("batch storage is closed")
	}

	bs.buffer = append(bs.buffer, item)
	bs.storageMetrics.TotalItems++

	// Check if we need to flush due to batch size or memory limit
	if len(bs.buffer) >= bs.config.BatchSize {
		bs.triggerFlush()
		return nil
	}

	if len(bs.buffer) >= bs.config.MaxMemory {
		bs.storageMetrics.MemoryFlushes++
		bs.triggerFlush()
		return nil
	}

	// Reset or start the flush timer
	bs.resetFlushTimer()

	return nil
}

// AddItems adds multiple items to the batch buffer
func (bs *BatchStorage) AddItems(items []types.RoadmapItem) error {
	bs.mu.Lock()
	defer bs.mu.Unlock()

	if bs.closed {
		return fmt.Errorf("batch storage is closed")
	}

	bs.buffer = append(bs.buffer, items...)
	bs.storageMetrics.TotalItems += len(items)

	// Check if we need to flush due to memory limit
	if len(bs.buffer) >= bs.config.MaxMemory {
		bs.storageMetrics.MemoryFlushes++
		bs.triggerFlush()
		return nil
	}

	// Check if we need to flush due to batch size
	if len(bs.buffer) >= bs.config.BatchSize {
		bs.triggerFlush()
		return nil
	}

	// Reset the flush timer
	bs.resetFlushTimer()

	return nil
}

// Flush manually flushes all buffered items to storage
func (bs *BatchStorage) Flush() error {
	bs.mu.Lock()
	defer bs.mu.Unlock()

	return bs.doFlush()
}

// Close flushes all remaining items and closes the batch storage
func (bs *BatchStorage) Close() error {
	bs.mu.Lock()
	bs.closed = true
	
	// Flush any remaining items
	err := bs.doFlush()
	
	bs.mu.Unlock()

	// Signal close to flush worker
	close(bs.closeChan)

	return err
}

// GetMetrics returns current storage metrics
func (bs *BatchStorage) GetMetrics() BatchStorageMetrics {
	bs.mu.Lock()
	defer bs.mu.Unlock()
	
	metrics := bs.storageMetrics
	if metrics.BatchesWritten > 0 {
		metrics.AvgBatchTime = metrics.TotalDuration / time.Duration(metrics.BatchesWritten)
	}
	
	return metrics
}

// triggerFlush sends a flush signal (must be called with lock held)
func (bs *BatchStorage) triggerFlush() {
	select {
	case bs.flushChan <- struct{}{}:
	default:
		// Channel is full, flush is already pending
	}
}

// resetFlushTimer resets the flush timer (must be called with lock held)
func (bs *BatchStorage) resetFlushTimer() {
	if bs.flushTimer != nil {
		bs.flushTimer.Stop()
	}
	
	bs.flushTimer = time.AfterFunc(bs.config.FlushInterval, func() {
		bs.mu.Lock()
		bs.storageMetrics.TimerFlushes++
		bs.mu.Unlock()
		bs.triggerFlush()
	})
}

// doFlush performs the actual flush operation (must be called with lock held)
func (bs *BatchStorage) doFlush() error {
	if len(bs.buffer) == 0 {
		return nil
	}

	startTime := time.Now()
	batchSize := len(bs.buffer)
	// Convert items to EnrichedItemOptions for batch storage
	var enrichedOptions []types.EnrichedItemOptions
	for _, item := range bs.buffer {
		enrichedOptions = append(enrichedOptions, types.EnrichedItemOptions{
			Title:         item.Title,
			Description:   item.Description,
			Status:        item.Status,
			Priority:      item.Priority,
			TargetDate:    item.TargetDate,
			Inputs:        item.Inputs,
			Outputs:       item.Outputs,
			Scripts:       item.Scripts,
			Prerequisites: item.Prerequisites,
			Methods:       item.Methods,
			URIs:          item.URIs,
			Tools:         item.Tools,
			Frameworks:    item.Frameworks,
			Complexity:    item.Complexity,
			Effort:        item.Effort,
			BusinessValue: item.BusinessValue,
			TechnicalDebt: item.TechnicalDebt,
			RiskLevel:     item.RiskLevel,
			Tags:          item.Tags,
		})
	}

	// Batch write to storage
	_, err := bs.storage.CreateEnrichedItems(enrichedOptions)
	if err != nil {
		errorMsg := fmt.Sprintf("failed to store batch of %d items: %v", batchSize, err)
		bs.storageMetrics.Errors = append(bs.storageMetrics.Errors, errorMsg)
		return fmt.Errorf(errorMsg)
	}

	// Update metrics
	duration := time.Since(startTime)
	bs.storageMetrics.BatchesWritten++
	bs.storageMetrics.FlushCount++
	bs.storageMetrics.TotalDuration += duration

	fmt.Printf("💾 Batch flush: %d items written in %v\n", batchSize, duration)

	// Clear buffer
	bs.buffer = bs.buffer[:0]

	// Stop the timer if it exists
	if bs.flushTimer != nil {
		bs.flushTimer.Stop()
		bs.flushTimer = nil
	}

	return nil
}

// flushWorker runs in background to handle flush operations
func (bs *BatchStorage) flushWorker() {
	for {
		select {
		case <-bs.flushChan:
			bs.mu.Lock()
			err := bs.doFlush()
			bs.mu.Unlock()
			
			if err != nil {
				fmt.Printf("⚠️  Batch flush error: %v\n", err)
			}

		case <-bs.closeChan:
			return
		}
	}
}

// ConcurrentBatchStorage provides thread-safe batch storage with multiple writers
type ConcurrentBatchStorage struct {
	batchStorage *BatchStorage
	mu           sync.Mutex
}

// NewConcurrentBatchStorage creates a new concurrent batch storage
func NewConcurrentBatchStorage(jsonStorage *storage.JSONStorage, config BatchStorageConfig) *ConcurrentBatchStorage {
	return &ConcurrentBatchStorage{
		batchStorage: NewBatchStorage(jsonStorage, config),
	}
}

// AddItem safely adds an item from multiple goroutines
func (cbs *ConcurrentBatchStorage) AddItem(item types.RoadmapItem) error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()
	return cbs.batchStorage.AddItem(item)
}

// AddItems safely adds multiple items from multiple goroutines
func (cbs *ConcurrentBatchStorage) AddItems(items []types.RoadmapItem) error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()
	return cbs.batchStorage.AddItems(items)
}

// Flush safely flushes from multiple goroutines
func (cbs *ConcurrentBatchStorage) Flush() error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()
	return cbs.batchStorage.Flush()
}

// Close safely closes from multiple goroutines
func (cbs *ConcurrentBatchStorage) Close() error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()
	return cbs.batchStorage.Close()
}

// GetMetrics safely gets metrics from multiple goroutines
func (cbs *ConcurrentBatchStorage) GetMetrics() BatchStorageMetrics {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()
	return cbs.batchStorage.GetMetrics()
}
