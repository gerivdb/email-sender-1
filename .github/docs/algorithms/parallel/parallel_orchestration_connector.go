// File: .github/docs/algorithms/parallel/parallel_orchestration_connector.go
// EMAIL_SENDER_1 Parallel Orchestration Connector
// Module de connexion entre l'orchestrateur principal et le système de pipeline parallélisé

package parallel

import (
	"context"
	"fmt"
	"log"
	"runtime"
	"sync"
	"time"
)

// ParallelOrchestrationConfig définit la configuration pour l'orchestration parallèle
type ParallelOrchestrationConfig struct {
	// Paramètres de parallélisation
	MaxWorkers            int           `json:"max_workers"`
	MaxConcurrentPipelines int          `json:"max_concurrent_pipelines"`
	MaxQueueSize          int           `json:"max_queue_size"`
	
	// Paramètres de résilience
	RetryLimit            int           `json:"retry_limit"`
	RetryDelayMs          int           `json:"retry_delay_ms"`
	PipelineTimeout       time.Duration `json:"pipeline_timeout"`
	StageTimeout          time.Duration `json:"stage_timeout"`
	RecoveryStrategy      string        `json:"recovery_strategy"`
	
	// Paramètres de supervision
	EnableStats           bool          `json:"enable_stats"`
	StatsIntervalSec      int           `json:"stats_interval_sec"`
	LogLevel              string        `json:"log_level"`
	OutputPath            string        `json:"output_path"`

	// Configuration EMAIL_SENDER
	BatchSize             int           `json:"batch_size"`
	NotionAPIKey          string        `json:"notion_api_key"`
	GmailCredentialsPath  string        `json:"gmail_credentials_path"`
	N8NWebhookURL         string        `json:"n8n_webhook_url"`
	RAGEndpoint           string        `json:"rag_endpoint"`
}

// DefaultParallelOrchestrationConfig retourne une configuration par défaut
func DefaultParallelOrchestrationConfig() ParallelOrchestrationConfig {
	return ParallelOrchestrationConfig{
		MaxWorkers:            runtime.NumCPU(),
		MaxConcurrentPipelines: 2,
		MaxQueueSize:          100,
		RetryLimit:            3,
		RetryDelayMs:          1000,
		PipelineTimeout:       30 * time.Minute,
		StageTimeout:          1 * time.Minute,
		RecoveryStrategy:      "retry-with-backoff",
		EnableStats:           true,
		StatsIntervalSec:      30,
		LogLevel:              "INFO",
		OutputPath:            "./output",
		BatchSize:             10,
	}
}

// ParallelOrchestrationConnector gère la connexion entre l'orchestrateur principal
// et le système de pipeline parallélisé
type ParallelOrchestrationConnector struct {
	config           ParallelOrchestrationConfig
	emailPipelines   []*EmailSenderPipeline
	pipelineLimiter  chan struct{}
	globalStats      *GlobalParallelStats
	pipelinesWg      sync.WaitGroup
	statsMu          sync.RWMutex
	ctx              context.Context
	cancel           context.CancelFunc
}

// GlobalParallelStats contient les statistiques globales de tous les pipelines
type GlobalParallelStats struct {
	TotalEmailsProcessed   int64                   `json:"total_emails_processed"`
	SuccessfulEmails       int64                   `json:"successful_emails"`
	FailedEmails           int64                   `json:"failed_emails"`
	TotalBatchesProcessed  int64                   `json:"total_batches_processed"`
	AverageProcessingTime  time.Duration           `json:"average_processing_time"`
	ErrorsByType           map[string]int64        `json:"errors_by_type"`
	ErrorsByComponent      map[string]int64        `json:"errors_by_component"`
	TotalRetries           int64                   `json:"total_retries"`
	StartTime              time.Time               `json:"start_time"`
	EndTime                time.Time               `json:"end_time"`
	ActivePipelines        int                     `json:"active_pipelines"`
	QueuedPipelines        int                     `json:"queued_pipelines"`
	PipelineStats          map[string]interface{}  `json:"pipeline_stats"`
}

// NewParallelOrchestrationConnector crée un nouveau connecteur d'orchestration parallèle
func NewParallelOrchestrationConnector(config ParallelOrchestrationConfig) *ParallelOrchestrationConnector {
	ctx, cancel := context.WithCancel(context.Background())
	
	globalStats := &GlobalParallelStats{
		ErrorsByType:      make(map[string]int64),
		ErrorsByComponent: make(map[string]int64),
		PipelineStats:     make(map[string]interface{}),
		StartTime:         time.Now(),
	}
	
	return &ParallelOrchestrationConnector{
		config:          config,
		emailPipelines:  make([]*EmailSenderPipeline, 0),
		pipelineLimiter: make(chan struct{}, config.MaxConcurrentPipelines),
		globalStats:     globalStats,
		ctx:             ctx,
		cancel:          cancel,
	}
}

// CreateEmailPipeline crée un nouveau pipeline EMAIL_SENDER avec les configurations nécessaires
func (poc *ParallelOrchestrationConnector) CreateEmailPipeline(pipelineID string) (*EmailSenderPipeline, error) {
	// Convertir la configuration du connecteur en configuration de pipeline
	pipelineConfig := EmailSenderPipelineConfig{
		MaxWorkers:          poc.config.MaxWorkers,
		MaxQueueSize:        poc.config.MaxQueueSize,
		BatchSize:           poc.config.BatchSize,
		MaxRetries:          poc.config.RetryLimit,
		RetryDelayMs:        poc.config.RetryDelayMs,
		PipelineTimeout:     poc.config.PipelineTimeout,
		StageTimeout:        poc.config.StageTimeout,
		OutputPath:          poc.config.OutputPath,
		EnableStats:         poc.config.EnableStats,
		StatsIntervalSec:    poc.config.StatsIntervalSec,
		LogLevel:            poc.config.LogLevel,
		NotionAPIKey:        poc.config.NotionAPIKey,
		GmailCredentialsPath: poc.config.GmailCredentialsPath,
		N8NWebhookURL:       poc.config.N8NWebhookURL,
		RAGEndpoint:         poc.config.RAGEndpoint,
	}
	
	// Créer un nouveau pipeline EMAIL_SENDER
	pipeline, err := NewEmailSenderPipeline(pipelineConfig)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la création du pipeline %s: %w", pipelineID, err)
	}
	
	// Ajouter le pipeline à la liste des pipelines gérés
	poc.statsMu.Lock()
	poc.emailPipelines = append(poc.emailPipelines, pipeline)
	poc.globalStats.PipelineStats[pipelineID] = map[string]interface{}{
		"id":           pipelineID,
		"status":       "created",
		"created_at":   time.Now(),
		"batch_count":  0,
		"email_count":  0,
	}
	poc.statsMu.Unlock()
	
	return pipeline, nil
}

// StartPipelineWithBatches démarre un pipeline avec un ensemble de lots d'emails
func (poc *ParallelOrchestrationConnector) StartPipelineWithBatches(pipelineID string, batches []EmailBatch) error {
	// Récupérer ou créer le pipeline
	var pipeline *EmailSenderPipeline
	var exists bool
	
	// Vérifier si le pipeline existe déjà
	for _, p := range poc.emailPipelines {
		if p != nil && fmt.Sprintf("%p", p) == pipelineID {
			pipeline = p
			exists = true
			break
		}
	}
	
	// Si le pipeline n'existe pas, en créer un nouveau
	if !exists {
		var err error
		pipeline, err = poc.CreateEmailPipeline(pipelineID)
		if err != nil {
			return err
		}
	}
	
	// Acquérir un slot dans le limiteur de pipelines
	select {
	case poc.pipelineLimiter <- struct{}{}:
		// Slot acquis, on continue
	default:
		// Pas de slot disponible, on met en file d'attente
		poc.statsMu.Lock()
		poc.globalStats.QueuedPipelines++
		poc.statsMu.Unlock()
		
		log.Printf("Pipeline %s en attente de ressources disponibles", pipelineID)
		poc.pipelineLimiter <- struct{}{} // Bloque jusqu'à ce qu'un slot soit disponible
	}
	
	// Incrémenter le compteur de pipelines actifs
	poc.statsMu.Lock()
	poc.globalStats.ActivePipelines++
	poc.globalStats.QueuedPipelines--
	if poc.globalStats.QueuedPipelines < 0 {
		poc.globalStats.QueuedPipelines = 0
	}
	poc.statsMu.Unlock()
	
	// Démarrer le pipeline
	err := pipeline.Start()
	if err != nil {
		// En cas d'erreur, libérer le slot et retourner l'erreur
		<-poc.pipelineLimiter
		
		poc.statsMu.Lock()
		poc.globalStats.ActivePipelines--
		poc.statsMu.Unlock()
		
		return fmt.Errorf("erreur lors du démarrage du pipeline %s: %w", pipelineID, err)
	}
	
	// Démarrer une goroutine pour soumettre les lots au pipeline
	poc.pipelinesWg.Add(1)
	go func(p *EmailSenderPipeline, batchList []EmailBatch) {
		defer poc.pipelinesWg.Done()
		defer func() {
			// Libérer le slot quand le pipeline est terminé
			<-poc.pipelineLimiter
			
			poc.statsMu.Lock()
			poc.globalStats.ActivePipelines--
			poc.statsMu.Unlock()
		}()
		
		// Soumettre chaque lot au pipeline
		for _, batch := range batchList {
			select {
			case <-poc.ctx.Done():
				// Contexte annulé, arrêter la soumission
				log.Printf("Soumission du lot %s annulée (pipeline: %s)", batch.BatchID, pipelineID)
				return
			default:
				// Soumettre le lot
				if err := p.SubmitBatch(batch); err != nil {
					log.Printf("Erreur lors de la soumission du lot %s au pipeline %s: %v", 
						batch.BatchID, pipelineID, err)
					continue
				}
				
				// Mettre à jour les statistiques
				poc.statsMu.Lock()
				pStats := poc.globalStats.PipelineStats[pipelineID].(map[string]interface{})
				pStats["batch_count"] = pStats["batch_count"].(int) + 1
				pStats["email_count"] = pStats["email_count"].(int) + len(batch.EmailTasks)
				poc.globalStats.TotalBatchesProcessed++
				poc.statsMu.Unlock()
				
				log.Printf("Lot %s soumis au pipeline %s avec %d emails", 
					batch.BatchID, pipelineID, len(batch.EmailTasks))
			}
		}
		
		// Attendre que le pipeline termine le traitement de tous les lots
		p.Wait()
		
		// Collecter les statistiques finales
		stats := p.GetStats()
		
		// Mettre à jour les statistiques globales
		poc.updateGlobalStats(pipelineID, stats)
		
		log.Printf("Pipeline %s terminé. %d emails traités, %d réussis, %d échoués", 
			pipelineID, stats.TotalEmailsProcessed, stats.SuccessfulEmails, stats.FailedEmails)
	}(pipeline, batches)
	
	return nil
}

// updateGlobalStats met à jour les statistiques globales avec les données d'un pipeline
func (poc *ParallelOrchestrationConnector) updateGlobalStats(pipelineID string, stats EmailPipelineStats) {
	poc.statsMu.Lock()
	defer poc.statsMu.Unlock()
	
	// Mettre à jour les compteurs globaux
	poc.globalStats.TotalEmailsProcessed += stats.TotalEmailsProcessed
	poc.globalStats.SuccessfulEmails += stats.SuccessfulEmails
	poc.globalStats.FailedEmails += stats.FailedEmails
	poc.globalStats.TotalRetries += stats.TotalRetries
	
	// Mettre à jour les erreurs par type et par composant
	for errType, count := range stats.ErrorsByType {
		poc.globalStats.ErrorsByType[errType] += count
	}
	
	for component, count := range stats.ErrorsByComponent {
		poc.globalStats.ErrorsByComponent[component] += count
	}
	
	// Calculer le temps de traitement moyen
	// Cette implémentation est simpliste et pourrait être améliorée
	if poc.globalStats.TotalEmailsProcessed > 0 {
		totalDuration := poc.globalStats.AverageProcessingTime.Nanoseconds() * 
			(poc.globalStats.TotalEmailsProcessed - stats.TotalEmailsProcessed)
		
		if stats.AverageProcessingTime > 0 && stats.TotalEmailsProcessed > 0 {
			totalDuration += stats.AverageProcessingTime.Nanoseconds() * stats.TotalEmailsProcessed
		}
		
		poc.globalStats.AverageProcessingTime = time.Duration(
			totalDuration / poc.globalStats.TotalEmailsProcessed)
	}
	
	// Mettre à jour les statistiques du pipeline
	pStats := poc.globalStats.PipelineStats[pipelineID].(map[string]interface{})
	pStats["status"] = "completed"
	pStats["completed_at"] = time.Now()
	pStats["success_count"] = stats.SuccessfulEmails
	pStats["error_count"] = stats.FailedEmails
	pStats["retry_count"] = stats.TotalRetries
}

// GetGlobalStats retourne les statistiques globales de tous les pipelines
func (poc *ParallelOrchestrationConnector) GetGlobalStats() GlobalParallelStats {
	poc.statsMu.RLock()
	defer poc.statsMu.RUnlock()
	
	// Faire une copie des statistiques pour éviter les modifications concurrentes
	statsCopy := *poc.globalStats
	statsCopy.PipelineStats = make(map[string]interface{})
	
	for id, stats := range poc.globalStats.PipelineStats {
		if statsMap, ok := stats.(map[string]interface{}); ok {
			// Copie profonde de la map
			statsCopy.PipelineStats[id] = make(map[string]interface{})
			for k, v := range statsMap {
				statsCopy.PipelineStats[id].(map[string]interface{})[k] = v
			}
		} else {
			statsCopy.PipelineStats[id] = stats
		}
	}
	
	return statsCopy
}

// Wait attend que tous les pipelines soient terminés
func (poc *ParallelOrchestrationConnector) Wait() {
	poc.pipelinesWg.Wait()
	poc.globalStats.EndTime = time.Now()
}

// Stop arrête tous les pipelines en cours d'exécution
func (poc *ParallelOrchestrationConnector) Stop() {
	log.Printf("Arrêt de l'orchestration parallèle (%d pipelines actifs)", len(poc.emailPipelines))
	
	// Annuler le contexte principal
	poc.cancel()
	
	// Arrêter tous les pipelines
	for _, pipeline := range poc.emailPipelines {
		if pipeline != nil {
			pipeline.Stop()
		}
	}
	
	// Attendre que toutes les goroutines se terminent
	poc.pipelinesWg.Wait()
	
	// Mettre à jour le temps de fin
	poc.globalStats.EndTime = time.Now()
	
	log.Printf("Orchestration parallèle arrêtée. Total: %d emails traités, %d réussis, %d échoués",
		poc.globalStats.TotalEmailsProcessed,
		poc.globalStats.SuccessfulEmails,
		poc.globalStats.FailedEmails)
}
