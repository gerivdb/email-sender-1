// File: .github/docs/algorithms/parallel/worker_pool.go
// EMAIL_SENDER_1 Worker Pool Implementation
// Système de parallélisation avec gestion de workers pools et timeouts

package parallel

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"sync/atomic"
	"time"
)

// WorkerPoolStats contient les statistiques d'un worker pool
type WorkerPoolStats struct {
	JobsProcessed int64
	JobsSucceeded int64
	JobsFailed    int64
	AverageTime   time.Duration
	TotalTime     int64
	MaxQueueSize  int64
	CurrentLoad   float64
}

// Task représente une tâche à exécuter par le worker pool
type Task struct {
	ID       string
	Priority int
	Execute  func(ctx context.Context) error
	Timeout  time.Duration
}

// Result contient le résultat de l'exécution d'une tâche
type Result struct {
	TaskID    string
	Error     error
	Duration  time.Duration
	StartTime time.Time
	EndTime   time.Time
}

// WorkerPool implémente un pool de workers avec gestion de priorité et timeouts
type WorkerPool struct {
	maxWorkers    int
	taskQueue     chan Task
	results       chan Result
	wg            sync.WaitGroup
	ctx           context.Context
	cancel        context.CancelFunc
	stats         WorkerPoolStats
	statsMutex    sync.RWMutex
	isRunning     int32
	maxQueueSize  int
}

// NewWorkerPool crée un nouveau worker pool
func NewWorkerPool(maxWorkers int, queueSize int) *WorkerPool {
	// Si maxWorkers n'est pas spécifié, utiliser le nombre de CPU
	if maxWorkers <= 0 {
		maxWorkers = runtime.NumCPU()
	}

	// Garantir une taille de queue minimum
	if queueSize < maxWorkers*2 {
		queueSize = maxWorkers * 2
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &WorkerPool{
		maxWorkers:   maxWorkers,
		taskQueue:    make(chan Task, queueSize),
		results:      make(chan Result, queueSize),
		ctx:          ctx,
		cancel:       cancel,
		maxQueueSize: queueSize,
	}
}

// Start démarre les workers
func (wp *WorkerPool) Start() {
	if !atomic.CompareAndSwapInt32(&wp.isRunning, 0, 1) {
		// Déjà en cours d'exécution
		return
	}

	for i := 0; i < wp.maxWorkers; i++ {
		wp.wg.Add(1)
		go wp.worker(i)
	}

	// Démarrer la collecte des statistiques
	go wp.statsCollector()
}

// Stop arrête le worker pool
func (wp *WorkerPool) Stop() {
	if !atomic.CompareAndSwapInt32(&wp.isRunning, 1, 0) {
		// Déjà arrêté
		return
	}

	wp.cancel()
	wp.wg.Wait()
}

// SubmitTask ajoute une tâche au worker pool
func (wp *WorkerPool) SubmitTask(task Task) (bool, error) {
	if atomic.LoadInt32(&wp.isRunning) != 1 {
		return false, fmt.Errorf("le worker pool n'est pas démarré")
	}

	// Vérifier si la tâche a une priorité valide
	if task.Priority <= 0 {
		task.Priority = 5 // Priorité par défaut
	}

	// Ajouter la tâche avec timeout
	select {
	case wp.taskQueue <- task:
		wp.updateMaxQueueSize(len(wp.taskQueue))
		return true, nil
	case <-wp.ctx.Done():
		return false, fmt.Errorf("worker pool arrêté")
	default:
		// Queue pleine, rejet de la tâche
		return false, fmt.Errorf("queue pleine")
	}
}

// GetResults retourne un canal pour récupérer les résultats
func (wp *WorkerPool) GetResults() <-chan Result {
	return wp.results
}

// GetStats retourne les statistiques courantes
func (wp *WorkerPool) GetStats() WorkerPoolStats {
	wp.statsMutex.RLock()
	defer wp.statsMutex.RUnlock()
	
	return wp.stats
}

// worker est la goroutine exécutée par chaque worker
func (wp *WorkerPool) worker(id int) {
	defer wp.wg.Done()

	for {
		select {
		case <-wp.ctx.Done():
			return
		case task := <-wp.taskQueue:
			wp.executeTask(task)
		}
	}
}

// executeTask exécute une tâche avec timeout si spécifié
func (wp *WorkerPool) executeTask(task Task) {
	startTime := time.Now()
	
	// Créer un contexte avec timeout si spécifié
	taskCtx := wp.ctx
	var cancel context.CancelFunc
	
	if task.Timeout > 0 {
		taskCtx, cancel = context.WithTimeout(wp.ctx, task.Timeout)
		defer cancel()
	}
	
	// Exécuter la tâche
	err := task.Execute(taskCtx)
	
	// Calculer la durée
	duration := time.Since(startTime)
	
	// Collecter le résultat
	result := Result{
		TaskID:    task.ID,
		Error:     err,
		Duration:  duration,
		StartTime: startTime,
		EndTime:   time.Now(),
	}
	
	// Mettre à jour les statistiques
	wp.updateStats(err == nil, duration)
	
	// Envoyer le résultat
	select {
	case wp.results <- result:
		// Résultat envoyé
	case <-wp.ctx.Done():
		// Worker pool arrêté
	default:
		// Canal des résultats plein (ne devrait pas arriver si dimensionné correctement)
	}
}

// updateStats met à jour les statistiques atomiquement
func (wp *WorkerPool) updateStats(success bool, duration time.Duration) {
	wp.statsMutex.Lock()
	defer wp.statsMutex.Unlock()
	
	wp.stats.JobsProcessed++
	wp.stats.TotalTime += int64(duration)
	
	if success {
		wp.stats.JobsSucceeded++
	} else {
		wp.stats.JobsFailed++
	}
	
	if wp.stats.JobsProcessed > 0 {
		wp.stats.AverageTime = time.Duration(wp.stats.TotalTime / wp.stats.JobsProcessed)
	}
	
	// Mettre à jour la charge courante (0.0 - 1.0)
	wp.stats.CurrentLoad = float64(len(wp.taskQueue)) / float64(wp.maxQueueSize)
}

// updateMaxQueueSize met à jour la taille maximum de la queue
func (wp *WorkerPool) updateMaxQueueSize(currentSize int) {
	wp.statsMutex.Lock()
	defer wp.statsMutex.Unlock()
	
	if int64(currentSize) > wp.stats.MaxQueueSize {
		wp.stats.MaxQueueSize = int64(currentSize)
	}
}

// statsCollector collecte périodiquement des statistiques
func (wp *WorkerPool) statsCollector() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			wp.statsMutex.Lock()
			wp.stats.CurrentLoad = float64(len(wp.taskQueue)) / float64(wp.maxQueueSize)
			wp.statsMutex.Unlock()
		case <-wp.ctx.Done():
			return
		}
	}
}
