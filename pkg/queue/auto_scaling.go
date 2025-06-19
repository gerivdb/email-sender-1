package queue

import (
	"context"
	"sync"
	"time"

	"go.uber.org/zap"
)

// AutoScaler gère le scaling dynamique des workers d'une queue
type AutoScaler struct {
	queue           *Queue
	minWorkers      int
	maxWorkers      int
	scaleUpThresh   int // jobs en attente pour scale up
	scaleDownThresh int // jobs en attente pour scale down
	logger          *zap.Logger
	interval        time.Duration
	stopCh          chan struct{}
	mu              sync.Mutex
}

// NewAutoScaler crée un autoscaler pour une queue
func NewAutoScaler(queue *Queue, minWorkers, maxWorkers, scaleUpThresh, scaleDownThresh int, interval time.Duration, logger *zap.Logger) *AutoScaler {
	return &AutoScaler{
		queue:           queue,
		minWorkers:      minWorkers,
		maxWorkers:      maxWorkers,
		scaleUpThresh:   scaleUpThresh,
		scaleDownThresh: scaleDownThresh,
		logger:          logger,
		interval:        interval,
		stopCh:          make(chan struct{}),
	}
}

// Start lance la boucle d'autoscaling
func (as *AutoScaler) Start(ctx context.Context) {
	as.logger.Info("AutoScaler started",
		zap.String("queue", as.queue.Name),
		zap.Int("min_workers", as.minWorkers),
		zap.Int("max_workers", as.maxWorkers),
		zap.Duration("interval", as.interval),
	)
	go func() {
		ticker := time.NewTicker(as.interval)
		defer ticker.Stop()
		for {
			select {
			case <-as.stopCh:
				as.logger.Info("AutoScaler stopped", zap.String("queue", as.queue.Name))
				return
			case <-ticker.C:
				as.scale()
			}
		}
	}()
}

// Stop arrête l'autoscaler
func (as *AutoScaler) Stop() {
	close(as.stopCh)
}

// scale ajuste dynamiquement le nombre de workers
func (as *AutoScaler) scale() {
	as.mu.Lock()
	defer as.mu.Unlock()

	pendingJobs := len(as.queue.Jobs) + len(as.queue.Priority)
	currentWorkers := as.queue.Workers

	if pendingJobs > as.scaleUpThresh && currentWorkers < as.maxWorkers {
		as.queue.Workers++
		as.logger.Info("AutoScaler: scaling UP",
			zap.String("queue", as.queue.Name),
			zap.Int("new_workers", as.queue.Workers),
			zap.Int("pending_jobs", pendingJobs),
		)
		go as.queue.spawnWorker(as.queue.Workers - 1)
	} else if pendingJobs < as.scaleDownThresh && currentWorkers > as.minWorkers {
		as.queue.Workers--
		as.logger.Info("AutoScaler: scaling DOWN",
			zap.String("queue", as.queue.Name),
			zap.Int("new_workers", as.queue.Workers),
			zap.Int("pending_jobs", pendingJobs),
		)
		// Note: Pour un vrai scale down, il faudrait signaler à un worker de s'arrêter proprement
	}
}

// spawnWorker démarre un nouveau worker (utilisé par l'autoscaler)
func (q *Queue) spawnWorker(workerIndex int) {
	worker := &Worker{
		ID:        q.Name + "-worker-" + time.Now().Format("150405") + "-" + string(workerIndex),
		QueueName: q.Name,
		Running:   false,
		StartTime: time.Now(),
	}
	go func() {
		q.mu.Lock()
		q.Workers++
		q.mu.Unlock()
		q.Processing[worker.ID] = nil
		// Utilise la même logique que startWorker dans async_queue_system.go
	}()
}
