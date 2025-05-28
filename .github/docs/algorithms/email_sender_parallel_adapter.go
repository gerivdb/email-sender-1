// File: .github/docs/algorithms/email_sender_parallel_adapter.go
// EMAIL_SENDER_1 Parallel Adapter
// Module d'adaptation du système de parallélisme au sein de l'orchestrateur principal

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"
	
	"d/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/.github/docs/algorithms/parallel"
)

// ParallelAlgorithm implémente l'interface Algorithm pour l'intégration du système parallélisé
type ParallelAlgorithm struct {
	connector *parallel.ParallelOrchestrationConnector
	manager   *parallel.AdaptiveParallelismManager
}

// NewParallelAlgorithm crée une nouvelle instance de l'algorithme parallèle
func NewParallelAlgorithm() *ParallelAlgorithm {
	return &ParallelAlgorithm{}
}

// ID retourne l'identifiant de l'algorithme
func (pa *ParallelAlgorithm) ID() string {
	return "parallel_pipeline_orchestrator"
}

// Name retourne le nom de l'algorithme
func (pa *ParallelAlgorithm) Name() string {
	return "Pipeline Orchestrator Parallèle"
}

// Validate valide la configuration de l'algorithme
func (pa *ParallelAlgorithm) Validate(config AlgorithmConfig) error {
	// Vérifier les paramètres requis
	requiredParams := []string{
		"notion_api_key", 
		"gmail_credentials_path", 
		"n8n_webhook_url", 
		"rag_endpoint",
	}
	
	for _, param := range requiredParams {
		if _, exists := config.Parameters[param]; !exists || config.Parameters[param] == "" {
			return fmt.Errorf("le paramètre %s est requis", param)
		}
	}
	
	return nil
}

// Execute exécute l'algorithme parallèle
func (pa *ParallelAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	startTime := time.Now()
	
	// Charger et valider la configuration
	parallelConfig, err := pa.loadParallelConfig(config)
	if err != nil {
		return nil, fmt.Errorf("erreur de configuration: %w", err)
	}
	
	// Créer le connecteur d'orchestration parallèle
	connector := parallel.NewParallelOrchestrationConnector(parallelConfig)
	pa.connector = connector
	
	// Créer et configurer le gestionnaire de parallélisme adaptatif
	adaptiveConfig := parallel.DefaultAdaptiveParallelismConfig()
	adaptiveConfig.InitialWorkers = parallelConfig.MaxWorkers
	adaptiveConfig.MaxWorkers = parallelConfig.MaxWorkers * 2
	adaptiveConfig.Mode = parallel.ParallelismMode(config.Parameters["parallelism_mode"])
	if adaptiveConfig.Mode == "" {
		adaptiveConfig.Mode = parallel.Balanced
	}
	
	manager := parallel.NewAdaptiveParallelismManager(adaptiveConfig)
	pa.manager = manager
	manager.Start()
	
	defer func() {
		// Arrêter proprement les composants
		manager.Stop()
		connector.Stop()
	}()
	
	// Charger les données d'emails à traiter
	emailBatches, err := pa.loadEmailBatches(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("erreur lors du chargement des emails: %w", err)
	}
	
	// Répartir les lots d'emails sur plusieurs pipelines
	pipelineCount := min(len(emailBatches), parallelConfig.MaxConcurrentPipelines)
	if pipelineCount == 0 {
		pipelineCount = 1
	}
	
	log.Printf("Démarrage de %d pipelines parallèles pour traiter %d lots d'emails",
		pipelineCount, len(emailBatches))
	
	// Répartir les lots entre les pipelines
	batchesPerPipeline := make(map[string][]parallel.EmailBatch)
	for i, batch := range emailBatches {
		pipelineID := fmt.Sprintf("pipeline_%d", i % pipelineCount)
		batchesPerPipeline[pipelineID] = append(batchesPerPipeline[pipelineID], batch)
	}
	
	// Démarrer les pipelines
	for pipelineID, batches := range batchesPerPipeline {
		if len(batches) == 0 {
			continue
		}
		
		log.Printf("Démarrage du pipeline %s avec %d lots", pipelineID, len(batches))
		if err := connector.StartPipelineWithBatches(pipelineID, batches); err != nil {
			log.Printf("Erreur lors du démarrage du pipeline %s: %v", pipelineID, err)
		}
	}
	
	// Attendre la fin de tous les pipelines
	connector.Wait()
	
	// Récupérer les statistiques globales
	stats := connector.GetGlobalStats()
	
	// Générer les résultats
	result := map[string]interface{}{
		"total_emails_processed": stats.TotalEmailsProcessed,
		"successful_emails":      stats.SuccessfulEmails,
		"failed_emails":          stats.FailedEmails,
		"total_batches":          stats.TotalBatchesProcessed,
		"average_processing_time": stats.AverageProcessingTime.String(),
		"errors_by_type":         stats.ErrorsByType,
		"errors_by_component":    stats.ErrorsByComponent,
		"total_retries":          stats.TotalRetries,
		"pipeline_stats":         stats.PipelineStats,
		"execution_time":         time.Since(startTime).String(),
		"parallelism_mode":       string(adaptiveConfig.Mode),
		"worker_count":           parallelConfig.MaxWorkers,
	}
	
	// Sauvegarder les résultats
	resultPath := filepath.Join(config.OutputPath, "parallel_execution_result.json")
	if err := pa.saveResults(resultPath, result); err != nil {
		log.Printf("Erreur lors de la sauvegarde des résultats: %v", err)
	}
	
	return result, nil
}

// loadParallelConfig charge la configuration du système parallélisé
func (pa *ParallelAlgorithm) loadParallelConfig(config AlgorithmConfig) (parallel.ParallelOrchestrationConfig, error) {
	parallelConfig := parallel.DefaultParallelOrchestrationConfig()
	
	// Appliquer les paramètres de configuration
	if workers, ok := config.Parameters["max_workers"]; ok {
		var maxWorkers int
		if _, err := fmt.Sscanf(workers, "%d", &maxWorkers); err == nil && maxWorkers > 0 {
			parallelConfig.MaxWorkers = maxWorkers
		}
	}
	
	if concurrentPipelines, ok := config.Parameters["max_concurrent_pipelines"]; ok {
		var maxConcurrentPipelines int
		if _, err := fmt.Sscanf(concurrentPipelines, "%d", &maxConcurrentPipelines); err == nil && maxConcurrentPipelines > 0 {
			parallelConfig.MaxConcurrentPipelines = maxConcurrentPipelines
		}
	}
	
	if queueSize, ok := config.Parameters["max_queue_size"]; ok {
		var maxQueueSize int
		if _, err := fmt.Sscanf(queueSize, "%d", &maxQueueSize); err == nil && maxQueueSize > 0 {
			parallelConfig.MaxQueueSize = maxQueueSize
		}
	}
	
	if batchSize, ok := config.Parameters["batch_size"]; ok {
		var bSize int
		if _, err := fmt.Sscanf(batchSize, "%d", &bSize); err == nil && bSize > 0 {
			parallelConfig.BatchSize = bSize
		}
	}
	
	if retryLimit, ok := config.Parameters["retry_limit"]; ok {
		var rLimit int
		if _, err := fmt.Sscanf(retryLimit, "%d", &rLimit); err == nil {
			parallelConfig.RetryLimit = rLimit
		}
	}
	
	if retryDelay, ok := config.Parameters["retry_delay_ms"]; ok {
		var rDelay int
		if _, err := fmt.Sscanf(retryDelay, "%d", &rDelay); err == nil && rDelay > 0 {
			parallelConfig.RetryDelayMs = rDelay
		}
	}
	
	if logLevel, ok := config.Parameters["log_level"]; ok && logLevel != "" {
		parallelConfig.LogLevel = logLevel
	}
	
	if recoveryStrategy, ok := config.Parameters["recovery_strategy"]; ok && recoveryStrategy != "" {
		parallelConfig.RecoveryStrategy = recoveryStrategy
	}
	
	// Copier les paramètres d'API requis
	parallelConfig.NotionAPIKey = config.Parameters["notion_api_key"]
	parallelConfig.GmailCredentialsPath = config.Parameters["gmail_credentials_path"]
	parallelConfig.N8NWebhookURL = config.Parameters["n8n_webhook_url"]
	parallelConfig.RAGEndpoint = config.Parameters["rag_endpoint"]
	
	// Configurer le chemin de sortie
	parallelConfig.OutputPath = config.OutputPath
	
	return parallelConfig, nil
}

// loadEmailBatches charge les lots d'emails à traiter
func (pa *ParallelAlgorithm) loadEmailBatches(ctx context.Context, config AlgorithmConfig) ([]parallel.EmailBatch, error) {
	var batches []parallel.EmailBatch
	
	// Déterminer la source des données
	dataSource := "default"
	if source, ok := config.Parameters["data_source"]; ok && source != "" {
		dataSource = source
	}
	
	switch dataSource {
	case "file":
		// Charger les données depuis un fichier
		dataFile := config.Parameters["data_file"]
		if dataFile == "" {
			return nil, fmt.Errorf("paramètre data_file requis pour la source file")
		}
		
		// Si le chemin est relatif, le résoudre par rapport au chemin de sortie
		if !filepath.IsAbs(dataFile) {
			dataFile = filepath.Join(filepath.Dir(config.OutputPath), dataFile)
		}
		
		// Lire le fichier
		data, err := os.ReadFile(dataFile)
		if err != nil {
			return nil, fmt.Errorf("erreur lors de la lecture du fichier de données: %w", err)
		}
		
		// Désérialiser les données
		if err := json.Unmarshal(data, &batches); err != nil {
			return nil, fmt.Errorf("erreur lors de la désérialisation des données: %w", err)
		}
		
	case "mock":
		// Générer des données de test
		batchCount := 5
		if batchCountParam, ok := config.Parameters["batch_count"]; ok {
			if _, err := fmt.Sscanf(batchCountParam, "%d", &batchCount); err != nil {
				batchCount = 5
			}
		}
		
		emailsPerBatch := 10
		if emailsParam, ok := config.Parameters["emails_per_batch"]; ok {
			if _, err := fmt.Sscanf(emailsParam, "%d", &emailsPerBatch); err != nil {
				emailsPerBatch = 10
			}
		}
		
		batches = pa.generateMockBatches(batchCount, emailsPerBatch)
		
	default:
		// Par défaut, générer un petit jeu de données de test
		batches = pa.generateMockBatches(2, 5)
	}
	
	log.Printf("Chargement terminé: %d lots d'emails avec un total de %d emails",
		len(batches), pa.countTotalEmails(batches))
	
	return batches, nil
}

// generateMockBatches génère des lots d'emails de test
func (pa *ParallelAlgorithm) generateMockBatches(batchCount, emailsPerBatch int) []parallel.EmailBatch {
	batches := make([]parallel.EmailBatch, 0, batchCount)
	
	emailTypes := []string{"prospection", "suivi", "réponse", "newsletter"}
	
	for i := 0; i < batchCount; i++ {
		batch := parallel.EmailBatch{
			BatchID:     fmt.Sprintf("batch_%d", i),
			EmailTasks:  make([]parallel.EmailTask, 0, emailsPerBatch),
			BatchSize:   emailsPerBatch,
			Priority:    3,
			CreatedAt:   time.Now(),
			Status:      "pending",
		}
		
		for j := 0; j < emailsPerBatch; j++ {
			task := parallel.EmailTask{
				ID:                fmt.Sprintf("email_%d_%d", i, j),
				ContactID:         fmt.Sprintf("contact_%d", j),
				EmailType:         emailTypes[j%len(emailTypes)],
				Priority:          3,
				Status:            "pending",
				CreatedAt:         time.Now(),
				Metadata:          make(map[string]interface{}),
				ContactMetadata:   make(map[string]interface{}),
				EmailContent:      fmt.Sprintf("Contenu de l'email %d pour le contact %d", i, j),
				NotionDatabaseID:  "12345abcdef",
			}
			
			// Ajouter des métadonnées de test
			task.Metadata["campaign"] = fmt.Sprintf("campaign_%d", i)
			task.ContactMetadata["name"] = fmt.Sprintf("Contact %d", j)
			task.ContactMetadata["company"] = fmt.Sprintf("Company %d", j)
			
			batch.EmailTasks = append(batch.EmailTasks, task)
		}
		
		batches = append(batches, batch)
	}
	
	return batches
}

// countTotalEmails compte le nombre total d'emails dans tous les lots
func (pa *ParallelAlgorithm) countTotalEmails(batches []parallel.EmailBatch) int {
	total := 0
	for _, batch := range batches {
		total += len(batch.EmailTasks)
	}
	return total
}

// saveResults sauvegarde les résultats dans un fichier
func (pa *ParallelAlgorithm) saveResults(filePath string, results map[string]interface{}) error {
	// Créer le répertoire parent si nécessaire
	if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
		return err
	}
	
	// Sérialiser les résultats en JSON
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return err
	}
	
	// Écrire dans le fichier
	return os.WriteFile(filePath, data, 0644)
}

// min retourne la plus petite de deux valeurs
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
