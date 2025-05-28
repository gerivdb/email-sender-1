// File: .github/docs/algorithms/parallel/pipeline_orchestrator.go
// EMAIL_SENDER_1 Pipeline Orchestration Implementation
// Système d'orchestration avancé avec worker pools et gestion du parallélisme

package parallel

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

// PipelineStage représente une étape du pipeline
type PipelineStage struct {
	ID          string
	Name        string
	Description string
	Priority    int
	DependsOn   []string
	Execute     func(ctx context.Context, input interface{}) (interface{}, error)
	Timeout     time.Duration
}

// PipelineResult contient le résultat d'une étape du pipeline
type PipelineResult struct {
	StageID   string
	Status    string
	Output    interface{}
	Error     error
	StartTime time.Time
	EndTime   time.Time
	Duration  time.Duration
	Metadata  map[string]interface{}
}

// PipelineStageStatus représente le statut d'une étape du pipeline
type PipelineStageStatus struct {
	StageID     string
	Status      string // "pending", "running", "completed", "failed", "skipped"
	StartTime   time.Time
	EndTime     time.Time
	Duration    time.Duration
	RetryCount  int
	Error       error
	DependsOn   []string
	Priority    int
	IsBlocking  bool
	IsCompleted bool
}

// PipelineOrchestrator gère l'exécution du pipeline de traitement EMAIL_SENDER_1
type PipelineOrchestrator struct {
	stages               map[string]PipelineStage
	stageStatus          map[string]*PipelineStageStatus
	stageResults         map[string]*PipelineResult
	executionOrder       []string
	workerPool           *WorkerPool
	ctx                  context.Context
	cancel               context.CancelFunc
	mu                   sync.RWMutex
	wg                   sync.WaitGroup
	completedStages      int32
	totalStages          int32
	stageCompletedSignal chan string
	maxConcurrentStages  int
	recoveryStrategy     RecoveryStrategy
	retryLimit           int
	retryDelayMs         int
	isRunning            int32
	startTime            time.Time
	endTime              time.Time
	stageTimeout         time.Duration
	pipelineTimeout      time.Duration
}

// RecoveryStrategy définit la stratégie de récupération en cas d'échec d'une étape
type RecoveryStrategy string

const (
	// FailFast arrête le pipeline à la première erreur
	FailFast RecoveryStrategy = "fail-fast"
	// SkipFailed ignore les étapes en échec et continue
	SkipFailed RecoveryStrategy = "skip-failed"
	// RetryOnce réessaye une fois les étapes en échec avant de continuer
	RetryOnce RecoveryStrategy = "retry-once"
	// RetryWithBackoff réessaye les étapes en échec avec un délai exponentiel
	RetryWithBackoff RecoveryStrategy = "retry-with-backoff"
)

// PipelineOrchestratorConfig contient la configuration pour le PipelineOrchestrator
type PipelineOrchestratorConfig struct {
	MaxWorkers          int
	MaxQueueSize        int
	MaxConcurrentStages int
	StageTimeout        time.Duration
	PipelineTimeout     time.Duration
	RecoveryStrategy    RecoveryStrategy
	RetryLimit          int
	RetryDelayMs        int
}

// DefaultPipelineConfig retourne une configuration par défaut
func DefaultPipelineConfig() PipelineOrchestratorConfig {
	return PipelineOrchestratorConfig{
		MaxWorkers:          8,
		MaxQueueSize:        100,
		MaxConcurrentStages: 4,
		StageTimeout:        2 * time.Minute,
		PipelineTimeout:     30 * time.Minute,
		RecoveryStrategy:    RetryOnce,
		RetryLimit:          3,
		RetryDelayMs:        1000,
	}
}

// NewPipelineOrchestrator crée une nouvelle instance de PipelineOrchestrator
func NewPipelineOrchestrator(config PipelineOrchestratorConfig) *PipelineOrchestrator {
	ctx, cancel := context.WithTimeout(context.Background(), config.PipelineTimeout)

	return &PipelineOrchestrator{
		stages:               make(map[string]PipelineStage),
		stageStatus:          make(map[string]*PipelineStageStatus),
		stageResults:         make(map[string]*PipelineResult),
		workerPool:           NewWorkerPool(config.MaxWorkers, config.MaxQueueSize),
		ctx:                  ctx,
		cancel:               cancel,
		stageCompletedSignal: make(chan string, config.MaxWorkers),
		maxConcurrentStages:  config.MaxConcurrentStages,
		recoveryStrategy:     config.RecoveryStrategy,
		retryLimit:           config.RetryLimit,
		retryDelayMs:         config.RetryDelayMs,
		stageTimeout:         config.StageTimeout,
		pipelineTimeout:      config.PipelineTimeout,
	}
}

// RegisterStage ajoute une étape au pipeline
func (po *PipelineOrchestrator) RegisterStage(stage PipelineStage) error {
	po.mu.Lock()
	defer po.mu.Unlock()

	if _, exists := po.stages[stage.ID]; exists {
		return fmt.Errorf("stage with ID %s already registered", stage.ID)
	}

	// Vérifier que les dépendances existent
	for _, depID := range stage.DependsOn {
		if _, exists := po.stages[depID]; !exists {
			return fmt.Errorf("dependency %s not found for stage %s", depID, stage.ID)
		}
	}

	po.stages[stage.ID] = stage
	po.stageStatus[stage.ID] = &PipelineStageStatus{
		StageID:     stage.ID,
		Status:      "pending",
		DependsOn:   stage.DependsOn,
		Priority:    stage.Priority,
		IsBlocking:  false,
		IsCompleted: false,
	}

	atomic.AddInt32(&po.totalStages, 1)
	return nil
}

// Start démarre le pipeline orchestrator avec les données d'entrée
func (po *PipelineOrchestrator) Start(initialInput interface{}) error {
	if !atomic.CompareAndSwapInt32(&po.isRunning, 0, 1) {
		return fmt.Errorf("pipeline is already running")
	}

	po.startTime = time.Now()

	// Calculer l'ordre d'exécution
	if err := po.calculateExecutionOrder(); err != nil {
		return err
	}

	// Démarrer le worker pool
	po.workerPool.Start()

	// Allocate initial input to the first stage
	if len(po.executionOrder) == 0 {
		return fmt.Errorf("no stages to execute")
	}
	
	// Surveiller la progression et le timeout
	go po.monitorPipeline()

	// Démarrer le pipeline
	po.wg.Add(1)
	go func() {
		defer po.wg.Done()
		po.executeStages(initialInput)
	}()

	return nil
}

// Wait attend que l'exécution du pipeline soit terminée
func (po *PipelineOrchestrator) Wait() {
	po.wg.Wait()
}

// Stop arrête le pipeline
func (po *PipelineOrchestrator) Stop() {
	if atomic.CompareAndSwapInt32(&po.isRunning, 1, 0) {
		po.cancel()
		po.workerPool.Stop()
	}
	
	po.endTime = time.Now()
}

// GetStageResult récupère le résultat d'une étape
func (po *PipelineOrchestrator) GetStageResult(stageID string) (*PipelineResult, error) {
	po.mu.RLock()
	defer po.mu.RUnlock()

	result, exists := po.stageResults[stageID]
	if !exists {
		return nil, fmt.Errorf("no result for stage %s", stageID)
	}

	return result, nil
}

// GetAllResults récupère tous les résultats des étapes
func (po *PipelineOrchestrator) GetAllResults() map[string]*PipelineResult {
	po.mu.RLock()
	defer po.mu.RUnlock()

	// Copier les résultats pour éviter les race conditions
	results := make(map[string]*PipelineResult, len(po.stageResults))
	for id, result := range po.stageResults {
		results[id] = result
	}

	return results
}

// GetPipelineProgress retourne la progression du pipeline (0-100%)
func (po *PipelineOrchestrator) GetPipelineProgress() float64 {
	completed := atomic.LoadInt32(&po.completedStages)
	total := atomic.LoadInt32(&po.totalStages)
	
	if total == 0 {
		return 0
	}
	
	return float64(completed) * 100.0 / float64(total)
}

// GetPipelineStats retourne les statistiques du pipeline
func (po *PipelineOrchestrator) GetPipelineStats() map[string]interface{} {
	po.mu.RLock()
	defer po.mu.RUnlock()

	// Calculer les statuts
	statuses := make(map[string]int)
	for _, status := range po.stageStatus {
		statuses[status.Status]++
	}

	now := time.Now()
	var duration time.Duration
	if po.endTime.IsZero() {
		duration = now.Sub(po.startTime)
	} else {
		duration = po.endTime.Sub(po.startTime)
	}

	workerPoolStats := po.workerPool.GetStats()
	
	return map[string]interface{}{
		"totalStages":          po.totalStages,
		"completedStages":      po.completedStages,
		"progress":             po.GetPipelineProgress(),
		"duration":             duration,
		"status":               po.getPipelineStatus(),
		"stageStatuses":        statuses,
		"workerPoolStats":      workerPoolStats,
		"queuedTasks":          workerPoolStats.MaxQueueSize - workerPoolStats.JobsProcessed,
		"averageStageTime":     workerPoolStats.AverageTime,
		"currentLoad":          workerPoolStats.CurrentLoad,
	}
}

// getPipelineStatus retourne le statut global du pipeline
func (po *PipelineOrchestrator) getPipelineStatus() string {
	if atomic.LoadInt32(&po.isRunning) == 0 {
		if po.ctx.Err() == context.DeadlineExceeded {
			return "timeout"
		}
		if po.ctx.Err() == context.Canceled {
			return "canceled"
		}
		
		// Vérifier si certaines étapes ont échoué
		for _, status := range po.stageStatus {
			if status.Status == "failed" {
				return "failed"
			}
		}
		
		// Si toutes les étapes sont complétées
		if atomic.LoadInt32(&po.completedStages) == po.totalStages {
			return "completed"
		}
		
		return "stopped"
	}
	
	return "running"
}

// calculateExecutionOrder calcule l'ordre d'exécution basé sur les dépendances et priorités
func (po *PipelineOrchestrator) calculateExecutionOrder() error {
	po.mu.Lock()
	defer po.mu.Unlock()

	// Copy stages to map
	stages := make(map[string]PipelineStage, len(po.stages))
	for id, stage := range po.stages {
		stages[id] = stage
	}

	// Trier par priorité et dépendances
	order, err := po.toposort(stages)
	if err != nil {
		return fmt.Errorf("failed to calculate execution order: %w", err)
	}

	po.executionOrder = order
	return nil
}

// toposort implements topological sorting with priority
func (po *PipelineOrchestrator) toposort(stages map[string]PipelineStage) ([]string, error) {
	var result []string
	visited := make(map[string]bool)
	temp := make(map[string]bool)

	var visit func(id string) error
	visit = func(id string) error {
		if temp[id] {
			return fmt.Errorf("pipeline contains circular dependency involving stage %s", id)
		}
		if visited[id] {
			return nil
		}
		
		temp[id] = true
		
		// Visit dependencies
		for _, depID := range stages[id].DependsOn {
			if err := visit(depID); err != nil {
				return err
			}
		}
		
		temp[id] = false
		visited[id] = true
		result = append(result, id)
		return nil
	}

	// Visit all stages
	for id := range stages {
		if !visited[id] {
			if err := visit(id); err != nil {
				return nil, err
			}
		}
	}

	return result, nil
}

// executeStages exécute les étapes du pipeline dans l'ordre calculé
func (po *PipelineOrchestrator) executeStages(initialInput interface{}) {
	// Créer un map pour stocker les données de sortie des étapes
	outputs := make(map[string]interface{})
	
	// Exécuter les étapes dans l'ordre
	semaControl := make(chan struct{}, po.maxConcurrentStages)
	
	for _, stageID := range po.executionOrder {
		stage := po.stages[stageID]
		
		// Ne pas commencer une étape si le pipeline est stoppé
		select {
		case <-po.ctx.Done():
			// Mise à jour du statut des étapes non exécutées
			po.markRemainingStagesAsCancelled()
			return
		default:
			// Continuer l'exécution
		}
		
		// Vérifier que toutes les dépendances sont satisfaites
		dependenciesOk, input := po.checkDependencies(stageID, outputs)
		if !dependenciesOk {
			po.updateStageStatus(stageID, "skipped", nil, time.Time{}, time.Time{})
			continue
		}
		
		// Limiter le nombre d'étapes parallèles
		semaControl <- struct{}{}
		
		po.wg.Add(1)
		go func(sid string, s PipelineStage, in interface{}) {
			defer po.wg.Done()
			defer func() { <-semaControl }()
			
			// Exécuter l'étape
			result := po.executeStage(sid, s, in)
			
			// Stocker le résultat
			po.mu.Lock()
			po.stageResults[sid] = result
			outputs[sid] = result.Output
			po.mu.Unlock()
			
			// Notifier qu'une étape est terminée
			po.stageCompletedSignal <- sid
			
			// Incrémenter le compteur des étapes terminées
			atomic.AddInt32(&po.completedStages, 1)
		}(stageID, stage, input)
	}
}

// executeStage exécute une seule étape du pipeline avec timeout
func (po *PipelineOrchestrator) executeStage(stageID string, stage PipelineStage, input interface{}) *PipelineResult {
	stageCtx := po.ctx
	var cancel context.CancelFunc
	
	// Créer un contexte avec timeout spécifique si défini
	timeout := po.stageTimeout
	if stage.Timeout > 0 {
		timeout = stage.Timeout
	}
	
	if timeout > 0 {
		stageCtx, cancel = context.WithTimeout(po.ctx, timeout)
		defer cancel()
	}
	
	// Mettre à jour le statut
	startTime := time.Now()
	po.updateStageStatus(stageID, "running", nil, startTime, time.Time{})
	
	// Créer une tâche
	task := Task{
		ID:       stageID,
		Priority: stage.Priority,
		Execute: func(ctx context.Context) error {
			var err error
			result := &PipelineResult{
				StageID:   stageID,
				StartTime: startTime,
				Metadata:  make(map[string]interface{}),
			}
			
			defer func() {
				// Récupérer les panics
				if r := recover(); r != nil {
					err = fmt.Errorf("stage %s panicked: %v", stageID, r)
					result.Status = "failed"
				}
				
				// Enregistrer le résultat
				result.EndTime = time.Now()
				result.Duration = result.EndTime.Sub(result.StartTime)
				result.Error = err
				
				if err != nil {
					result.Status = "failed"
					po.updateStageStatus(stageID, "failed", err, startTime, time.Now())
				} else {
					result.Status = "completed"
					po.updateStageStatus(stageID, "completed", nil, startTime, time.Now())
				}
				
				po.mu.Lock()
				po.stageResults[stageID] = result
				po.mu.Unlock()
			}()
			
			// Exécuter l'étape
			result.Output, err = stage.Execute(ctx, input)
			return err
		},
		Timeout: timeout,
	}
	
	// Soumettre la tâche au worker pool
	submitted, err := po.workerPool.SubmitTask(task)
	if !submitted || err != nil {
		return &PipelineResult{
			StageID:   stageID,
			Status:    "failed",
			Error:     fmt.Errorf("failed to submit task: %v", err),
			StartTime: startTime,
			EndTime:   time.Now(),
			Duration:  time.Since(startTime),
			Metadata:  map[string]interface{}{"error": "task_submission_failed"},
		}
	}
	
	// Récupérer le résultat depuis le worker pool
	var taskResult *PipelineResult
	
	// Attendre le résultat depuis le worker pool
	for result := range po.workerPool.GetResults() {
		if result.TaskID == stageID {
			taskResult = &PipelineResult{
				StageID:   stageID,
				Error:     result.Error,
				StartTime: result.StartTime,
				EndTime:   result.EndTime,
				Duration:  result.Duration,
				Metadata:  make(map[string]interface{}),
			}
			
			if result.Error != nil {
				taskResult.Status = "failed"
			} else {
				taskResult.Status = "completed"
			}
			
			break
		}
	}
	
	// Si on n'a pas pu récupérer le résultat
	if taskResult == nil {
		taskResult = &PipelineResult{
			StageID:   stageID,
			Status:    "failed",
			Error:     fmt.Errorf("failed to get task result"),
			StartTime: startTime,
			EndTime:   time.Now(),
			Duration:  time.Since(startTime),
			Metadata:  map[string]interface{}{"error": "result_retrieval_failed"},
		}
	}
	
	return taskResult
}

// updateStageStatus met à jour le statut d'une étape
func (po *PipelineOrchestrator) updateStageStatus(stageID, status string, err error, startTime, endTime time.Time) {
	po.mu.Lock()
	defer po.mu.Unlock()
	
	if status == po.stageStatus[stageID].Status {
		return
	}
	
	po.stageStatus[stageID].Status = status
	
	if !startTime.IsZero() {
		po.stageStatus[stageID].StartTime = startTime
	}
	
	if !endTime.IsZero() {
		po.stageStatus[stageID].EndTime = endTime
		po.stageStatus[stageID].Duration = endTime.Sub(po.stageStatus[stageID].StartTime)
		po.stageStatus[stageID].IsCompleted = (status == "completed" || status == "failed" || status == "skipped")
	}
	
	if err != nil {
		po.stageStatus[stageID].Error = err
	}
}

// checkDependencies vérifie que toutes les dépendances d'une étape sont satisfaites
func (po *PipelineOrchestrator) checkDependencies(stageID string, outputs map[string]interface{}) (bool, interface{}) {
	po.mu.RLock()
	defer po.mu.RUnlock()
	
	// Vérifier les dépendances
	stage := po.stages[stageID]
	
	for _, depID := range stage.DependsOn {
		depStatus, exists := po.stageStatus[depID]
		if !exists || depStatus.Status != "completed" {
			return false, nil
		}
	}
	
	// Déterminer l'entrée pour cette étape
	var input interface{}
	
	// Si l'étape a une seule dépendance, utiliser sa sortie comme entrée
	if len(stage.DependsOn) == 1 {
		input = outputs[stage.DependsOn[0]]
	} else if len(stage.DependsOn) > 1 {
		// Si plusieurs dépendances, créer une map des sorties
		inputs := make(map[string]interface{})
		for _, depID := range stage.DependsOn {
			inputs[depID] = outputs[depID]
		}
		input = inputs
	}
	
	return true, input
}

// markRemainingStagesAsCancelled marque toutes les étapes non exécutées comme annulées
func (po *PipelineOrchestrator) markRemainingStagesAsCancelled() {
	po.mu.Lock()
	defer po.mu.Unlock()
	
	for id, status := range po.stageStatus {
		if status.Status == "pending" {
			status.Status = "cancelled"
		}
	}
}

// monitorPipeline surveille l'exécution du pipeline
func (po *PipelineOrchestrator) monitorPipeline() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			// Vérifier si le pipeline est terminé
			if atomic.LoadInt32(&po.completedStages) == po.totalStages {
				if atomic.CompareAndSwapInt32(&po.isRunning, 1, 0) {
					po.endTime = time.Now()
					po.cancel() // Annuler le contexte
				}
				return
			}
			
			// Autres vérifications de santé du pipeline...
			
		case completedStage := <-po.stageCompletedSignal:
			// Une étape est terminée, vérifier son statut
			po.mu.RLock()
			stageResult, exists := po.stageResults[completedStage]
			po.mu.RUnlock()
			
			if !exists || stageResult.Error == nil {
				continue
			}
			
			// Gérer les échecs selon la stratégie de récupération
			switch po.recoveryStrategy {
			case FailFast:
				if atomic.CompareAndSwapInt32(&po.isRunning, 1, 0) {
					po.cancel() // Annuler le contexte pour arrêter les autres étapes
				}
				return
				
			case RetryOnce, RetryWithBackoff:
				// Implémenter la logique de retry
				go po.handleRetry(completedStage, stageResult)
				
			case SkipFailed:
				// Continuer l'exécution, les dépendances de l'étape échouée seront automatiquement ignorées
			}
			
		case <-po.ctx.Done():
			// Contexte annulé ou timeout
			if atomic.CompareAndSwapInt32(&po.isRunning, 1, 0) {
				po.endTime = time.Now()
			}
			return
		}
	}
}

// handleRetry gère les tentatives de réexécution d'une étape échouée
func (po *PipelineOrchestrator) handleRetry(stageID string, result *PipelineResult) {
	po.mu.Lock()
	stageStatus := po.stageStatus[stageID]
	po.mu.Unlock()
	
	if stageStatus.RetryCount >= po.retryLimit {
		return
	}
	
	// Incrémenter le compteur de retry
	stageStatus.RetryCount++
	
	// Attendre avant de réessayer si nécessaire
	if po.recoveryStrategy == RetryWithBackoff {
		backoffDelay := po.retryDelayMs * (1 << uint(stageStatus.RetryCount-1)) // Exponentiel: 1s, 2s, 4s...
		time.Sleep(time.Duration(backoffDelay) * time.Millisecond)
	} else {
		time.Sleep(time.Duration(po.retryDelayMs) * time.Millisecond)
	}
	
	// Réinitialiser le statut pour réexécuter l'étape
	po.updateStageStatus(stageID, "pending", nil, time.Time{}, time.Time{})
	
	// Décrémentation du compteur des étapes terminées
	atomic.AddInt32(&po.completedStages, -1)
	
	// Récupérer la dernière entrée
	var input interface{}
	po.mu.RLock()
	stage := po.stages[stageID]
	outputs := make(map[string]interface{})
	for id, res := range po.stageResults {
		if res.Status == "completed" {
			outputs[id] = res.Output
		}
	}
	po.mu.RUnlock()
	
	// Vérifier les dépendances et obtenir l'entrée
	dependenciesOk, input := po.checkDependencies(stageID, outputs)
	if !dependenciesOk {
		po.updateStageStatus(stageID, "skipped", fmt.Errorf("dependencies not satisfied during retry"), time.Time{}, time.Now())
		return
	}
	
	// Réexécuter l'étape
	task := Task{
		ID:       fmt.Sprintf("%s_retry_%d", stageID, stageStatus.RetryCount),
		Priority: stage.Priority + 1, // Priorité plus élevée pour les retries
		Execute: func(ctx context.Context) error {
			startTime := time.Now()
			newResult := &PipelineResult{
				StageID:   stageID,
				StartTime: startTime,
				Metadata:  map[string]interface{}{"retry_count": stageStatus.RetryCount},
			}
			
			var err error
			newResult.Output, err = stage.Execute(ctx, input)
			
			newResult.EndTime = time.Now()
			newResult.Duration = newResult.EndTime.Sub(newResult.StartTime)
			
			if err != nil {
				newResult.Status = "failed"
				newResult.Error = err
			} else {
				newResult.Status = "completed"
			}
			
			po.mu.Lock()
			po.stageResults[stageID] = newResult
			po.mu.Unlock()
			
			po.updateStageStatus(stageID, newResult.Status, err, startTime, newResult.EndTime)
			
			// Incrémenter le compteur des étapes terminées
			if err == nil {
				atomic.AddInt32(&po.completedStages, 1)
				po.stageCompletedSignal <- stageID
			}
			
			return err
		},
		Timeout: po.stageTimeout,
	}
	
	// Soumettre la tâche au worker pool
	po.workerPool.SubmitTask(task)
}
