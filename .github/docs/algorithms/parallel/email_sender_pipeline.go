// File: .github/docs/algorithms/parallel/email_sender_pipeline.go
// EMAIL_SENDER_1 Pipeline Implementation
// Implémentation concrète du pipeline pour le traitement des emails

package parallel

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// EmailTask représente une tâche de traitement d'email
type EmailTask struct {
	ID                string                 `json:"id"`
	ContactID         string                 `json:"contact_id"`
	EmailType         string                 `json:"email_type"`       // "prospection", "suivi", "réponse"
	Priority          int                    `json:"priority"`
	Status            string                 `json:"status"`
	CreatedAt         time.Time              `json:"created_at"`
	ProcessedAt       time.Time              `json:"processed_at"`
	CompletedAt       time.Time              `json:"completed_at"`
	Duration          time.Duration          `json:"duration"`
	Metadata          map[string]interface{} `json:"metadata"`
	ContactMetadata   map[string]interface{} `json:"contact_metadata"`
	EmailContent      string                 `json:"email_content"`
	RAGContext        interface{}            `json:"rag_context"`
	WorkflowID        string                 `json:"workflow_id"`
	NotionDatabaseID  string                 `json:"notion_database_id"`
	RetryCount        int                    `json:"retry_count"`
	ErrorDetails      string                 `json:"error_details"`
}

// EmailBatch représente un lot d'emails à traiter
type EmailBatch struct {
	BatchID     string      `json:"batch_id"`
	EmailTasks  []EmailTask `json:"email_tasks"`
	BatchSize   int         `json:"batch_size"`
	Priority    int         `json:"priority"`
	CreatedAt   time.Time   `json:"created_at"`
	ProcessedAt time.Time   `json:"processed_at"`
	Status      string      `json:"status"`
}

// EmailSenderPipeline orchestre le traitement des emails
type EmailSenderPipeline struct {
	orchestrator      *PipelineOrchestrator
	workerPool        *WorkerPool
	config            EmailSenderPipelineConfig
	batchProcessor    *EmailBatchProcessor
	notionClient      NotionClient
	gmailClient       GmailClient
	ragClient         RAGClient
	n8nClient         N8NClient
	pipelineMu        sync.RWMutex
	stats             *EmailPipelineStats
	batchQueue        chan EmailBatch
	resultCollector   chan EmailTask
	errorCollector    chan EmailProcessingError
	wg                sync.WaitGroup
	ctx               context.Context
	cancel            context.CancelFunc
}

// EmailProcessingError représente une erreur lors du traitement d'un email
type EmailProcessingError struct {
	TaskID      string    `json:"task_id"`
	StageID     string    `json:"stage_id"`
	ErrorType   string    `json:"error_type"`
	Message     string    `json:"message"`
	Timestamp   time.Time `json:"timestamp"`
	RetryCount  int       `json:"retry_count"`
	Component   string    `json:"component"` // "RAG", "Notion", "Gmail", "N8N"
	IsRetryable bool      `json:"is_retryable"`
}

// EmailPipelineStats contient les statistiques du pipeline d'emails
type EmailPipelineStats struct {
	TotalEmailsProcessed   int64         `json:"total_emails_processed"`
	SuccessfulEmails       int64         `json:"successful_emails"`
	FailedEmails           int64         `json:"failed_emails"`
	TotalBatchesProcessed  int64         `json:"total_batches_processed"`
	CurrentQueueSize       int           `json:"current_queue_size"`
	AverageProcessingTime  time.Duration `json:"average_processing_time"`
	AverageBatchSize       float64       `json:"average_batch_size"`
	ErrorsByType           map[string]int64 `json:"errors_by_type"`
	ErrorsByComponent      map[string]int64 `json:"errors_by_component"`
	TotalRetries           int64         `json:"total_retries"`
	LastProcessedTimestamp time.Time     `json:"last_processed_timestamp"`
	StartTime              time.Time     `json:"start_time"`
}

// EmailSenderPipelineConfig configure le pipeline EMAIL_SENDER
type EmailSenderPipelineConfig struct {
	MaxWorkers           int           `json:"max_workers"`
	MaxQueueSize         int           `json:"max_queue_size"`
	BatchSize            int           `json:"batch_size"`
	MaxRetries           int           `json:"max_retries"`
	RetryDelayMs         int           `json:"retry_delay_ms"`
	PipelineTimeout      time.Duration `json:"pipeline_timeout"`
	StageTimeout         time.Duration `json:"stage_timeout"`
	NotionAPIKey         string        `json:"notion_api_key"`
	GmailCredentialsPath string        `json:"gmail_credentials_path"`
	N8NWebhookURL        string        `json:"n8n_webhook_url"`
	RAGEndpoint          string        `json:"rag_endpoint"`
	OutputPath           string        `json:"output_path"`
	EnableStats          bool          `json:"enable_stats"`
	StatsIntervalSec     int           `json:"stats_interval_sec"`
	LogLevel             string        `json:"log_level"`
}

// EmailBatchProcessor traite les lots d'emails
type EmailBatchProcessor struct {
	notionClient  NotionClient
	gmailClient   GmailClient
	ragClient     RAGClient
	n8nClient     N8NClient
	config        EmailSenderPipelineConfig
	statsCollector *EmailPipelineStats
}

// RAGClient interface for interacting with the RAG system
type RAGClient interface {
	GetEmailContext(ctx context.Context, contactID string, emailType string) (interface{}, error)
	IndexEmail(ctx context.Context, emailContent string, metadata map[string]interface{}) error
}

// NotionClient interface for interacting with Notion
type NotionClient interface {
	GetContact(ctx context.Context, contactID string) (map[string]interface{}, error)
	UpdateContactStatus(ctx context.Context, contactID string, status string) error
	LogEmailSent(ctx context.Context, contactID string, emailContent string, metadata map[string]interface{}) error
}

// GmailClient interface for interacting with Gmail
type GmailClient interface {
	SendEmail(ctx context.Context, to string, subject string, content string, metadata map[string]interface{}) (string, error)
	TrackEmail(ctx context.Context, emailID string) (map[string]interface{}, error)
}

// N8NClient interface for interacting with N8N
type N8NClient interface {
	TriggerWorkflow(ctx context.Context, workflowID string, data map[string]interface{}) error
	GetWorkflowStatus(ctx context.Context, executionID string) (string, error)
}

// DefaultEmailPipelineConfig retourne une configuration par défaut
func DefaultEmailPipelineConfig() EmailSenderPipelineConfig {
	return EmailSenderPipelineConfig{
		MaxWorkers:       8,
		MaxQueueSize:     100,
		BatchSize:        10,
		MaxRetries:       3,
		RetryDelayMs:     1000,
		PipelineTimeout:  30 * time.Minute,
		StageTimeout:     1 * time.Minute,
		OutputPath:       "./output",
		EnableStats:      true,
		StatsIntervalSec: 30,
		LogLevel:         "INFO",
	}
}

// NewEmailSenderPipeline crée un nouveau pipeline EMAIL_SENDER
func NewEmailSenderPipeline(config EmailSenderPipelineConfig) (*EmailSenderPipeline, error) {
	// Validation de la configuration
	if err := validateConfig(config); err != nil {
		return nil, err
	}
	
	ctx, cancel := context.WithCancel(context.Background())
	
	// Créer les clients
	notionClient, err := createNotionClient(config.NotionAPIKey)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create Notion client: %w", err)
	}
	
	gmailClient, err := createGmailClient(config.GmailCredentialsPath)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create Gmail client: %w", err)
	}
	
	ragClient, err := createRAGClient(config.RAGEndpoint)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create RAG client: %w", err)
	}
	
	n8nClient, err := createN8NClient(config.N8NWebhookURL)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create N8N client: %w", err)
	}
	
	// Créer le worker pool
	workerPool := NewWorkerPool(config.MaxWorkers, config.MaxQueueSize)
	
	// Créer l'orchestrateur de pipeline
	orchestratorConfig := PipelineOrchestratorConfig{
		MaxWorkers:          config.MaxWorkers,
		MaxQueueSize:        config.MaxQueueSize,
		MaxConcurrentStages: config.MaxWorkers / 2,
		PipelineTimeout:     config.PipelineTimeout,
		StageTimeout:        config.StageTimeout,
		RecoveryStrategy:    RetryWithBackoff,
		RetryLimit:          config.MaxRetries,
		RetryDelayMs:        config.RetryDelayMs,
	}
	
	orchestrator := NewPipelineOrchestrator(orchestratorConfig)
	
	// Créer les statistiques
	stats := &EmailPipelineStats{
		ErrorsByType:      make(map[string]int64),
		ErrorsByComponent: make(map[string]int64),
		StartTime:         time.Now(),
	}
	
	// Créer le processor de batch
	batchProcessor := &EmailBatchProcessor{
		notionClient:   notionClient,
		gmailClient:    gmailClient,
		ragClient:      ragClient,
		n8nClient:      n8nClient,
		config:         config,
		statsCollector: stats,
	}
	
	// Créer les canaux
	batchQueue := make(chan EmailBatch, config.MaxQueueSize)
	resultCollector := make(chan EmailTask, config.MaxQueueSize*config.BatchSize)
	errorCollector := make(chan EmailProcessingError, config.MaxQueueSize)
	
	return &EmailSenderPipeline{
		orchestrator:    orchestrator,
		workerPool:      workerPool,
		config:          config,
		batchProcessor:  batchProcessor,
		notionClient:    notionClient,
		gmailClient:     gmailClient,
		ragClient:       ragClient,
		n8nClient:       n8nClient,
		stats:           stats,
		batchQueue:      batchQueue,
		resultCollector: resultCollector,
		errorCollector:  errorCollector,
		ctx:             ctx,
		cancel:          cancel,
	}, nil
}

// validateConfig valide la configuration du pipeline
func validateConfig(config EmailSenderPipelineConfig) error {
	if config.MaxWorkers <= 0 {
		return fmt.Errorf("max_workers must be greater than 0")
	}
	
	if config.MaxQueueSize <= 0 {
		return fmt.Errorf("max_queue_size must be greater than 0")
	}
	
	if config.BatchSize <= 0 {
		return fmt.Errorf("batch_size must be greater than 0")
	}
	
	if config.NotionAPIKey == "" {
		return fmt.Errorf("notion_api_key is required")
	}
	
	if config.GmailCredentialsPath == "" {
		return fmt.Errorf("gmail_credentials_path is required")
	}
	
	if config.N8NWebhookURL == "" {
		return fmt.Errorf("n8n_webhook_url is required")
	}
	
	if config.RAGEndpoint == "" {
		return fmt.Errorf("rag_endpoint is required")
	}
	
	return nil
}

// createNotionClient crée un client Notion
func createNotionClient(apiKey string) (NotionClient, error) {
	// Implémentation simulée pour cet exemple
	return &mockNotionClient{apiKey: apiKey}, nil
}

// createGmailClient crée un client Gmail
func createGmailClient(credentialsPath string) (GmailClient, error) {
	// Implémentation simulée pour cet exemple
	return &mockGmailClient{credentialsPath: credentialsPath}, nil
}

// createRAGClient crée un client RAG
func createRAGClient(endpoint string) (RAGClient, error) {
	// Implémentation simulée pour cet exemple
	return &mockRAGClient{endpoint: endpoint}, nil
}

// createN8NClient crée un client N8N
func createN8NClient(webhookURL string) (N8NClient, error) {
	// Implémentation simulée pour cet exemple
	return &mockN8NClient{webhookURL: webhookURL}, nil
}

// Start démarre le pipeline EMAIL_SENDER
func (esp *EmailSenderPipeline) Start() error {
	log.Printf("🚀 Starting EMAIL_SENDER_1 Pipeline")
	log.Printf("⚙️ Configuration: %d workers, batch size %d", esp.config.MaxWorkers, esp.config.BatchSize)
	
	// Démarrer le worker pool
	esp.workerPool.Start()
	
	// Configurer et enregistrer les étapes du pipeline
	if err := esp.registerPipelineStages(); err != nil {
		return fmt.Errorf("failed to register pipeline stages: %w", err)
	}
	
	// Démarrer les collecteurs de résultats et d'erreurs
	esp.wg.Add(2)
	go esp.resultCollectorWorker()
	go esp.errorCollectorWorker()
	
	// Démarrer le collecteur de statistiques si activé
	if esp.config.EnableStats {
		esp.wg.Add(1)
		go esp.statsCollectorWorker()
	}
	
	// Démarrer le traitement des lots
	esp.wg.Add(1)
	go esp.batchProcessorWorker()
	
	log.Printf("✅ EMAIL_SENDER_1 Pipeline started successfully")
	return nil
}

// registerPipelineStages enregistre toutes les étapes du pipeline
func (esp *EmailSenderPipeline) registerPipelineStages() error {
	// Étape 1: Préparation et enrichissement des données
	prepareStage := PipelineStage{
		ID:          "prepare",
		Name:        "Préparation et enrichissement",
		Description: "Prépare et enrichit les données de contact pour le traitement",
		Priority:    1,
		DependsOn:   []string{},
		Timeout:     30 * time.Second,
		Execute: func(ctx context.Context, input interface{}) (interface{}, error) {
			batch, ok := input.(EmailBatch)
			if !ok {
				return nil, fmt.Errorf("invalid input type: expected EmailBatch")
			}
			
			// Enrichir chaque tâche d'email avec les données de contact
			for i := range batch.EmailTasks {
				contactMetadata, err := esp.notionClient.GetContact(ctx, batch.EmailTasks[i].ContactID)
				if err != nil {
					return nil, fmt.Errorf("failed to get contact %s: %w", batch.EmailTasks[i].ContactID, err)
				}
				batch.EmailTasks[i].ContactMetadata = contactMetadata
				batch.EmailTasks[i].Status = "prepared"
			}
			
			return batch, nil
		},
	}
	
	// Étape 2: Génération de contexte RAG
	ragContextStage := PipelineStage{
		ID:          "rag_context",
		Name:        "Génération contexte RAG",
		Description: "Récupère le contexte RAG pour personnaliser les emails",
		Priority:    2,
		DependsOn:   []string{"prepare"},
		Timeout:     45 * time.Second,
		Execute: func(ctx context.Context, input interface{}) (interface{}, error) {
			batch, ok := input.(EmailBatch)
			if !ok {
				return nil, fmt.Errorf("invalid input type: expected EmailBatch")
			}
			
			// Obtenir le contexte RAG pour chaque tâche
			for i := range batch.EmailTasks {
				ragContext, err := esp.ragClient.GetEmailContext(ctx, batch.EmailTasks[i].ContactID, batch.EmailTasks[i].EmailType)
				if err != nil {
					return nil, fmt.Errorf("failed to get RAG context for %s: %w", batch.EmailTasks[i].ContactID, err)
				}
				batch.EmailTasks[i].RAGContext = ragContext
				batch.EmailTasks[i].Status = "contextualized"
			}
			
			return batch, nil
		},
	}
	
	// Étape 3: Déclencher les workflows N8N
	n8nTriggerStage := PipelineStage{
		ID:          "n8n_trigger",
		Name:        "Déclenchement workflows N8N",
		Description: "Déclenche les workflows N8N pour le traitement des emails",
		Priority:    3,
		DependsOn:   []string{"rag_context"},
		Timeout:     1 * time.Minute,
		Execute: func(ctx context.Context, input interface{}) (interface{}, error) {
			batch, ok := input.(EmailBatch)
			if !ok {
				return nil, fmt.Errorf("invalid input type: expected EmailBatch")
			}
			
			// Déclencher le workflow N8N pour chaque tâche
			for i := range batch.EmailTasks {
				data := make(map[string]interface{})
				data["contactId"] = batch.EmailTasks[i].ContactID
				data["emailType"] = batch.EmailTasks[i].EmailType
				data["ragContext"] = batch.EmailTasks[i].RAGContext
				data["contactMetadata"] = batch.EmailTasks[i].ContactMetadata
				
				if err := esp.n8nClient.TriggerWorkflow(ctx, batch.EmailTasks[i].WorkflowID, data); err != nil {
					return nil, fmt.Errorf("failed to trigger N8N workflow %s: %w", batch.EmailTasks[i].WorkflowID, err)
				}
				
				batch.EmailTasks[i].Status = "workflow_triggered"
			}
			
			return batch, nil
		},
	}
	
	// Étape 4: Envoi des emails via Gmail
	sendEmailStage := PipelineStage{
		ID:          "send_email",
		Name:        "Envoi des emails",
		Description: "Envoie les emails via l'API Gmail",
		Priority:    4,
		DependsOn:   []string{"n8n_trigger"},
		Timeout:     1 * time.Minute,
		Execute: func(ctx context.Context, input interface{}) (interface{}, error) {
			batch, ok := input.(EmailBatch)
			if !ok {
				return nil, fmt.Errorf("invalid input type: expected EmailBatch")
			}
			
			// Envoyer l'email pour chaque tâche
			for i := range batch.EmailTasks {
				// Extraire l'email du contact
				email, ok := batch.EmailTasks[i].ContactMetadata["email"].(string)
				if !ok || email == "" {
					return nil, fmt.Errorf("invalid or missing email for contact %s", batch.EmailTasks[i].ContactID)
				}
				
				subject := fmt.Sprintf("Subject for %s", batch.EmailTasks[i].EmailType)
				
				emailID, err := esp.gmailClient.SendEmail(ctx, email, subject, batch.EmailTasks[i].EmailContent, batch.EmailTasks[i].Metadata)
				if err != nil {
					return nil, fmt.Errorf("failed to send email to %s: %w", email, err)
				}
				
				batch.EmailTasks[i].Metadata["email_id"] = emailID
				batch.EmailTasks[i].Status = "sent"
			}
			
			return batch, nil
		},
	}
	
	// Étape 5: Mise à jour de l'état dans Notion
	updateNotionStage := PipelineStage{
		ID:          "update_notion",
		Name:        "Mise à jour Notion",
		Description: "Met à jour l'état des contacts dans Notion",
		Priority:    5,
		DependsOn:   []string{"send_email"},
		Timeout:     30 * time.Second,
		Execute: func(ctx context.Context, input interface{}) (interface{}, error) {
			batch, ok := input.(EmailBatch)
			if !ok {
				return nil, fmt.Errorf("invalid input type: expected EmailBatch")
			}
			
			// Mettre à jour l'état dans Notion pour chaque tâche
			for i := range batch.EmailTasks {
				if err := esp.notionClient.UpdateContactStatus(ctx, batch.EmailTasks[i].ContactID, "email_sent"); err != nil {
					return nil, fmt.Errorf("failed to update Notion status for %s: %w", batch.EmailTasks[i].ContactID, err)
				}
				
				if err := esp.notionClient.LogEmailSent(ctx, batch.EmailTasks[i].ContactID, batch.EmailTasks[i].EmailContent, batch.EmailTasks[i].Metadata); err != nil {
					return nil, fmt.Errorf("failed to log email in Notion for %s: %w", batch.EmailTasks[i].ContactID, err)
				}
				
				batch.EmailTasks[i].Status = "completed"
			}
			
			return batch, nil
		},
	}
	
	// Enregistrer toutes les étapes
	if err := esp.orchestrator.RegisterStage(prepareStage); err != nil {
		return err
	}
	if err := esp.orchestrator.RegisterStage(ragContextStage); err != nil {
		return err
	}
	if err := esp.orchestrator.RegisterStage(n8nTriggerStage); err != nil {
		return err
	}
	if err := esp.orchestrator.RegisterStage(sendEmailStage); err != nil {
		return err
	}
	if err := esp.orchestrator.RegisterStage(updateNotionStage); err != nil {
		return err
	}
	
	return nil
}

// SubmitBatch soumet un lot d'emails pour traitement
func (esp *EmailSenderPipeline) SubmitBatch(batch EmailBatch) error {
	select {
	case esp.batchQueue <- batch:
		return nil
	default:
		return fmt.Errorf("batch queue is full")
	}
}

// GetStats retourne les statistiques actuelles du pipeline
func (esp *EmailSenderPipeline) GetStats() EmailPipelineStats {
	esp.pipelineMu.RLock()
	defer esp.pipelineMu.RUnlock()
	
	// Copier les statistiques pour éviter les race conditions
	statsCopy := *esp.stats
	return statsCopy
}

// batchProcessorWorker traite les lots d'emails
func (esp *EmailSenderPipeline) batchProcessorWorker() {
	defer esp.wg.Done()
	
	for {
		select {
		case <-esp.ctx.Done():
			return
		case batch, ok := <-esp.batchQueue:
			if !ok {
				return
			}
			
			// Mettre à jour le statut du lot
			batch.Status = "processing"
			batch.ProcessedAt = time.Now()
			
			// Démarrer l'orchestrateur de pipeline pour ce lot
			if err := esp.orchestrator.Start(batch); err != nil {
				log.Printf("Error starting pipeline for batch %s: %v", batch.BatchID, err)
				batch.Status = "failed"
				
				// Collecter les erreurs pour chaque tâche du lot
				for _, task := range batch.EmailTasks {
					esp.errorCollector <- EmailProcessingError{
						TaskID:      task.ID,
						StageID:     "batch_processor",
						ErrorType:   "batch_start_failed",
						Message:     err.Error(),
						Timestamp:   time.Now(),
						RetryCount:  0,
						Component:   "Orchestrator",
						IsRetryable: true,
					}
				}
			} else {
				// Attendre la fin de l'exécution du pipeline
				esp.orchestrator.Wait()
				
				// Récupérer les résultats
				results := esp.orchestrator.GetAllResults()
				
				// Chercher le résultat final (dernière étape)
				if result, ok := results["update_notion"]; ok && result.Status == "completed" {
					if finalBatch, ok := result.Output.(EmailBatch); ok {
						// Collecter les résultats pour chaque tâche
						for _, task := range finalBatch.EmailTasks {
							esp.resultCollector <- task
						}
						
						log.Printf("Batch %s processed successfully with %d tasks", batch.BatchID, len(finalBatch.EmailTasks))
					}
				} else {
					log.Printf("Batch %s processing incomplete", batch.BatchID)
					
					// Collecter les erreurs pour chaque étape qui a échoué
					for stageID, result := range results {
						if result.Status != "completed" {
							for _, task := range batch.EmailTasks {
								esp.errorCollector <- EmailProcessingError{
									TaskID:      task.ID,
									StageID:     stageID,
									ErrorType:   "stage_failed",
									Message:     fmt.Sprintf("Stage %s failed: %v", stageID, result.Error),
									Timestamp:   time.Now(),
									RetryCount:  0,
									Component:   getComponentForStage(stageID),
									IsRetryable: true,
								}
							}
						}
					}
				}
			}
		}
	}
}

// resultCollectorWorker collecte et traite les résultats
func (esp *EmailSenderPipeline) resultCollectorWorker() {
	defer esp.wg.Done()
	
	for {
		select {
		case <-esp.ctx.Done():
			return
		case task, ok := <-esp.resultCollector:
			if !ok {
				return
			}
			
			// Traiter la tâche complétée
			esp.pipelineMu.Lock()
			esp.stats.TotalEmailsProcessed++
			esp.stats.SuccessfulEmails++
			esp.stats.LastProcessedTimestamp = time.Now()
			esp.pipelineMu.Unlock()
			
			log.Printf("Task %s for contact %s completed successfully", task.ID, task.ContactID)
			
			// Indexer l'email dans RAG
			if err := esp.ragClient.IndexEmail(esp.ctx, task.EmailContent, task.Metadata); err != nil {
				log.Printf("Warning: Failed to index email %s in RAG: %v", task.ID, err)
			}
			
			// Autres actions post-traitement...
		}
	}
}

// errorCollectorWorker collecte et traite les erreurs
func (esp *EmailSenderPipeline) errorCollectorWorker() {
	defer esp.wg.Done()
	
	for {
		select {
		case <-esp.ctx.Done():
			return
		case err, ok := <-esp.errorCollector:
			if !ok {
				return
			}
			
			// Traiter l'erreur
			esp.pipelineMu.Lock()
			esp.stats.FailedEmails++
			esp.stats.ErrorsByType[err.ErrorType]++
			esp.stats.ErrorsByComponent[err.Component]++
			esp.pipelineMu.Unlock()
			
			log.Printf("Error processing task %s at stage %s: %s", err.TaskID, err.StageID, err.Message)
			
			// Gérer les retries si applicable
			if err.IsRetryable && err.RetryCount < esp.config.MaxRetries {
				// La logique de retry est gérée par l'orchestrateur
				// Cette partie collecte juste les statistiques et les logs
				esp.pipelineMu.Lock()
				esp.stats.TotalRetries++
				esp.pipelineMu.Unlock()
				
				log.Printf("Retry %d/%d scheduled for task %s", err.RetryCount+1, esp.config.MaxRetries, err.TaskID)
			}
			
			// Autres actions de gestion d'erreurs...
		}
	}
}

// statsCollectorWorker collecte et sauvegarde périodiquement les statistiques
func (esp *EmailSenderPipeline) statsCollectorWorker() {
	defer esp.wg.Done()
	
	ticker := time.NewTicker(time.Duration(esp.config.StatsIntervalSec) * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-esp.ctx.Done():
			// Sauvegarde finale des statistiques avant de sortir
			esp.saveStats()
			return
		case <-ticker.C:
			esp.saveStats()
		}
	}
}

// saveStats sauvegarde les statistiques actuelles
func (esp *EmailSenderPipeline) saveStats() {
	// Créer le répertoire de sortie si nécessaire
	if err := os.MkdirAll(esp.config.OutputPath, 0755); err != nil {
		log.Printf("Failed to create output directory: %v", err)
		return
	}
	
	// Copier les statistiques pour la sauvegarde
	esp.pipelineMu.RLock()
	statsCopy := *esp.stats
	esp.pipelineMu.RUnlock()
	
	// Ajouter les statistiques du worker pool
	workerPoolStats := esp.workerPool.GetStats()
	
	// Créer un fichier des statistiques
	statsFile := filepath.Join(esp.config.OutputPath, "email_pipeline_stats.json")
	
	// Fusionner les statistiques
	combinedStats := map[string]interface{}{
		"email_pipeline": statsCopy,
		"worker_pool":    workerPoolStats,
		"timestamp":      time.Now(),
	}
	
	// Sérialiser en JSON
	data, err := json.MarshalIndent(combinedStats, "", "  ")
	if err != nil {
		log.Printf("Failed to marshal stats: %v", err)
		return
	}
	
	// Écrire dans un fichier
	if err := os.WriteFile(statsFile, data, 0644); err != nil {
		log.Printf("Failed to write stats to file: %v", err)
		return
	}
}

// Stop arrête le pipeline EMAIL_SENDER
func (esp *EmailSenderPipeline) Stop() {
	log.Printf("Stopping EMAIL_SENDER_1 Pipeline...")
	
	// Annuler le contexte pour arrêter tous les workers
	esp.cancel()
	
	// Arrêter l'orchestrateur
	esp.orchestrator.Stop()
	
	// Arrêter le worker pool
	esp.workerPool.Stop()
	
	// Attendre que tous les workers se terminent
	esp.wg.Wait()
	
	// Fermer les canaux
	close(esp.resultCollector)
	close(esp.errorCollector)
	close(esp.batchQueue)
	
	// Sauvegarde finale des statistiques
	esp.saveStats()
	
	log.Printf("EMAIL_SENDER_1 Pipeline stopped")
}

// getComponentForStage détermine le composant principal pour une étape donnée
func getComponentForStage(stageID string) string {
	switch stageID {
	case "prepare", "update_notion":
		return "Notion"
	case "rag_context":
		return "RAG"
	case "n8n_trigger":
		return "N8N"
	case "send_email":
		return "Gmail"
	default:
		return "Pipeline"
	}
}

// Implémentations simulées des clients pour l'exemple

type mockNotionClient struct {
	apiKey string
}

func (c *mockNotionClient) GetContact(ctx context.Context, contactID string) (map[string]interface{}, error) {
	return map[string]interface{}{
		"email":    fmt.Sprintf("%s@example.com", contactID),
		"name":     fmt.Sprintf("Contact %s", contactID),
		"company":  "Example Corp",
		"position": "Developer",
	}, nil
}

func (c *mockNotionClient) UpdateContactStatus(ctx context.Context, contactID string, status string) error {
	return nil
}

func (c *mockNotionClient) LogEmailSent(ctx context.Context, contactID string, emailContent string, metadata map[string]interface{}) error {
	return nil
}

type mockGmailClient struct {
	credentialsPath string
}

func (c *mockGmailClient) SendEmail(ctx context.Context, to string, subject string, content string, metadata map[string]interface{}) (string, error) {
	return fmt.Sprintf("email_%s_%d", to, time.Now().Unix()), nil
}

func (c *mockGmailClient) TrackEmail(ctx context.Context, emailID string) (map[string]interface{}, error) {
	return map[string]interface{}{
		"opened":    true,
		"clicked":   false,
		"replied":   false,
		"timestamp": time.Now(),
	}, nil
}

type mockRAGClient struct {
	endpoint string
}

func (c *mockRAGClient) GetEmailContext(ctx context.Context, contactID string, emailType string) (interface{}, error) {
	return map[string]interface{}{
		"relevance_score": 0.92,
		"similar_contacts": []string{"contact1", "contact2"},
		"suggested_topics": []string{"Topic A", "Topic B"},
	}, nil
}

func (c *mockRAGClient) IndexEmail(ctx context.Context, emailContent string, metadata map[string]interface{}) error {
	return nil
}

type mockN8NClient struct {
	webhookURL string
}

func (c *mockN8NClient) TriggerWorkflow(ctx context.Context, workflowID string, data map[string]interface{}) error {
	return nil
}

func (c *mockN8NClient) GetWorkflowStatus(ctx context.Context, executionID string) (string, error) {
	return "completed", nil
}
