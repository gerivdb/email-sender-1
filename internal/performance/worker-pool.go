package performance

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// WorkerPoolMetrics contient les métriques pour les worker pools
type WorkerPoolMetrics struct {
	activeWorkers     prometheus.Gauge
	queuedTasks       prometheus.Gauge
	processedTasks    prometheus.Counter
	taskDuration      prometheus.Histogram
	workerUtilization prometheus.Histogram
}

// WorkerPool représente un pool de workers optimisé pour la vectorisation
type WorkerPool struct {
	workers   int
	taskQueue chan Task
	wg        sync.WaitGroup
	ctx       context.Context
	cancel    context.CancelFunc
	metrics   *WorkerPoolMetrics
	mu        sync.RWMutex
	config    *PoolConfig
}

// Task représente une tâche à exécuter
type Task struct {
	ID       string
	Payload  interface{}
	Execute  func(interface{}) error
	Priority int
	Created  time.Time
}

// PoolConfig contient la configuration du pool
type PoolConfig struct {
	MinWorkers         int
	MaxWorkers         int
	QueueSize          int
	TaskTimeout        time.Duration
	ScaleUpThreshold   float64
	ScaleDownThreshold float64
	ScaleCheckInterval time.Duration
	AdaptiveScaling    bool
}

// NewWorkerPool crée un nouveau worker pool optimisé
func NewWorkerPool(config *PoolConfig) *WorkerPool {
	ctx, cancel := context.WithCancel(context.Background())

	metrics := &WorkerPoolMetrics{
		activeWorkers: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "vectorization_worker_pool_active_workers",
			Help: "Nombre de workers actifs dans le pool",
		}),
		queuedTasks: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "vectorization_worker_pool_queued_tasks",
			Help: "Nombre de tâches en attente dans la queue",
		}),
		processedTasks: promauto.NewCounter(prometheus.CounterOpts{
			Name: "vectorization_worker_pool_processed_tasks_total",
			Help: "Nombre total de tâches traitées",
		}),
		taskDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "vectorization_worker_pool_task_duration_seconds",
			Help:    "Durée d'exécution des tâches",
			Buckets: prometheus.DefBuckets,
		}),
		workerUtilization: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "vectorization_worker_pool_worker_utilization",
			Help:    "Taux d'utilisation des workers",
			Buckets: []float64{0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 1.0},
		}),
	}

	pool := &WorkerPool{
		workers:   config.MinWorkers,
		taskQueue: make(chan Task, config.QueueSize),
		ctx:       ctx,
		cancel:    cancel,
		metrics:   metrics,
		config:    config,
	}

	// Démarrer les workers initiaux
	pool.scaleWorkers(config.MinWorkers)

	// Démarrer le monitoring de scaling automatique si activé
	if config.AdaptiveScaling {
		go pool.autoScaleMonitor()
	}

	return pool
}

// Submit soumet une tâche au pool
func (wp *WorkerPool) Submit(task Task) error {
	select {
	case wp.taskQueue <- task:
		wp.metrics.queuedTasks.Inc()
		return nil
	case <-wp.ctx.Done():
		return fmt.Errorf("worker pool fermé")
	default:
		return fmt.Errorf("queue pleine, tâche rejetée")
	}
}

// scaleWorkers ajuste le nombre de workers
func (wp *WorkerPool) scaleWorkers(targetWorkers int) {
	wp.mu.Lock()
	defer wp.mu.Unlock()

	currentWorkers := wp.workers

	if targetWorkers > currentWorkers {
		// Scale up
		for i := currentWorkers; i < targetWorkers; i++ {
			wp.wg.Add(1)
			go wp.worker(i)
		}
	} else if targetWorkers < currentWorkers {
		// Scale down sera géré par les workers eux-mêmes
		// en vérifiant régulièrement s'ils doivent se terminer
	}

	wp.workers = targetWorkers
	wp.metrics.activeWorkers.Set(float64(targetWorkers))
}

// worker exécute les tâches depuis la queue
func (wp *WorkerPool) worker(workerID int) {
	defer wp.wg.Done()

	utilizationStart := time.Now()
	busyTime := time.Duration(0)

	for {
		select {
		case task := <-wp.taskQueue:
			taskStart := time.Now()
			wp.metrics.queuedTasks.Dec()

			// Exécuter la tâche avec timeout
			taskCtx, taskCancel := context.WithTimeout(wp.ctx, wp.config.TaskTimeout)
			err := wp.executeTaskWithTimeout(taskCtx, task)
			taskCancel()

			taskDuration := time.Since(taskStart)
			busyTime += taskDuration

			wp.metrics.processedTasks.Inc()
			wp.metrics.taskDuration.Observe(taskDuration.Seconds())

			if err != nil {
				fmt.Printf("Erreur lors de l'exécution de la tâche %s: %v\n", task.ID, err)
			}

		case <-wp.ctx.Done():
			// Calculer l'utilisation finale du worker
			totalTime := time.Since(utilizationStart)
			if totalTime > 0 {
				utilization := float64(busyTime) / float64(totalTime)
				wp.metrics.workerUtilization.Observe(utilization)
			}
			return

		case <-time.After(time.Second):
			// Vérifier si nous devons arrêter ce worker (scale down)
			wp.mu.RLock()
			shouldStop := workerID >= wp.workers
			wp.mu.RUnlock()

			if shouldStop {
				// Calculer l'utilisation avant de partir
				totalTime := time.Since(utilizationStart)
				if totalTime > 0 {
					utilization := float64(busyTime) / float64(totalTime)
					wp.metrics.workerUtilization.Observe(utilization)
				}
				return
			}
		}
	}
}

// executeTaskWithTimeout exécute une tâche avec gestion du timeout
func (wp *WorkerPool) executeTaskWithTimeout(ctx context.Context, task Task) error {
	done := make(chan error, 1)

	go func() {
		done <- task.Execute(task.Payload)
	}()

	select {
	case err := <-done:
		return err
	case <-ctx.Done():
		return fmt.Errorf("timeout lors de l'exécution de la tâche %s", task.ID)
	}
}

// autoScaleMonitor surveille et ajuste automatiquement le nombre de workers
func (wp *WorkerPool) autoScaleMonitor() {
	ticker := time.NewTicker(wp.config.ScaleCheckInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			wp.checkAndScale()
		case <-wp.ctx.Done():
			return
		}
	}
}

// checkAndScale vérifie les métriques et ajuste le scaling
func (wp *WorkerPool) checkAndScale() {
	wp.mu.RLock()
	currentWorkers := wp.workers
	queueLength := len(wp.taskQueue)
	queueCapacity := cap(wp.taskQueue)
	wp.mu.RUnlock()

	queueUtilization := float64(queueLength) / float64(queueCapacity)

	// Décision de scaling basée sur l'utilisation de la queue
	if queueUtilization > wp.config.ScaleUpThreshold && currentWorkers < wp.config.MaxWorkers {
		// Scale up
		newWorkers := min(currentWorkers*2, wp.config.MaxWorkers)
		fmt.Printf("Scaling up: %d -> %d workers (queue: %.2f%%)\n",
			currentWorkers, newWorkers, queueUtilization*100)
		wp.scaleWorkers(newWorkers)
	} else if queueUtilization < wp.config.ScaleDownThreshold && currentWorkers > wp.config.MinWorkers {
		// Scale down
		newWorkers := max(currentWorkers/2, wp.config.MinWorkers)
		fmt.Printf("Scaling down: %d -> %d workers (queue: %.2f%%)\n",
			currentWorkers, newWorkers, queueUtilization*100)
		wp.scaleWorkers(newWorkers)
	}
}

// GetOptimalConfig retourne une configuration optimale basée sur le système
func GetOptimalConfig() *PoolConfig {
	cpuCount := runtime.NumCPU()

	return &PoolConfig{
		MinWorkers:         max(1, cpuCount/2),
		MaxWorkers:         cpuCount * 4,
		QueueSize:          cpuCount * 100,
		TaskTimeout:        30 * time.Second,
		ScaleUpThreshold:   0.8,
		ScaleDownThreshold: 0.2,
		ScaleCheckInterval: 5 * time.Second,
		AdaptiveScaling:    true,
	}
}

// Shutdown arrête proprement le worker pool
func (wp *WorkerPool) Shutdown(timeout time.Duration) error {
	wp.cancel()

	done := make(chan struct{})
	go func() {
		wp.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timeout lors de l'arrêt du worker pool")
	}
}

// GetStats retourne les statistiques actuelles du pool
func (wp *WorkerPool) GetStats() map[string]interface{} {
	wp.mu.RLock()
	defer wp.mu.RUnlock()

	return map[string]interface{}{
		"active_workers":    wp.workers,
		"queued_tasks":      len(wp.taskQueue),
		"queue_capacity":    cap(wp.taskQueue),
		"queue_utilization": float64(len(wp.taskQueue)) / float64(cap(wp.taskQueue)),
	}
}

// Fonctions utilitaires
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
