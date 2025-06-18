package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// EmbeddingMigrator gère la migration des embeddings vers de nouveaux modèles
type EmbeddingMigrator struct {
	oldModel     string
	newModel     string
	batchSize    int
	parallel     int
	dryRun       bool
	qdrantClient QdrantClient
	metrics      *MigrationMetrics
}

// MigrationMetrics contient les métriques de migration
type MigrationMetrics struct {
	documentsProcessed prometheus.Counter
	migrationDuration  prometheus.Histogram
	errorCount         prometheus.Counter
	batchSize          prometheus.Gauge
}

// QdrantClient interface pour le client Qdrant
type QdrantClient interface {
	GetCollection(ctx context.Context, name string) (*Collection, error)
	GetPoints(ctx context.Context, collection string, limit int, offset int) ([]Point, error)
	UpsertPoints(ctx context.Context, collection string, points []Point) error
	CreateCollection(ctx context.Context, name string, config CollectionConfig) error
}

// Collection représente une collection Qdrant
type Collection struct {
	Name   string           `json:"name"`
	Config CollectionConfig `json:"config"`
}

// CollectionConfig contient la configuration d'une collection
type CollectionConfig struct {
	VectorSize int    `json:"vector_size"`
	Distance   string `json:"distance"`
}

// Point représente un point dans Qdrant
type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// EmbeddingModel interface pour les modèles d'embedding
type EmbeddingModel interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	GetDimensions() int
	GetModelName() string
}

// MigrationResult contient les résultats de migration
type MigrationResult struct {
	ProcessedDocuments   int           `json:"processed_documents"`
	SuccessfulMigrations int           `json:"successful_migrations"`
	FailedMigrations     int           `json:"failed_migrations"`
	Duration             time.Duration `json:"duration"`
	Errors               []string      `json:"errors"`
}

func main() {
	var (
		oldModel   = flag.String("old-model", "text-embedding-ada-002", "Ancien modèle d'embedding")
		newModel   = flag.String("new-model", "text-embedding-3-large", "Nouveau modèle d'embedding")
		collection = flag.String("collection", "roadmap_tasks", "Collection à migrer")
		batchSize  = flag.Int("batch-size", 100, "Taille des batches")
		parallel   = flag.Int("parallel", 4, "Nombre de workers parallèles")
		dryRun     = flag.Bool("dry-run", false, "Mode simulation sans modifications")
		qdrantURL  = flag.String("qdrant-url", "http://localhost:6333", "URL du serveur Qdrant")
	)
	flag.Parse()

	fmt.Printf("Migration d'embeddings: %s -> %s\n", *oldModel, *newModel)
	fmt.Printf("Collection: %s\n", *collection)
	fmt.Printf("Batch size: %d, Parallel: %d, Dry run: %t\n", *batchSize, *parallel, *dryRun)

	// Initialiser les métriques
	metrics := &MigrationMetrics{
		documentsProcessed: promauto.NewCounter(prometheus.CounterOpts{
			Name: "embedding_migration_documents_processed_total",
			Help: "Nombre de documents traités durant la migration",
		}),
		migrationDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "embedding_migration_duration_seconds",
			Help:    "Durée de la migration des embeddings",
			Buckets: []float64{1, 5, 10, 30, 60, 300, 600, 1800, 3600},
		}),
		errorCount: promauto.NewCounter(prometheus.CounterOpts{
			Name: "embedding_migration_errors_total",
			Help: "Nombre d'erreurs durant la migration",
		}),
		batchSize: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "embedding_migration_batch_size",
			Help: "Taille des batches de migration",
		}),
	}

	// Créer le client Qdrant (implémentation simplifiée)
	qdrantClient := NewQdrantClient(*qdrantURL)

	// Créer le migrateur
	migrator := &EmbeddingMigrator{
		oldModel:     *oldModel,
		newModel:     *newModel,
		batchSize:    *batchSize,
		parallel:     *parallel,
		dryRun:       *dryRun,
		qdrantClient: qdrantClient,
		metrics:      metrics,
	}

	// Exécuter la migration
	ctx := context.Background()
	result, err := migrator.MigrateCollection(ctx, *collection)
	if err != nil {
		log.Fatalf("Erreur lors de la migration: %v", err)
	}

	// Afficher les résultats
	fmt.Printf("\n=== Résultats de la Migration ===\n")
	fmt.Printf("Documents traités: %d\n", result.ProcessedDocuments)
	fmt.Printf("Migrations réussies: %d\n", result.SuccessfulMigrations)
	fmt.Printf("Migrations échouées: %d\n", result.FailedMigrations)
	fmt.Printf("Durée totale: %v\n", result.Duration)

	if len(result.Errors) > 0 {
		fmt.Printf("\nErreurs rencontrées:\n")
		for _, err := range result.Errors {
			fmt.Printf("- %s\n", err)
		}
	}
}

// MigrateCollection migre une collection vers le nouveau modèle
func (em *EmbeddingMigrator) MigrateCollection(ctx context.Context, collectionName string) (*MigrationResult, error) {
	start := time.Now()

	result := &MigrationResult{
		Errors: []string{},
	}

	// Vérifier que la collection existe
	collection, err := em.qdrantClient.GetCollection(ctx, collectionName)
	if err != nil {
		return nil, fmt.Errorf("impossible de récupérer la collection %s: %w", collectionName, err)
	}

	fmt.Printf("Collection trouvée: %s (dimensions: %d)\n", collection.Name, collection.Config.VectorSize)

	// Créer la nouvelle collection avec les dimensions du nouveau modèle
	newCollectionName := fmt.Sprintf("%s_%s", collectionName, em.newModel)
	if !em.dryRun {
		newModel := em.getEmbeddingModel(em.newModel)
		newConfig := CollectionConfig{
			VectorSize: newModel.GetDimensions(),
			Distance:   collection.Config.Distance,
		}

		err = em.qdrantClient.CreateCollection(ctx, newCollectionName, newConfig)
		if err != nil {
			return nil, fmt.Errorf("impossible de créer la nouvelle collection: %w", err)
		}
		fmt.Printf("Nouvelle collection créée: %s (dimensions: %d)\n", newCollectionName, newConfig.VectorSize)
	}

	// Récupérer tous les points de la collection
	allPoints, err := em.getAllPoints(ctx, collectionName)
	if err != nil {
		return nil, fmt.Errorf("impossible de récupérer les points: %w", err)
	}

	fmt.Printf("Points à migrer: %d\n", len(allPoints))
	result.ProcessedDocuments = len(allPoints)

	// Migrer par batches en parallèle
	err = em.migrateBatches(ctx, allPoints, newCollectionName, result)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la migration par batches: %w", err)
	}

	result.Duration = time.Since(start)
	em.metrics.migrationDuration.Observe(result.Duration.Seconds())

	return result, nil
}

// getAllPoints récupère tous les points d'une collection
func (em *EmbeddingMigrator) getAllPoints(ctx context.Context, collectionName string) ([]Point, error) {
	var allPoints []Point
	offset := 0
	limit := 1000

	for {
		points, err := em.qdrantClient.GetPoints(ctx, collectionName, limit, offset)
		if err != nil {
			return nil, err
		}

		if len(points) == 0 {
			break
		}

		allPoints = append(allPoints, points...)
		offset += len(points)

		fmt.Printf("Récupéré %d points (total: %d)\n", len(points), len(allPoints))
	}

	return allPoints, nil
}

// migrateBatches migre les points par batches en parallèle
func (em *EmbeddingMigrator) migrateBatches(ctx context.Context, points []Point, newCollectionName string, result *MigrationResult) error {
	batches := em.createBatches(points)

	// Canal pour les batches à traiter
	batchChan := make(chan []Point, len(batches))

	// Canal pour les résultats
	resultChan := make(chan BatchResult, len(batches))

	// Démarrer les workers
	var wg sync.WaitGroup
	for i := 0; i < em.parallel; i++ {
		wg.Add(1)
		go em.worker(ctx, batchChan, resultChan, newCollectionName, &wg)
	}

	// Envoyer les batches
	for _, batch := range batches {
		batchChan <- batch
	}
	close(batchChan)

	// Attendre que tous les workers terminent
	wg.Wait()
	close(resultChan)

	// Collecter les résultats
	for batchResult := range resultChan {
		result.SuccessfulMigrations += batchResult.SuccessCount
		result.FailedMigrations += batchResult.ErrorCount
		result.Errors = append(result.Errors, batchResult.Errors...)
	}

	return nil
}

// BatchResult contient les résultats d'un batch
type BatchResult struct {
	SuccessCount int
	ErrorCount   int
	Errors       []string
}

// worker traite les batches de points
func (em *EmbeddingMigrator) worker(ctx context.Context, batchChan <-chan []Point, resultChan chan<- BatchResult, newCollectionName string, wg *sync.WaitGroup) {
	defer wg.Done()

	newModel := em.getEmbeddingModel(em.newModel)

	for batch := range batchChan {
		result := em.processBatch(ctx, batch, newModel, newCollectionName)
		resultChan <- result
	}
}

// processBatch traite un batch de points
func (em *EmbeddingMigrator) processBatch(ctx context.Context, batch []Point, newModel EmbeddingModel, newCollectionName string) BatchResult {
	result := BatchResult{
		Errors: []string{},
	}

	newPoints := make([]Point, 0, len(batch))

	for _, point := range batch {
		// Extraire le texte du payload
		text, ok := point.Payload["text"].(string)
		if !ok {
			result.ErrorCount++
			result.Errors = append(result.Errors, fmt.Sprintf("Point %v: pas de texte dans le payload", point.ID))
			continue
		}

		// Générer le nouveau embedding
		newVector, err := newModel.GenerateEmbedding(ctx, text)
		if err != nil {
			result.ErrorCount++
			result.Errors = append(result.Errors, fmt.Sprintf("Point %v: erreur embedding: %v", point.ID, err))
			em.metrics.errorCount.Inc()
			continue
		}

		// Créer le nouveau point
		newPoint := Point{
			ID:      point.ID,
			Vector:  newVector,
			Payload: point.Payload,
		}

		// Ajouter les métadonnées de migration
		newPoint.Payload["migration_timestamp"] = time.Now().Unix()
		newPoint.Payload["original_model"] = em.oldModel
		newPoint.Payload["new_model"] = em.newModel

		newPoints = append(newPoints, newPoint)
		result.SuccessCount++
		em.metrics.documentsProcessed.Inc()
	}

	// Insérer les nouveaux points si pas en mode dry-run
	if !em.dryRun && len(newPoints) > 0 {
		err := em.qdrantClient.UpsertPoints(ctx, newCollectionName, newPoints)
		if err != nil {
			result.ErrorCount += len(newPoints)
			result.SuccessCount -= len(newPoints)
			result.Errors = append(result.Errors, fmt.Sprintf("Erreur insertion batch: %v", err))
		}
	}

	fmt.Printf("Batch traité: %d succès, %d erreurs\n", result.SuccessCount, result.ErrorCount)

	return result
}

// createBatches divise les points en batches
func (em *EmbeddingMigrator) createBatches(points []Point) [][]Point {
	var batches [][]Point

	for i := 0; i < len(points); i += em.batchSize {
		end := i + em.batchSize
		if end > len(points) {
			end = len(points)
		}
		batches = append(batches, points[i:end])
	}

	em.metrics.batchSize.Set(float64(em.batchSize))

	return batches
}

// getEmbeddingModel retourne le modèle d'embedding approprié
func (em *EmbeddingMigrator) getEmbeddingModel(modelName string) EmbeddingModel {
	// Implémentation simplifiée - à remplacer par la vraie implémentation
	return &MockEmbeddingModel{name: modelName}
}

// Implémentations simplifiées pour l'exemple

type MockQdrantClient struct {
	url string
}

func NewQdrantClient(url string) QdrantClient {
	return &MockQdrantClient{url: url}
}

func (c *MockQdrantClient) GetCollection(ctx context.Context, name string) (*Collection, error) {
	return &Collection{
		Name: name,
		Config: CollectionConfig{
			VectorSize: 1536,
			Distance:   "cosine",
		},
	}, nil
}

func (c *MockQdrantClient) GetPoints(ctx context.Context, collection string, limit int, offset int) ([]Point, error) {
	// Implémentation simplifiée
	return []Point{}, nil
}

func (c *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	// Implémentation simplifiée
	return nil
}

func (c *MockQdrantClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error {
	// Implémentation simplifiée
	return nil
}

type MockEmbeddingModel struct {
	name string
}

func (m *MockEmbeddingModel) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	// Implémentation simplifiée - retourne un vecteur factice
	dimensions := m.GetDimensions()
	vector := make([]float32, dimensions)
	for i := range vector {
		vector[i] = 0.1 // Valeur factice
	}
	return vector, nil
}

func (m *MockEmbeddingModel) GetDimensions() int {
	switch m.name {
	case "text-embedding-3-large":
		return 3072
	case "text-embedding-ada-002":
		return 1536
	default:
		return 1536
	}
}

func (m *MockEmbeddingModel) GetModelName() string {
	return m.name
}
