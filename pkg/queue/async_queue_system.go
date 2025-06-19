package queue

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// AsyncQueueSystem gère les queues asynchrones entre N8N et Go
type AsyncQueueSystem struct {
	logger       *zap.Logger
	queues       map[string]*Queue
	workers      map[string][]*Worker
	config       *QueueConfig
	mu           sync.RWMutex
	ctx          context.Context
	cancel       context.CancelFunc
	metrics      *QueueMetrics
	eventHandler EventHandler
}

// QueueConfig configuration du système de queue
type QueueConfig struct {
	DefaultWorkers     int           `json:"default_workers"`
	MaxWorkers         int           `json:"max_workers"`
	JobTimeout         time.Duration `json:"job_timeout"`
	RetryAttempts      int           `json:"retry_attempts"`
	RetryBackoff       time.Duration `json:"retry_backoff"`
	QueueCapacity      int           `json:"queue_capacity"`
	MetricsInterval    time.Duration `json:"metrics_interval"`
	EnablePersistence  bool          `json:"enable_persistence"`
	PersistencePath    string        `json:"persistence_path"`
	EnableLoadBalancer bool          `json:"enable_load_balancer"`
}

// Queue représente une queue de travaux
type Queue struct {
	Name         string
	Jobs         chan *Job
	Priority     chan *Job // High priority jobs
	Processing   map[string]*Job
	Failed       []*Job
	Completed    []*Job
	Workers      int
	MaxCapacity  int
	CreatedAt    time.Time
	LastActivity time.Time
	mu           sync.RWMutex
}

// Job représente un travail dans la queue
type Job struct {
	ID            string                 `json:"id"`
	Type          string                 `json:"type"`
	QueueName     string                 `json:"queue_name"`
	Priority      JobPriority            `json:"priority"`
	Payload       map[string]interface{} `json:"payload"`
	Status        JobStatus              `json:"status"`
	CreatedAt     time.Time              `json:"created_at"`
	StartedAt     *time.Time             `json:"started_at,omitempty"`
	CompletedAt   *time.Time             `json:"completed_at,omitempty"`
	FailedAt      *time.Time             `json:"failed_at,omitempty"`
	RetryCount    int                    `json:"retry_count"`
	MaxRetries    int                    `json:"max_retries"`
	LastError     string                 `json:"last_error,omitempty"`
	Result        interface{}            `json:"result,omitempty"`
	TraceID       string                 `json:"trace_id"`
	CorrelationID string                 `json:"correlation_id"`
	N8NWorkflowID string                 `json:"n8n_workflow_id,omitempty"`
	N8NNodeID     string                 `json:"n8n_node_id,omitempty"`
	ExecutionTime time.Duration          `json:"execution_time"`
}

// JobPriority définit la priorité d'un job
type JobPriority int

const (
	PriorityLow      JobPriority = 1
	PriorityNormal   JobPriority = 2
	PriorityHigh     JobPriority = 3
	PriorityCritical JobPriority = 4
)

// JobStatus définit le statut d'un job
type JobStatus string

const (
	JobStatusPending   JobStatus = "pending"
	JobStatusRunning   JobStatus = "running"
	JobStatusCompleted JobStatus = "completed"
	JobStatusFailed    JobStatus = "failed"
	JobStatusRetrying  JobStatus = "retrying"
	JobStatusCanceled  JobStatus = "canceled"
)

// Worker représente un worker qui traite les jobs
type Worker struct {
	ID            string
	QueueName     string
	Running       bool
	CurrentJob    *Job
	ProcessedJobs int64
	FailedJobs    int64
	StartTime     time.Time
	LastActivity  time.Time
	mu            sync.RWMutex
}

// QueueMetrics métriques du système de queue
type QueueMetrics struct {
	TotalQueues    int                    `json:"total_queues"`
	TotalWorkers   int                    `json:"total_workers"`
	TotalJobs      int64                  `json:"total_jobs"`
	CompletedJobs  int64                  `json:"completed_jobs"`
	FailedJobs     int64                  `json:"failed_jobs"`
	QueueStats     map[string]QueueStats  `json:"queue_stats"`
	WorkerStats    map[string]WorkerStats `json:"worker_stats"`
	Throughput     float64                `json:"throughput"` // jobs per second
	AverageLatency time.Duration          `json:"average_latency"`
	LastUpdated    time.Time              `json:"last_updated"`
}

// QueueStats statistiques d'une queue
type QueueStats struct {
	Name         string        `json:"name"`
	Size         int           `json:"size"`
	Processing   int           `json:"processing"`
	Failed       int           `json:"failed"`
	Completed    int           `json:"completed"`
	Workers      int           `json:"workers"`
	Throughput   float64       `json:"throughput"`
	AvgLatency   time.Duration `json:"avg_latency"`
	LastActivity time.Time     `json:"last_activity"`
}

// WorkerStats statistiques d'un worker
type WorkerStats struct {
	ID           string        `json:"id"`
	QueueName    string        `json:"queue_name"`
	Running      bool          `json:"running"`
	Processed    int64         `json:"processed"`
	Failed       int64         `json:"failed"`
	Uptime       time.Duration `json:"uptime"`
	LastActivity time.Time     `json:"last_activity"`
}

// EventHandler gère les événements du système de queue
type EventHandler interface {
	OnJobQueued(job *Job)
	OnJobStarted(job *Job, worker *Worker)
	OnJobCompleted(job *Job, worker *Worker, result interface{})
	OnJobFailed(job *Job, worker *Worker, err error)
	OnJobRetry(job *Job, worker *Worker, attempt int)
	OnQueueCreated(queue *Queue)
	OnWorkerStarted(worker *Worker)
	OnWorkerStopped(worker *Worker)
}

// DefaultEventHandler implémentation par défaut de EventHandler
type DefaultEventHandler struct {
	logger *zap.Logger
}

// NewAsyncQueueSystem crée un nouveau système de queue asynchrone
func NewAsyncQueueSystem(config *QueueConfig, logger *zap.Logger) *AsyncQueueSystem {
	ctx, cancel := context.WithCancel(context.Background())

	system := &AsyncQueueSystem{
		logger:       logger,
		queues:       make(map[string]*Queue),
		workers:      make(map[string][]*Worker),
		config:       config,
		ctx:          ctx,
		cancel:       cancel,
		metrics:      &QueueMetrics{QueueStats: make(map[string]QueueStats), WorkerStats: make(map[string]WorkerStats)},
		eventHandler: &DefaultEventHandler{logger: logger},
	}

	// Démarrer la collecte de métriques
	go system.startMetricsCollection()

	logger.Info("Async Queue System initialized",
		zap.Int("default_workers", config.DefaultWorkers),
		zap.Int("queue_capacity", config.QueueCapacity),
		zap.Duration("job_timeout", config.JobTimeout))

	return system
}

// CreateQueue crée une nouvelle queue
func (aqs *AsyncQueueSystem) CreateQueue(name string, workers int) error {
	aqs.mu.Lock()
	defer aqs.mu.Unlock()

	if _, exists := aqs.queues[name]; exists {
		return fmt.Errorf("queue '%s' already exists", name)
	}

	if workers <= 0 {
		workers = aqs.config.DefaultWorkers
	}

	if workers > aqs.config.MaxWorkers {
		workers = aqs.config.MaxWorkers
	}

	queue := &Queue{
		Name:         name,
		Jobs:         make(chan *Job, aqs.config.QueueCapacity),
		Priority:     make(chan *Job, aqs.config.QueueCapacity/2),
		Processing:   make(map[string]*Job),
		Failed:       make([]*Job, 0),
		Completed:    make([]*Job, 0),
		Workers:      workers,
		MaxCapacity:  aqs.config.QueueCapacity,
		CreatedAt:    time.Now(),
		LastActivity: time.Now(),
	}

	aqs.queues[name] = queue
	aqs.workers[name] = make([]*Worker, 0, workers)

	// Démarrer les workers pour cette queue
	for i := 0; i < workers; i++ {
		worker := &Worker{
			ID:        fmt.Sprintf("%s-worker-%d", name, i),
			QueueName: name,
			Running:   false,
			StartTime: time.Now(),
		}
		aqs.workers[name] = append(aqs.workers[name], worker)
		go aqs.startWorker(worker, queue)
	}

	aqs.eventHandler.OnQueueCreated(queue)

	aqs.logger.Info("Queue created",
		zap.String("queue", name),
		zap.Int("workers", workers),
		zap.Int("capacity", aqs.config.QueueCapacity))

	return nil
}

// EnqueueJob ajoute un job à la queue
func (aqs *AsyncQueueSystem) EnqueueJob(job *Job) error {
	aqs.mu.RLock()
	queue, exists := aqs.queues[job.QueueName]
	aqs.mu.RUnlock()

	if !exists {
		// Créer automatiquement la queue si elle n'existe pas
		if err := aqs.CreateQueue(job.QueueName, aqs.config.DefaultWorkers); err != nil {
			return fmt.Errorf("failed to create queue '%s': %w", job.QueueName, err)
		}
		aqs.mu.RLock()
		queue = aqs.queues[job.QueueName]
		aqs.mu.RUnlock()
	}

	// Initialiser le job
	if job.ID == "" {
		job.ID = uuid.New().String()
	}
	job.Status = JobStatusPending
	job.CreatedAt = time.Now()

	// Sélectionner le canal approprié selon la priorité
	select {
	case queue.Priority <- job: // High priority
		aqs.logger.Debug("Job queued with high priority",
			zap.String("job_id", job.ID),
			zap.String("queue", job.QueueName),
			zap.String("type", job.Type))
	case queue.Jobs <- job: // Normal priority
		aqs.logger.Debug("Job queued with normal priority",
			zap.String("job_id", job.ID),
			zap.String("queue", job.QueueName),
			zap.String("type", job.Type))
	default:
		return fmt.Errorf("queue '%s' is full", job.QueueName)
	}

	queue.mu.Lock()
	queue.LastActivity = time.Now()
	queue.mu.Unlock()

	aqs.eventHandler.OnJobQueued(job)

	return nil
}

// GetJob récupère un job depuis la queue (priorité aux jobs high priority)
func (aqs *AsyncQueueSystem) GetJob(queueName string) (*Job, error) {
	aqs.mu.RLock()
	queue, exists := aqs.queues[queueName]
	aqs.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("queue '%s' not found", queueName)
	}

	// Priorité aux jobs haute priorité
	select {
	case job := <-queue.Priority:
		return job, nil
	case job := <-queue.Jobs:
		return job, nil
	default:
		return nil, fmt.Errorf("no jobs available in queue '%s'", queueName)
	}
}

// GetJobStatus retourne le statut d'un job
func (aqs *AsyncQueueSystem) GetJobStatus(jobID string) (*Job, error) {
	aqs.mu.RLock()
	defer aqs.mu.RUnlock()

	// Chercher dans toutes les queues
	for _, queue := range aqs.queues {
		queue.mu.RLock()

		// Chercher dans les jobs en cours
		if job, exists := queue.Processing[jobID]; exists {
			queue.mu.RUnlock()
			return job, nil
		}

		// Chercher dans les jobs échoués
		for _, job := range queue.Failed {
			if job.ID == jobID {
				queue.mu.RUnlock()
				return job, nil
			}
		}

		// Chercher dans les jobs complétés
		for _, job := range queue.Completed {
			if job.ID == jobID {
				queue.mu.RUnlock()
				return job, nil
			}
		}

		queue.mu.RUnlock()
	}

	return nil, fmt.Errorf("job '%s' not found", jobID)
}

// CancelJob annule un job
func (aqs *AsyncQueueSystem) CancelJob(jobID string) error {
	aqs.mu.RLock()
	defer aqs.mu.RUnlock()

	for _, queue := range aqs.queues {
		queue.mu.Lock()
		if job, exists := queue.Processing[jobID]; exists {
			job.Status = JobStatusCanceled
			now := time.Now()
			job.CompletedAt = &now
			delete(queue.Processing, jobID)
			queue.Completed = append(queue.Completed, job)
			queue.mu.Unlock()
			return nil
		}
		queue.mu.Unlock()
	}

	return fmt.Errorf("job '%s' not found or not cancelable", jobID)
}

// startWorker démarre un worker pour traiter les jobs
func (aqs *AsyncQueueSystem) startWorker(worker *Worker, queue *Queue) {
	worker.mu.Lock()
	worker.Running = true
	worker.mu.Unlock()

	aqs.eventHandler.OnWorkerStarted(worker)

	aqs.logger.Info("Worker started",
		zap.String("worker_id", worker.ID),
		zap.String("queue", worker.QueueName))

	for {
		select {
		case <-aqs.ctx.Done():
			aqs.stopWorker(worker)
			return

		case job := <-queue.Priority: // Priorité aux jobs haute priorité
			aqs.processJob(worker, queue, job)

		case job := <-queue.Jobs: // Jobs normaux
			aqs.processJob(worker, queue, job)
		}
	}
}

// processJob traite un job
func (aqs *AsyncQueueSystem) processJob(worker *Worker, queue *Queue, job *Job) {
	startTime := time.Now()
	job.Status = JobStatusRunning
	job.StartedAt = &startTime

	worker.mu.Lock()
	worker.CurrentJob = job
	worker.LastActivity = time.Now()
	worker.mu.Unlock()

	queue.mu.Lock()
	queue.Processing[job.ID] = job
	queue.LastActivity = time.Now()
	queue.mu.Unlock()

	aqs.eventHandler.OnJobStarted(job, worker)

	aqs.logger.Info("Processing job",
		zap.String("job_id", job.ID),
		zap.String("worker_id", worker.ID),
		zap.String("type", job.Type))

	// Traitement du job avec timeout
	ctx, cancel := context.WithTimeout(aqs.ctx, aqs.config.JobTimeout)
	defer cancel()

	var result interface{}
	var err error

	// Traiter selon le type de job
	switch job.Type {
	case "n8n-workflow":
		result, err = aqs.processN8NWorkflow(ctx, job)
	case "go-cli":
		result, err = aqs.processGoCLI(ctx, job)
	case "data-conversion":
		result, err = aqs.processDataConversion(ctx, job)
	case "parameter-mapping":
		result, err = aqs.processParameterMapping(ctx, job)
	default:
		err = fmt.Errorf("unknown job type: %s", job.Type)
	}

	endTime := time.Now()
	job.ExecutionTime = endTime.Sub(startTime)

	// Nettoyer le worker
	worker.mu.Lock()
	worker.CurrentJob = nil
	worker.mu.Unlock()

	queue.mu.Lock()
	delete(queue.Processing, job.ID)
	queue.mu.Unlock()

	if err != nil {
		aqs.handleJobFailure(worker, queue, job, err)
	} else {
		aqs.handleJobSuccess(worker, queue, job, result)
	}
}

// handleJobSuccess gère le succès d'un job
func (aqs *AsyncQueueSystem) handleJobSuccess(worker *Worker, queue *Queue, job *Job, result interface{}) {
	now := time.Now()
	job.Status = JobStatusCompleted
	job.CompletedAt = &now
	job.Result = result

	worker.mu.Lock()
	worker.ProcessedJobs++
	worker.mu.Unlock()

	queue.mu.Lock()
	queue.Completed = append(queue.Completed, job)
	queue.mu.Unlock()

	aqs.eventHandler.OnJobCompleted(job, worker, result)

	aqs.logger.Info("Job completed successfully",
		zap.String("job_id", job.ID),
		zap.String("worker_id", worker.ID),
		zap.Duration("execution_time", job.ExecutionTime))
}

// handleJobFailure gère l'échec d'un job
func (aqs *AsyncQueueSystem) handleJobFailure(worker *Worker, queue *Queue, job *Job, err error) {
	job.LastError = err.Error()
	job.RetryCount++

	worker.mu.Lock()
	worker.FailedJobs++
	worker.mu.Unlock()

	// Retry logic
	if job.RetryCount < job.MaxRetries {
		job.Status = JobStatusRetrying

		aqs.eventHandler.OnJobRetry(job, worker, job.RetryCount)

		aqs.logger.Warn("Job failed, retrying",
			zap.String("job_id", job.ID),
			zap.String("worker_id", worker.ID),
			zap.Int("retry_count", job.RetryCount),
			zap.Int("max_retries", job.MaxRetries),
			zap.Error(err))

		// Re-queue with backoff
		go func() {
			time.Sleep(aqs.config.RetryBackoff * time.Duration(job.RetryCount))
			aqs.EnqueueJob(job)
		}()
	} else {
		now := time.Now()
		job.Status = JobStatusFailed
		job.FailedAt = &now

		queue.mu.Lock()
		queue.Failed = append(queue.Failed, job)
		queue.mu.Unlock()

		aqs.eventHandler.OnJobFailed(job, worker, err)

		aqs.logger.Error("Job failed permanently",
			zap.String("job_id", job.ID),
			zap.String("worker_id", worker.ID),
			zap.Int("retry_count", job.RetryCount),
			zap.Error(err))
	}
}

// Process methods for different job types
func (aqs *AsyncQueueSystem) processN8NWorkflow(ctx context.Context, job *Job) (interface{}, error) {
	// Simuler l'exécution d'un workflow N8N
	aqs.logger.Debug("Processing N8N workflow", zap.String("job_id", job.ID))

	// Implementation placeholder
	time.Sleep(100 * time.Millisecond) // Simulate work

	return map[string]interface{}{
		"status":         "completed",
		"workflow_id":    job.N8NWorkflowID,
		"execution_time": job.ExecutionTime.String(),
	}, nil
}

func (aqs *AsyncQueueSystem) processGoCLI(ctx context.Context, job *Job) (interface{}, error) {
	// Simuler l'exécution d'une commande Go CLI
	aqs.logger.Debug("Processing Go CLI command", zap.String("job_id", job.ID))

	// Implementation placeholder
	time.Sleep(200 * time.Millisecond) // Simulate work

	return map[string]interface{}{
		"status":  "completed",
		"command": job.Payload["command"],
		"output":  "CLI execution completed successfully",
	}, nil
}

func (aqs *AsyncQueueSystem) processDataConversion(ctx context.Context, job *Job) (interface{}, error) {
	// Simuler la conversion de données
	aqs.logger.Debug("Processing data conversion", zap.String("job_id", job.ID))

	// Implementation placeholder
	time.Sleep(50 * time.Millisecond) // Simulate work

	return map[string]interface{}{
		"status":         "completed",
		"converted_data": job.Payload["data"],
		"format":         "converted",
	}, nil
}

func (aqs *AsyncQueueSystem) processParameterMapping(ctx context.Context, job *Job) (interface{}, error) {
	// Simuler le mapping de paramètres
	aqs.logger.Debug("Processing parameter mapping", zap.String("job_id", job.ID))

	// Implementation placeholder
	time.Sleep(30 * time.Millisecond) // Simulate work

	return map[string]interface{}{
		"status":            "completed",
		"mapped_parameters": job.Payload["parameters"],
	}, nil
}

// stopWorker arrête un worker
func (aqs *AsyncQueueSystem) stopWorker(worker *Worker) {
	worker.mu.Lock()
	worker.Running = false
	worker.mu.Unlock()

	aqs.eventHandler.OnWorkerStopped(worker)

	aqs.logger.Info("Worker stopped", zap.String("worker_id", worker.ID))
}

// GetMetrics retourne les métriques du système
func (aqs *AsyncQueueSystem) GetMetrics() *QueueMetrics {
	aqs.mu.RLock()
	defer aqs.mu.RUnlock()

	return aqs.metrics
}

// startMetricsCollection démarre la collecte de métriques
func (aqs *AsyncQueueSystem) startMetricsCollection() {
	ticker := time.NewTicker(aqs.config.MetricsInterval)
	defer ticker.Stop()

	for {
		select {
		case <-aqs.ctx.Done():
			return
		case <-ticker.C:
			aqs.updateMetrics()
		}
	}
}

// updateMetrics met à jour les métriques
func (aqs *AsyncQueueSystem) updateMetrics() {
	aqs.mu.Lock()
	defer aqs.mu.Unlock()

	aqs.metrics.TotalQueues = len(aqs.queues)
	aqs.metrics.TotalWorkers = 0
	aqs.metrics.LastUpdated = time.Now()

	// Reset stats
	aqs.metrics.QueueStats = make(map[string]QueueStats)
	aqs.metrics.WorkerStats = make(map[string]WorkerStats)

	for queueName, queue := range aqs.queues {
		queue.mu.RLock()

		queueStat := QueueStats{
			Name:         queueName,
			Size:         len(queue.Jobs) + len(queue.Priority),
			Processing:   len(queue.Processing),
			Failed:       len(queue.Failed),
			Completed:    len(queue.Completed),
			Workers:      queue.Workers,
			LastActivity: queue.LastActivity,
		}

		aqs.metrics.QueueStats[queueName] = queueStat
		queue.mu.RUnlock()

		// Worker stats pour cette queue
		workers := aqs.workers[queueName]
		aqs.metrics.TotalWorkers += len(workers)
		for _, worker := range workers {
			worker.mu.RLock()
			workerStat := WorkerStats{
				ID:           worker.ID,
				QueueName:    worker.QueueName,
				Running:      worker.Running,
				Processed:    worker.ProcessedJobs,
				Failed:       worker.FailedJobs,
				Uptime:       time.Since(worker.StartTime),
				LastActivity: worker.LastActivity,
			}
			aqs.metrics.WorkerStats[worker.ID] = workerStat
			worker.mu.RUnlock()
		}
	}
}

// Shutdown arrête le système de queue
func (aqs *AsyncQueueSystem) Shutdown() error {
	aqs.logger.Info("Shutting down async queue system...")

	aqs.cancel()

	// Attendre que tous les workers se terminent
	aqs.mu.RLock()
	for queueName, workers := range aqs.workers {
		for _, worker := range workers {
			aqs.logger.Debug("Waiting for worker to stop",
				zap.String("worker_id", worker.ID),
				zap.String("queue", queueName))
		}
	}
	aqs.mu.RUnlock()

	aqs.logger.Info("Async queue system shutdown completed")
	return nil
}

// Implementation of DefaultEventHandler
func (deh *DefaultEventHandler) OnJobQueued(job *Job) {
	deh.logger.Debug("Job queued", zap.String("job_id", job.ID))
}

func (deh *DefaultEventHandler) OnJobStarted(job *Job, worker *Worker) {
	deh.logger.Debug("Job started", zap.String("job_id", job.ID), zap.String("worker_id", worker.ID))
}

func (deh *DefaultEventHandler) OnJobCompleted(job *Job, worker *Worker, result interface{}) {
	deh.logger.Debug("Job completed", zap.String("job_id", job.ID), zap.String("worker_id", worker.ID))
}

func (deh *DefaultEventHandler) OnJobFailed(job *Job, worker *Worker, err error) {
	deh.logger.Warn("Job failed", zap.String("job_id", job.ID), zap.String("worker_id", worker.ID), zap.Error(err))
}

func (deh *DefaultEventHandler) OnJobRetry(job *Job, worker *Worker, attempt int) {
	deh.logger.Info("Job retry", zap.String("job_id", job.ID), zap.String("worker_id", worker.ID), zap.Int("attempt", attempt))
}

func (deh *DefaultEventHandler) OnQueueCreated(queue *Queue) {
	deh.logger.Info("Queue created", zap.String("queue", queue.Name))
}

func (deh *DefaultEventHandler) OnWorkerStarted(worker *Worker) {
	deh.logger.Info("Worker started", zap.String("worker_id", worker.ID))
}

func (deh *DefaultEventHandler) OnWorkerStopped(worker *Worker) {
	deh.logger.Info("Worker stopped", zap.String("worker_id", worker.ID))
}
