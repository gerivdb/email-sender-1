// internal/ast/worker_pool.go
package ast

import (
	"context"
	"fmt"
	"sync"
	"time"
)

type WorkerPool struct {
	size     int
	taskCh   chan Task
	resultCh chan TaskResult
	workers  []*Worker
	wg       sync.WaitGroup
	ctx      context.Context
	cancel   context.CancelFunc
	started  bool
	mu       sync.RWMutex
}

type Task struct {
	ID       string
	Type     string
	Data     interface{}
	Priority int
	Created  time.Time
}

type TaskResult struct {
	TaskID   string
	Result   interface{}
	Error    error
	Duration time.Duration
}

type Worker struct {
	id       int
	pool     *WorkerPool
	taskCh   chan Task
	resultCh chan TaskResult
	quit     chan struct{}
}

func NewWorkerPool(size int) *WorkerPool {
	return &WorkerPool{
		size:     size,
		taskCh:   make(chan Task, size*2),
		resultCh: make(chan TaskResult, size*2),
		workers:  make([]*Worker, 0, size),
	}
}

func (wp *WorkerPool) Start(ctx context.Context) error {
	wp.mu.Lock()
	defer wp.mu.Unlock()

	if wp.started {
		return fmt.Errorf("worker pool already started")
	}

	wp.ctx, wp.cancel = context.WithCancel(ctx)

	// Créer et démarrer les workers
	for i := 0; i < wp.size; i++ {
		worker := &Worker{
			id:       i,
			pool:     wp,
			taskCh:   wp.taskCh,
			resultCh: wp.resultCh,
			quit:     make(chan struct{}),
		}

		wp.workers = append(wp.workers, worker)
		wp.wg.Add(1)
		go worker.start()
	}

	wp.started = true
	return nil
}

func (wp *WorkerPool) Stop(ctx context.Context) error {
	wp.mu.Lock()
	defer wp.mu.Unlock()

	if !wp.started {
		return nil
	}

	// Annuler le contexte pour arrêter les workers
	wp.cancel()

	// Fermer le canal des tâches
	close(wp.taskCh)

	// Attendre que tous les workers se terminent avec timeout
	done := make(chan struct{})
	go func() {
		wp.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		// Tous les workers se sont arrêtés proprement
	case <-ctx.Done():
		// Timeout - forcer l'arrêt
		for _, worker := range wp.workers {
			close(worker.quit)
		}
	case <-time.After(5 * time.Second):
		// Timeout de sécurité
		for _, worker := range wp.workers {
			close(worker.quit)
		}
	}

	wp.started = false
	return nil
}

func (wp *WorkerPool) SubmitTask(task Task) error {
	wp.mu.RLock()
	defer wp.mu.RUnlock()

	if !wp.started {
		return fmt.Errorf("worker pool not started")
	}

	select {
	case wp.taskCh <- task:
		return nil
	case <-wp.ctx.Done():
		return fmt.Errorf("worker pool is shutting down")
	default:
		return fmt.Errorf("task queue is full")
	}
}

func (wp *WorkerPool) GetResult() <-chan TaskResult {
	return wp.resultCh
}

func (wp *WorkerPool) Size() int {
	wp.mu.RLock()
	defer wp.mu.RUnlock()
	return wp.size
}

func (wp *WorkerPool) IsStarted() bool {
	wp.mu.RLock()
	defer wp.mu.RUnlock()
	return wp.started
}

func (w *Worker) start() {
	defer w.pool.wg.Done()

	for {
		select {
		case task, ok := <-w.taskCh:
			if !ok {
				// Canal fermé, arrêter le worker
				return
			}

			result := w.processTask(task)

			select {
			case w.resultCh <- result:
				// Résultat envoyé avec succès
			case <-w.pool.ctx.Done():
				// Pool en cours d'arrêt
				return
			case <-w.quit:
				// Arrêt forcé
				return
			}

		case <-w.pool.ctx.Done():
			// Pool en cours d'arrêt
			return
		case <-w.quit:
			// Arrêt forcé
			return
		}
	}
}

func (w *Worker) processTask(task Task) TaskResult {
	start := time.Now()

	result := TaskResult{
		TaskID:   task.ID,
		Duration: 0,
	}

	// Traitement de la tâche selon son type
	switch task.Type {
	case "file_analysis":
		// Placeholder pour l'analyse de fichier
		result.Result = fmt.Sprintf("Analysis completed for task %s", task.ID)
	case "dependency_mapping":
		// Placeholder pour le mapping des dépendances
		result.Result = fmt.Sprintf("Dependency mapping completed for task %s", task.ID)
	case "structural_search":
		// Placeholder pour la recherche structurelle
		result.Result = fmt.Sprintf("Structural search completed for task %s", task.ID)
	default:
		result.Error = fmt.Errorf("unknown task type: %s", task.Type)
	}

	result.Duration = time.Since(start)
	return result
}

// Utilitaires pour créer des tâches
func NewFileAnalysisTask(id, filePath string) Task {
	return Task{
		ID:       id,
		Type:     "file_analysis",
		Data:     filePath,
		Priority: 1,
		Created:  time.Now(),
	}
}

func NewDependencyMappingTask(id, filePath string) Task {
	return Task{
		ID:       id,
		Type:     "dependency_mapping",
		Data:     filePath,
		Priority: 2,
		Created:  time.Now(),
	}
}

func NewStructuralSearchTask(id string, query interface{}) Task {
	return Task{
		ID:       id,
		Type:     "structural_search",
		Data:     query,
		Priority: 3,
		Created:  time.Now(),
	}
}
